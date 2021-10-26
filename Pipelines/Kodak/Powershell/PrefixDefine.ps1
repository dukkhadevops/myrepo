param(
    [string]$environment,
    [string]$branchname
)

Write-Host "Enviroment branch: $branchname / $environment"

# Is it a PR name
if($branchname -match "^(.*)\/(\w+)-(\d+)[-|_](.*)$") {
    Write-Host "This is a branch build."
    $branchid = $matches[2] + "-" + $matches[3]
}
else
{
    if($environment.length -gt 0 -And $branchname.length -gt 8) {
        $environmentPart = $environment | Select-String -Pattern '^([^-]*)'
        $branchid = $environmentPart.Matches.Groups[1].Value
        Write-Host "This is an environment build."
    } else {
        if($branchname.Length -gt 0 -And $branchname.Length -lt 8) {
            $branchid = $branchname
            Write-Host "This is an branch name build."
        } else {
            $branchid = $($env:BUILD_SOURCEBRANCHNAME)
            if($branchid.length -gt 8) {
                $branchid = $branchid.Substring(0,8)
            }
            Write-Host "This is source branch build."
        }
    }
}

$branchid = $branchid.toLower()
$storageid = $branchid.Replace("-", "")
if($storageid -eq 'Development') { $storageid = 'Dev' }
if($storageid -eq 'QualityAssurance') { $storageid = 'Qa' }
if($storageid -eq 'Production') { $storageid = 'Prod' }

Write-Host "My branch Id $branchid"
Write-Host "Storage Id $storageid"
Write-Host "setting global variables...."
Write-Host "##vso[task.setvariable variable=ResourceId;isOutput=true]$branchid"
Write-Host "##vso[task.setvariable variable=StorageId;isOutput=true]$storageid"

#if branchid has a "-" in it, it must be a PR so set an envPrefix of "Dev" for later use
If ($branchid -like "*-*") {
    Write-Host "branchid found a - in it so it must be a PR build"
    Write-Host "lets set an environment prefix now"
    $envPrefix = "Dev"
    $B2CDomain = "securedev"
    $B2CClientId = "77777777-7777-7777-7777-777777777777" #got this from Ed
    #new vars for Rob which he needs for automated testing
    $automatedUITestingPrefix = "PR"
    $behaveParallelParams = "--feature_list feature_list.txt --tags pr_smoke,pr_shipping --processes 12"

    Write-Host "##vso[task.setvariable variable=ENVPrefix;isOutput=true]$envPrefix"
    Write-Host "##vso[task.setvariable variable=B2CDomain;isOutput=true]$B2CDomain"
    Write-Host "##vso[task.setvariable variable=B2CClientId;isOutput=true]$B2CClientId"
    Write-Host "##vso[task.setvariable variable=automatedUITestingPrefix;isOutput=true]$automatedUITestingPrefix"
    Write-Host "##vso[task.setvariable variable=behaveParallelParams;isOutput=true]$behaveParallelParams"
}

Else {
    Write-Host "branchid did NOT find a - in it so it can't be a PR build"
    $envPrefix = $branchid
    Write-Host "##vso[task.setvariable variable=ENVPrefix;isOutput=true]$envPrefix"

    If ($branchid -like "*QA*"){
        $B2CDomain = "secureqa"
        $B2CClientId = "7777-7777-7777-7777-777777777777"
        #new var for Rob which he needs for automated testing
        $automatedUITestingPrefix = "QA"
        $behaveParallelParams = "--suite features/feature --processes 12"

        Write-Host "##vso[task.setvariable variable=B2CDomain;isOutput=true]$B2CDomain"
        Write-Host "##vso[task.setvariable variable=B2CClientId;isOutput=true]$B2CClientId"
        Write-Host "##vso[task.setvariable variable=automatedUITestingPrefix;isOutput=true]$automatedUITestingPrefix"
        Write-Host "##vso[task.setvariable variable=behaveParallelParams;isOutput=true]$behaveParallelParams"
    }
    Elseif ($branchid -like "*DEMO*") {
        $B2CDomain = "secureqa"
        $B2CClientId = "7777-7777-7777-7777-777777777777"
        #new var for Rob which he needs for automated testing
        $automatedUITestingPrefix = "DEMO"
        $behaveParallelParams = "--suite features/feature --processes 12"

        Write-Host "##vso[task.setvariable variable=B2CDomain;isOutput=true]$B2CDomain"
        Write-Host "##vso[task.setvariable variable=B2CClientId;isOutput=true]$B2CClientId"
        Write-Host "##vso[task.setvariable variable=automatedUITestingPrefix;isOutput=true]$automatedUITestingPrefix"
        Write-Host "##vso[task.setvariable variable=behaveParallelParams;isOutput=true]$behaveParallelParams"
    }
    Elseif ($branchid -like "*PROD*") {
        $B2CDomain = "secure"
        $B2CClientId = "7777-7777-7777-7777-777777777777"
        #new var for Rob which he needs for automated testing
        $automatedUITestingPrefix = "PROD"
        $behaveParallelParams = "--feature_list feature_list.txt --tags prod_smoke,prod_shipping --processes 12"
  
        Write-Host "##vso[task.setvariable variable=B2CDomain;isOutput=true]$B2CDomain"
        Write-Host "##vso[task.setvariable variable=B2CClientId;isOutput=true]$B2CClientId"
        Write-Host "##vso[task.setvariable variable=automatedUITestingPrefix;isOutput=true]$automatedUITestingPrefix"
        Write-Host "##vso[task.setvariable variable=behaveParallelParams;isOutput=true]$behaveParallelParams"
    
    }
    Else { 
        Write-Host "no branchid match found"
    }
}

Write-Host "show the new automatedUITestingPrefix variable we just set: $automatedUITestingPrefix"
Write-Host "show the new behaveParallelParams string we just set: $behaveParallelParams"

#now a section to set names for ui testing artifacts
$logArtifactName = $automatedUITestingPrefix + "ParallelTestLog"
Write-Host "here is the new name we're going to use for the log artifact: $logArtifactName"

$screenshotArtifactName = $automatedUITestingPrefix + "uiTestingScreenshots"
Write-Host "here is the new name we're going to use for the log artifact: $screenshotArtifactName"

Write-Host "setting the variables so we can use them later"
Write-Host "##vso[task.setvariable variable=logArtifactName;isOutput=true]$logArtifactName"
Write-Host "##vso[task.setvariable variable=screenshotArtifactName;isOutput=true]$screenshotArtifactName"