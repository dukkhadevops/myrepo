[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)][string]$dbConnectionString,
    [Parameter(Mandatory = $True)][string]$environment,
    [Parameter(Mandatory = $True)][string]$rootDirectory, #this is the path that the sourcecode resides, it should have the following folders: WebClient, WebApi, devops/powershell
    [Parameter(Mandatory = $False)][string]$domain
)

function FindJsonPrimitivesAndReplaceWithNewValue($path, $originalJson, $newValues) {

    # Iterate over json element names
    ForEach ($jsonElementKey in $originalJson.psobject.properties.name) {
        # Get the actual json element object
        $jsonValue = $originalJson.psobject.properties[$jsonElementKey]

        # Check if value is JSON, if so, keep parsing recursively, otherwise look for matching key and swap values.
        if ($jsonValue.value -match '^@\{.*\}' -and $jsonValue.typeNameOfValue -eq "System.Management.Automation.PSCustomObject") {
            # This throws if value is not json
            $parsedJsonValue = $jsonValue.value

            # Recursively call same method on child json building path parameter
            FindJsonPrimitivesAndReplaceWithNewValue "$path$jsonElementKey." $parsedJsonValue $newValues
        }
        else {
            $matchingEnvVar = $newValues["$path$jsonElementKey"]
            if (-not ([string]::IsNullOrEmpty($matchingEnvVar))) {
                Write-Output "Replacing value for key: $path$jsonElementKey"
                Write-Output "  -$($jsonValue.value)`n    ..replaced with..`n  -$matchingEnvVar"
                $jsonValue.value = $matchingEnvVar
            }
            else {
                # Write-Output "  .. Not found"		
            }
        }
    }
}

function ReplaceJsonSettingInpath($originalJson, $newValues) {
    Write-Output "OLD ITEMS"
    Write-Output $originalJson

    Write-Output "------"
    Write-Output "STARTING REPLACEMENT"
    Write-Output "------"

    FindJsonPrimitivesAndReplaceWithNewValue "" $originalJson $newValues

    Write-Output "------"
    Write-Output "REPLACEMENT COMPLETE"
    Write-Output "------"
}

#Finding the needed settings
$environment = "$environment"
$easyPostProdApiKey = $env:easyPostProdApiKey
$easyPostTestApiKey = $env:easyPostTestApiKey
$easyPostUseTestApiKey = $env:easyPostUseTestApiKey
$easyPostEnableEnvironmentToggle = $env:easyPostEnableEnvironmentToggle
$upsApiClientAuthenticationPassword = $env:UpsApiClientAuthenticationPassword
$resetPasswordTokenLifetimeInDays = $env:ResetPasswordTokenLifetimeInDays

#Release ID #2 is the PR build
if ("2" -eq $env:RELEASE_DEFINITIONID) {
    $isPREnvironment = "true";
}
else  {
    $isPREnvironment = "false";
}

#showing variables with values
Write-Output "Environment: $environment"
Write-Output "RootDirectory: $rootDirectory"
Write-Output "EasyPostProdApiKey: $($easyPostProdApiKey.Substring(0,5))..."
Write-Output "EasyPostTestApiKey: $($easyPostTestApiKey.Substring(0,5))..."
Write-Output "EasyPostUseTestApiKey: $($easyPostUseTestApiKey)"
Write-Output "EasyPostEnableEnvironmentToggle: $($easyPostEnableEnvironmentToggle)"
Write-Output "UpsApiClientAuthenticationPassword: $($upsApiClientAuthenticationPassword.Substring(0,3))..."
Write-Output "GainsightAnalyticsAppId: $($env:GAINSIGHTANALYTICSAPPID)..."
Write-Output "ConnectionString: $($dbConnectionString.Substring(0,10))..."

# Get Application Domains
if($PSBoundParameters.ContainsKey('domain')) {
    $clientDomain = "$domain";
    $apiDomain = "$domain";
    $enforceHttpsRedirection = "false";
}
else {
    $clientDomain = "$environment-traject-client.azurewebsites.net";
    $apiDomain = "$environment-traject-api.azurewebsites.net";
    $enforceHttpsRedirection = "true";
}

#replacing the settings
$settingContent = Get-Content "$rootDirectory/devops/powershell/traject-variables.txt"
$settingContent = $settingContent -replace "\$\[ClientDomain\]", $clientDomain
$settingContent = $settingContent -replace "\$\[ApiDomain\]", $apiDomain
$settingContent = $settingContent -replace "\$\[EasyPostProdApiKey\]", $easyPostProdApiKey
$settingContent = $settingContent -replace "\$\[EasyPostTestApiKey\]", $easyPostTestApiKey
$settingContent = $settingContent -replace "\$\[EasyPostUseTestApiKey\]", $easyPostUseTestApiKey
$settingContent = $settingContent -replace "\$\[EasyPostEnableEnvironmentToggle\]", $easyPostEnableEnvironmentToggle
$settingContent = $settingContent -replace "\$\[UpsApiClientAuthenticationPassword\]", $upsApiClientAuthenticationPassword
$settingContent = $settingContent -replace "\$\[GainsightAnalyticsAppId\]", $env:GAINSIGHTANALYTICSAPPID
$settingContent = $settingContent -replace "\$\[SendGridOptionsApiKey\]", $env:SENDGRIDOPTIONSAPIKEY
$settingContent = $settingContent -replace "\$\[ResetPasswordTokenLifetimeInDays\]", $env:ResetPasswordTokenLifetimeInDays
$settingContent = $settingContent -replace "\$\[ReleaseVersion\]", $env:RELEASE_RELEASENAME
$settingContent = $settingContent -replace "\$\[DbConnectionString\]", "$dbConnectionString"
$settingContent = $settingContent -replace "\$\[IsPREnvironment\]", $isPREnvironment
$settingContent = $settingContent -replace "\$\[EnforceHttpsRedirection\]", $enforceHttpsRedirection

$settingsRaw = $settingContent | Select-String -Pattern '^([^:]*): ([^\n]*)$'

$settings = @{ }

ForEach ($variable in $settingsRaw) {
    $key = $variable.Matches.Groups[1].Value
    $value = $variable.Matches.Groups[2].Value
    $value = [System.Net.WebUtility]::HtmlDecode($value)
    
    # Treat JSON as such, otherwise fallback to primitive (handles arrays, etc)
    try {
        $value = $value | ConvertFrom-Json
    }
    catch { }
    Write-Output "Variable Added: $key : $value"

    $settings[$key] = $value
}

# Api appsettings.json
Write-Output "Starting AppSettings.json files"
$appJsonFiles = Get-ChildItem $rootDirectory appsettings.json -recurse
Write-Output $appJsonFiles 

ForEach ($file in $appJsonFiles) {
    Write-Output "Found file $($file.FullName)"  
    Write-Output "Updating json files with correct values"
    $json = Get-Content $file.PSPath -Raw | ConvertFrom-Json  

    ReplaceJsonSettingInpath $json $settings
        
    Write-Output "Saving File: $($file.FullName)"
    $json | ConvertTo-Json -Depth 10 | Out-File "$($file.FullName)"
}
# Angular config.json
Write-Output "Starting config.json files"
$environmentTsFiles = Get-ChildItem $rootDirectory config.json -recurse
Write-Output $environmentTsFiles 

ForEach ($file in $environmentTsFiles) {
    Write-Output "Found file $($file.FullName)"  
    Write-Output "Updating json files with correct values"
    $fileContents = Get-Content $file.PSPath -Raw

    $json = $fileContents | ConvertFrom-Json  
    Write-Output $json  

    ReplaceJsonSettingInpath $json $settings
        
    Write-Output "Saving File: $($file.FullName)"
    $output = $json | ConvertTo-Json -Depth 10

    $output | Out-File "$($file.FullName)" -encoding "ASCII"
}

Write-Output "END OF CODE"