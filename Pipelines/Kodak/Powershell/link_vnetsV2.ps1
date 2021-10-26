####################################################################################################################################
#This script was updated/written explicitly for the traject application to handle the following scenario
#
##ONE WebAppFarm hosting TWO WebApps on the same farm which need to be on the same VNET
#
#You can probably reuse some of the functions used to do the heavy lifting you need in Azure (DetermineVNET, FindOpenSubnet, AddVnetIntegration)
#
#OVERVIEW
##Install Modules needed by the functions we use later to interact with Azure
##Based on the EnvPrefix & ResourceId - create an app service plan name & grab the obj from azure
##Using that app service plan find the vnet it should use & find an open subnet on that vnet based on if its a PR or QA/DEMO/PROD
##For each resource on that app service plan create a vnet resource obj and run the command to add it using the subnet info we grabbed
####################################################################################################################################
param(
    [Parameter(Mandatory=$True)][string]$envPrefix,
    [Parameter(Mandatory=$True)][string]$envResourceId
)
#this is required for get-azappserviceplan for example
Try{
    Write-Host "trying install of az.websites module"
    Install-Module Az.Websites -AllowClobber -Force
    Write-Host "trying install of az.network module"
    Install-Module Az.Network -AllowClobber -Force
    Write-Host "trying install of az.resources module"
    Install-Module Az.Resources -AllowClobber -Force
}
Catch{
    Write-Host "not able to install the modules for some reason"
}
#try running a list to show what modules are installed now
#Get-Module -ListAvailable -All
#$moduleCheck = Get-Module
Write-Host "-----------------------------------------------------"
Write-Host "Done installing the modules needed"

Write-Host "EnvPrefix: $envPrefix"
Write-Host "EnvResourceId: $envResourceId"
$envPrefix = $envPrefix.ToLower()
$envResourceId = $envResourceId.ToLower()
$appServicePlanRG = $envResourceId + "-traject-webap"

#params we need for new functions
$appServicePlanName = "$envResourceId" + "-traject-farm"
Write-Host "App Service Plan name we are working on & RG: $appServicePlanName | $appServicePlanRG"

#since we know there will only be 1 app service plan just look for one with the name we know its going to be
Write-Host "Getting the App Service Plan object for that name: $appServicePlanName"
$appServicePlanObj = Get-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $appServicePlanRG
Write-Host "done getting the App Service Plan object. Run a test to make sure its not empty"
$tempName1 = $appServicePlanObj.Name
Write-Host "here is the name that came back at least: $tempName1"

#now feed that app service plan object to get-azwebapp to get all the apps it has
Write-Host "Getting the WebApps for that specific App Service Plan obj...."
$resources = Get-AzWebApp -AppServicePlan $appServicePlanObj
$tempWebAppName = $resources[0].Name
Write-Host "done getting the WebApps for that App Service Plan object. Here is the one in position 0: $tempWebAppName"

####################################################################################################################################
#region all supporting functions

####################################################################################################################################
#determine what virtual network to work on based on the app service plan name (qa-mdisapp-funcFarm should use the qa-enterprise-vnet for example)
#returns a small array [0]=name [1]=resourceGroup [2]=location for the app service plan name you feed it
Function DetermineVNET{
    param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $appServicePlanName
    )
    $firstElement = $appServicePlanName.Split('-')[0]
    $firstElement = $firstElement.ToString()

    #check the first element. if it matches qa use the qa-vnet & so on
    if ($firstElement -eq 'qa'){
        $vnetName = 'qa-enterprise-vnet'
        $vnetRG = 'qa-enterprise-netlb'
        $vnetLocation = 'eastus'
    }
    elseif ($firstElement -eq 'demo'){
        $vnetName = 'demo-enterprise-vnet'
        $vnetRG = 'demo-enterprise-netlb'
        $vnetLocation = 'centralus'
    }
    elseif ($firstElement -eq 'prod'){
        $vnetName = 'prod-enterprise-vnet'
        $vnetRG = 'prod-enterprise-netlb'
        $vnetLocation = 'northcentralus'
    }
    #everything else should be on the enterprise vnet
    else{
        $vnetName = 'dev-enterprise-vnet'
        $vnetRG = 'dev-enterprise-netlb'
        $vnetLocation = 'eastus2'
    }
    Return $vnetName, $vnetRG, $vnetLocation
}
####################################################################################################################################

####################################################################################################################################
#depends on getting the DetermineVNET function
#gets the subnets off of the VNET coming from the above - finds and open vnet and returns the name
Function FindOpenSubnet{
    param
    (
         [Parameter(Mandatory=$true, Position=0)][string] $appServicePlanName,
         [Parameter(Mandatory=$True, Position=1)][string] $envPrefix
    )
    #set debug preference to continue that way we can use write-debug from within the function and still output all that good debug info to log/screen
    #if we dont do this, when you use return it will return all the write out crap from above the return
    #$DebugPreference = "Continue"

    #Use function to get the VNET & associated subnets we will be working on
    $getVNet = DetermineVNET $appServicePlanName
    $vnetName = $getVNet[0]
    $vnetRG = $getVNet[1]
    Write-Host "try getting virtual network"
    $virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $vnetRG -Name $vnetName
    $temp2 = $virtualNetwork[0]

    Write-Host "show a value now that we just got back from get-azvirtualnetwork command: $temp2"
    ##################################################################################
    #need an array of viable subnet names (excludes things like 'GatewaySubnet')
    #cleanup to only get a list of subnets like mdis001, sigtrack002 etc etc
    $subnets = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $virtualNetwork
    #we have to filter out some subnets that we shouldn't/cannot use
    $subnets = $subnets | Where-Object -FilterScript {$_.name -ne 'GatewaySubnet' -AND $_.name -notlike '*container*'}
    
    ###################################################################################
    #break out the elements of the appserviceplanname we want to work on
    # $ASPsecondElement = $appServicePlanName.Split('-')[1]
    # $ASPsecondElement = $ASPsecondElement.ToString()
    # $ASPthirdElement = $appServicePlanName.Split('-')[2]
    # $ASPthirdElement = $ASPthirdElement.ToString()

    #if env = dev then we just want to find a subnet like 'pr001-subnet-farm'
    if ($envPrefix -like '*dev*'){
        Write-Host "env looks like dev so searching for an open subnet using the dev naming pattern"
        #take subnets from above and since this is dev we can filter/match the PR naming pattern we know
        $prVnets = $subnets| Where-Object { $_.name -match '^pr[\d]{3}(.)*farm$' }
        #for each subnet - check to see if it has service association link
        foreach ($subnet in $prVnets){
            #set some vars for this particular subnet we are inspecting
            $tempSubnetName = $subnet.name
            $tempSubnetAddress = $subnet.AddressPrefix
            $tempCheck = $subnet.ServiceAssociationLinks.ProvisioningState
            #if the subnet we're inspecting is actually empty/null/open to be used lets go ahead and use it
            if ($null -eq $tempCheck){
                Write-Host "----------------------------------------------------"
                Write-Host "you can use this subnet, its open: $tempSubnetName | $tempSubnetAddress"
                Write-Host "WE FOUND AN OPEN SUBNET!! Returning this subnet name. Exiting findOpenSubnetFunction."
                Return $tempSubnetName
            }
            else {
                Write-Host "----------------------------------------------------"
                Write-Host "trying next subnet in list of subnets. You may need to manually create a fresh one on the aformentioned vnet in order to avoid this error."
                Write-Host "----------------------------------------------------"
            }
        }
    }
    #else env is not a PR so we can expect different subnet naming pattern
    else {
        Write-Host "env does not look like dev so searching for an open subnet using the environment naming pattern"
        #take subnets from above and since this is NOT dev we filter/match the qa/demo/prod naming pattern we know
        $envVnets = $subnets| Where-Object { $_.name -match '^traject[\d]{3}' }
        #for each subnet - check to see if it has service association link
        foreach ($subnet in $envVnets){
            #set some vars for this particular subnet we are inspecting
            $tempSubnetName = $subnet.name
            $tempSubnetAddress = $subnet.AddressPrefix
            $tempCheck = $subnet.ServiceAssociationLinks.ProvisioningState
            #if the subnet we're inspecting is actually empty/null/open to be used lets go ahead and use it
            if ($null -eq $tempCheck){
                Write-Host "----------------------------------------------------"
                Write-Host "you can use this subnet, its open: $tempSubnetName | $tempSubnetAddress"
                Write-Host "WE FOUND AN OPEN SUBNET!! Returning this subnet name. Exiting findOpenSubnetFunction."
                Return $tempSubnetName
            }
            else {
                Write-Host "----------------------------------------------------"
                Write-Host "trying next subnet in list of subnets. You may need to manually create a fresh one on the aformentioned vnet in order to avoid this error."
                Write-Host "----------------------------------------------------"
            }
        }
    }
#endfunction
}
#########################################################################################################################

#########################################################################################################################
#needs webAppName, webAppRG, vnetName, vnetLocation, vnetRG, integrationSubnetName
Function AddVNetIntegration{
    param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $webAppName,
         [Parameter(Mandatory=$true, Position=1)]
         [string] $webAppRG,
         [Parameter(Mandatory=$true, Position=2)]
         [string] $vnetName,
         [Parameter(Mandatory=$true, Position=3)]
         [string] $vnetLocation,
         [Parameter(Mandatory=$true, Position=4)]
         [string] $vnetRG,
         [Parameter(Mandatory=$true, Position=5)]
         [string] $integrationSubnetName
         
    )
    ######VERIFIED WORKING#############################
    # $webAppName = 'qa-mdisapp-functions'
    # $webAppRG = 'qa-strdsrv-bgfun'
    # $vnetName = $virtualNetwork.Name
    # $vnetLocation = $virtualNetwork.Location
    # $vnetRG = $virtualNetwork.ResourceGroupName
    # $integrationSubnetName = 'mdisapp001-subnet-farm'
    ###################################################
    #Property array with the SubnetID
    #/subscriptions/7777777-7777-7777--777777777777/resourceGroups/qa-enterprise-netlb/providers/Microsoft.Network/virtualNetworks/qa-enterprise-vnet/subnets/mdisapp-function
    $properties = @{
        subnetResourceId = "/subscriptions/7777777-7777-7777--777777777777/resourceGroups/$vnetRG/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$integrationSubnetName"
    }
    #Creation of the VNet integration
    $vNetParams = @{
        ResourceName = "$webAppName/VirtualNetwork"
        Location = $vnetLocation
        ResourceGroupName = $webAppRG
        ResourceType = 'Microsoft.Web/sites/networkConfig'
        PropertyObject = $properties
    }
    #run the action command that does something. do it with -force so there is no prompt for user input
    New-AzResource @vNetParams -force
#end function
}
#########################################################################################################################

#endregion
####################################################################################################################################

#in the case of Traject we only ever have one app service plan to look at with multiple webapps apart of it

#first we get the vnet we will need to work with
Write-Host "--------------------------------------------------------------------"
Write-Host "getting virtual nework needed for this appserviceplanname: $appServicePlanName"
$virtualNetwork = DetermineVNET $appServicePlanName
$tempVNetName = $virtualNetwork[0]
$tempVNetRG = $virtualNetwork[1]
$tempVNetLocation = $virtualNetwork[2]
Write-Host "here is the vnet|RG|location we will be using: $tempVNetName | $tempVNetRG | $tempVNetLocation "
Write-Host "--------------------------------------------------------------------"

#find open subnet
Try{
    Write-Host "Try getting an open subnet for this appserviceplan name on that vnet we just found"
    $openSubnet = FindOpenSubnet $appServicePlanName $envPrefix
    Write-Host "done running the findOpenSubnet function"
    Write-Host "heres what we found"
    Write-Host "$openSubnet"
}
Catch{
    Write-Host "failed running FindOpenSubnet against the above. Continuing anyway"
    Write-Host $Error[0].ToString()
    Continue
}
Write-Host "--------------------------------------------------------------------"

#for each webapp on that appserviceplan, add them to the same subnet (each app on a farm needs to be on the same subnet)
foreach ($resource in $resources){
    Write-Host "-------------------------------------------------------------" 
    $tempWebAppName = $resource.Name
    $tempRg1 = $resource.ResourceGroup
    Write-Host "first remove all vnets so we dont have any vnet confusion (so webapp1 is on vnet1 and webapp2 is on vnet2 or cant join vnet 2 due to error)"
    Try{
        az webapp vnet-integration remove -g $tempRG1 -n $tempWebAppName
    }
    Catch{
        Write-Host "failed running command to remove vnet integration for this webapp: $tempWebAppName"
    }
    Write-Host "done removing vnet integrations for each webapp now lets add it"
    Write-Host "-------------------------------------------------------------" 
}

foreach($resource in $resources){
    Write-Host "-------------------------------------------------------------" 
    $tempWebAppName = $resource.Name
    $tempRg1 = $resource.ResourceGroup
    Write-Host "here are the params we're about to feed to AddVNETIntegration"
    Write-Host "webappname: $tempWebAppName, RG: $tempRg1"
    Write-Host "plus the vnet|RG|location we will be using: $tempVNetName | $tempVNetRG | $tempVNetLocation "
    #$openSubnet
    Try{
        Write-Host "Try to finally run the command to actually add the vnet"
        #webAppName, webAppRG, vnetName, vnetLocation, vnetRG, integrationSubnetName
        AddVNetIntegration $resource.Name $tempRg1 $tempVNetName $tempVNetLocation $tempVNetRG $openSubnet
        Write-Host "done running the AddVNetIntegration function & commands"
    }
    Catch{
        Write-Host "failed running AddVNetIntegration against the above. Continuing anyway"
        Write-Host $Error[0].ToString()
        Continue
    }
}