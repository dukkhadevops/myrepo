param(
    [Parameter(Mandatory=$True)][string]$environment,
    [Parameter(Mandatory=$True)][string]$prefix,
    [Parameter(Mandatory=$True)][string]$resourceGroupName
)

Write-Host "Environment: $environment"
Write-Host "Prefix: $prefix"
Write-Host "Resource Group: $resourceGroupName"
$environment = $environment.ToLower()
$prefix = $prefix.ToLower()
$resourceGroupName = $resourceGroupName.ToLower()

#for each az resource we find with type Microsoft.Web/sites, inspect it to see if its connected to a vnet
##for each resource, if it is not connected to a vnet, add it to a list of webapps that need connected
###we may end up needing to return the farm the resource belongs to as well - in order to account for RG's that have multiple resources & farms within
Function Get-WebAppsForResourceGroup {
    param(
        [Parameter(Mandatory=$True)][string]$resourceGroupName
    )
    $services = az resource list --resource-group $resourceGroupName | ConvertFrom-Json | Where-Object { $_.type -eq 'Microsoft.Web/sites' }

    $vnetList = [System.Collections.ArrayList]::new()
    #for each webapp we found in the resource group - is it already connected to a vnet?
    foreach( $s in $services ) {
        #for $s.name, return the vnet object
        $item = az webapp vnet-integration list --resource-group $resourceGroupName --name $s.name | ConvertFrom-Json
        #if there isn't a vnet object we need to add it obviously so add it to vnet list. if that vnet command returns something it must not need added so don't add it to the vnet list
        if($item.count -eq 0) {
            $null = $vnetList.Add($s.name)
        }
    }
    return $vnetList
}

Function Get-VnetsForEnvironment {
    param(
        [Parameter(Mandatory=$True)][string]$environment
    )
    if($environment -eq "dev") {
        $vnet = az network vnet show --name $environment-enterprise-vnet --resource-group $environment-enterprise-netlb | ConvertFrom-Json
        $prVnet = $vnet.subnets | Where-Object { $_.name -match '^pr[\d]{3}(.)*farm$' }
        $prlinkedObject = $prVnet | Where-Object { $_.serviceAssociationLinks.count -eq 0 }
        return $prLinkedObject[0]
    } else {
        $vnet = az network vnet show --name $environment-enterprise-vnet --resource-group $environment-enterprise-netlb | ConvertFrom-Json
        $subVnet = $vnet.subnets | Where-Object { $_.name -match '^core-mdis[\d]{3}' }
        $sublinkedObject = $subVnet | Where-Object { $_.serviceAssociationLinks.count -eq 0 }
        return $subLinkedObject[0]

    }
}

Function Main {
    $services = Get-WebAppsForResourceGroup $resourceGroupName
    $count = $services.Count
    $planlist = az appservice plan list --resource-group "$resourceGroupName" | ConvertFrom-Json

    # count is first to short circuit empty string
    if($count -gt 0 -and $services.GetType() -eq [string]) {
        if($environment -ne $resourceGroupName) {
            $linkedServices = Get-VnetsForEnvironment $environment
        }
        write-host "az webapp vnet-integration add --name '$services' --resource-group '$resourceGroupName' --vnet '$environment-enterprise-vnet' --subnet '$($linkedServices.name)'"
        az webapp vnet-integration add --name "$services" -g $resourceGroupName --vnet "$environment-enterprise-vnet" --subnet $linkedServices.name
    } else {
        for($i = 0; $i -lt $count; $i++)
        {
            # check to see if we can attach to another vnet already in this region ( since we cannot tell what belongs to what. )
            $attached = $false
            foreach($plan in $planlist) {
                try {
                    $net = az appservice vnet-integration list --resource-group "$resourceGroupName" --plan "$($plan.name)" | ConvertFrom-Json
                    if($net -and $net.count -gt 0) {
                        for($n = 0; $n -lt $net.count; $n++) {
                            $idlist = $net.vnetResourceId.split('/')
                            write-host "az webapp vnet-integration add --name '$($services[$i])' -g $resourceGroupName --vnet '$($idlist[8])' --subnet '$($idlist[10])'"
                            az webapp vnet-integration add --name "$($services[$i])" -g $resourceGroupName --vnet "$($idlist[8])" --subnet "$($idlist[10])"
                            $attached = $true
                            write-host "Successed in connecting $($services[$i]) to $($idlist[10])"
                            break
                        }
                    }
                } catch {}
            } 
            if(-not $attached) {
                if($environment -ne $resourceGroupName) {
                    $linkedServices = Get-VnetsForEnvironment $environment
                }
                try {
                    write-host "az webapp vnet-integration add --name '$($services[$i])' --resource-group '$resourceGroupName' --vnet '$environment-enterprise-vnet' --subnet '$($linkedServices.name)'"
                    az webapp vnet-integration add --name "$($services[$i])" -g $resourceGroupName --vnet "$environment-enterprise-vnet" --subnet $linkedServices.name
                    write-host "Successful when connecting $($services[$i]) to $($linkedServices.name)"
                } catch {
                    write-host "Could not locate a subnet to connect $($services[$i])."
                }
            }
        }
    }
}

Main