param(
    [Parameter(Mandatory=$True)][string]$environment,
    [Parameter(Mandatory=$True)][string]$variablesfilepath,
    [Parameter(Mandatory=$True)][string]$jsonsearchpath,
    [Parameter(Mandatory=$True)][string]$envResourceId,
    [Parameter(Mandatory=$True)][string]$dbConnectionString,
    [Parameter(Mandatory=$True)][string]$buildVersion,
    [Parameter(Mandatory=$True)][string]$upsApiPassword,
    #[Parameter(Mandatory=$True)][string]$upsCapitalApiQuoteEndpoint, #these are not secrets so we can just set them in this script instead of pull in more params
    #[Parameter(Mandatory=$True)][string]$upsCapitalApiConfirmationEndpoint,
    [Parameter(Mandatory=$True)][string]$upsCapitalApiBearerToken, #these are secrets from the vault we get from pull_security
    [Parameter(Mandatory=$True)][string]$upsCapitalApiClientIdToken,
    [Parameter(Mandatory=$True)][string]$upsCapitalApiClientSecretToken
)
Write-Output "********************************************************************"
Write-Output "Here are the incoming parameters"
Write-Output "environment incoming parameter = $environment"
Write-Output "variablesfilepath incoming parameter = $variablesfilepath"
Write-Output "jsonsearchpath incoming parameter = $jsonsearchpath"
Write-Output "envResourceId incoming parameter = $envResourceId"
Write-Output "dbConnectionString incoming parameter = $dbConnectionString"
Write-Output "buildVersion incoming parameter = $buildVersion"
Write-Output "upsApiPassword incoming parameter: $upsApiPassword"
#Write-Output "upsCapitalApiQuoteEndpoint incoming parameter: $upsCapitalApiQuoteEndpoint"
#Write-Output "upsCapitalApiConfirmationEndpoing incoming parameter: $upsCapitalApiConfirmationEndpoint"
Write-Output "upsCapitalApiBearerToken incoming parameter: $upsCapitalApiBearerToken"
Write-Output "upsCapitalApiClientIdToken incoming parameter: $upsCapitalApiClientIdToken"
Write-Output "upsCapitalApiClientSecretToken incoming parameter: $upsCapitalApiClientSecretToken"
Write-Output "********************************************************************"

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

#tighten up the ol' resourceId so its consistent everywhere
$envResourceId = $envResourceId.toLower()

#if envResourceId has a "-" in it, it must be a PR so set an envPrefix of "Dev" for later use
If ($envResourceId -like "*-*") {
    Write-Output "envResourceId found a - in it so it must be a PR build"
    $envPrefix = "Dev"
}
Else {
    Write-Output "envResource idea did NOT find a - in it so it can't be a PR build"
    $envPrefix = $envResourceId
}

#$upsApiPassword is always the same, for every env, so set it here using the old variable name from the original pipeline
$UpsApiClientAuthenticationPassword = $upsApiPassword

##############################################################################################
#region handle all non-secret values, variables
#if prefix is like test/dev/uat, ust the prefix name to create the appUrl & apiUrl
If ($envPrefix -like "*dev*"){
    $clientDomain = "$envResourceId-traject-client.azurewebsites.net"
    $apiDomain = "$envResourceId-traject-api.azurewebsites.net"
    $easyPostTestApiKey = "7777777777777777777777"
    $easyPostProdApiKey = "7777777777777777777777"
    $easyPostUseTestApiKey = "true"
    $easyPostEnableEnvironmentToggle = "true"
    $gainsightAnalyticsAppID = "???"
    $sendGridOptionsApiKey = "SG.77777777777777777777777777777777777777777777"
    $resetPasswordTokenLifetimeInDays = 1
    #$env:RELEASE_RELEASENAME ###this should be set already but worth noting it here so all environments have the same list
    #$dbConnectionString    ###this should be set already but worth noting it here so all environments have the same list
    $isPREnvironment = "true"
    $enforceHttpsRedirection = "false"
    #more new vars
    $upsCapitalApiQuoteEndpoint = "https://endpoint/v2"
    $upsCapitalApiConfirmationEndpoint = "https://endpoint/v2"
}
ElseIf ($envPrefix -like "*qa*"){
    $clientDomain = "qa.project.com"
    $apiDomain = "qa.project.com"
    $easyPostTestApiKey = "7777777777777777777777"
    $easyPostProdApiKey = "7777777777777777777777"
    $easyPostUseTestApiKey = "true"
    $easyPostEnableEnvironmentToggle = "true"
    $gainsightAnalyticsAppID = "7777777777777777777777"
    $sendGridOptionsApiKey = "SG.77777777777777777777777777777777777777777777"
    $resetPasswordTokenLifetimeInDays = 1
    #$env:RELEASE_RELEASENAME ###this should be set already but worth noting it here so all environments have the same list
    #$dbConnectionString    ###this should be set already but worth noting it here so all environments have the same list
    $isPREnvironment = "false"
    $enforceHttpsRedirection = "false"
    #more new vars
    $upsCapitalApiQuoteEndpoint = "https://upscapi.ams1907.com/apis/list-extstg/quote/v2"
    $upsCapitalApiConfirmationEndpoint = "https://upscapi.ams1907.com/apis/list-extstg/coverage/v2"
}
Elseif ($envPrefix -like "*demo*"){
    $clientDomain = "demo.project.com"
    $apiDomain = "demo.project.com"
    $easyPostTestApiKey = "7777777777777777777777"
    $easyPostProdApiKey = "7777777777777777777777"
    $easyPostUseTestApiKey = "true"
    $easyPostEnableEnvironmentToggle = "true"
    $gainsightAnalyticsAppID = "???"
    $sendGridOptionsApiKey = "SG.77777777777777777777777777777777777777777777"
    $resetPasswordTokenLifetimeInDays = 10
    #$env:RELEASE_RELEASENAME ###this should be set already but worth noting it here so all environments have the same list
    #$dbConnectionString    ###this should be set already but worth noting it here so all environments have the same list
    $isPREnvironment = "false"
    $enforceHttpsRedirection = "false"
    #more new vars
    $upsCapitalApiQuoteEndpoint = "https://endpoint/v2"
    $upsCapitalApiConfirmationEndpoint = "https://endpoint/v2"
}
ElseIf ($envPrefix -like "*prod"){
    $clientDomain = "project.com"
    $apiDomain = "project.com"
    $easyPostTestApiKey = "7777777777777777777777"
    $easyPostProdApiKey = "7777777777777777777777"
    $easyPostUseTestApiKey = "false"
    $easyPostEnableEnvironmentToggle = "false"
    $gainsightAnalyticsAppID = "AP-777777777777-7"
    $sendGridOptionsApiKey = "SG.77777777777777777777777777777777777777777777"
    $resetPasswordTokenLifetimeInDays = 10
    #$env:RELEASE_RELEASENAME ###this should be set already but worth noting it here so all environments have the same list
    #$dbConnectionString    ###this should be set already but worth noting it here so all environments have the same list
    $isPREnvironment = "false"
    $enforceHttpsRedirection = "false"
    #new vars
    $upsCapitalApiQuoteEndpoint = "https://endpoint/v2"
    $upsCapitalApiConfirmationEndpoint = "https://endpoint/v2"
}
#endregion
##############################################################################################
$settingContent = Get-Content "$variablesfilepath/traject-variables.txt"
Write-Output "Here is the content from settingContent."
Write-Output "********************************************************************"
Write-Output $settingContent
Write-Output "********************************************************************"
Write-Output "Now replace settings"
$settingContent = $settingContent -replace "\$\[ClientDomain\]", $clientDomain
$settingContent = $settingContent -replace "\$\[ApiDomain\]", $apiDomain
$settingContent = $settingContent -replace "\$\[EasyPostProdApiKey\]", $easyPostProdApiKey
$settingContent = $settingContent -replace "\$\[EasyPostTestApiKey\]", $easyPostTestApiKey
$settingContent = $settingContent -replace "\$\[EasyPostUseTestApiKey\]", $easyPostUseTestApiKey
$settingContent = $settingContent -replace "\$\[EasyPostEnableEnvironmentToggle\]", $easyPostEnableEnvironmentToggle
$settingContent = $settingContent -replace "\$\[UpsApiClientAuthenticationPassword\]", $upsApiClientAuthenticationPassword
#new vars
$settingContent = $settingContent -replace "\$\[upsCapitalApiQuoteEndpoint\]", $upsCapitalApiQuoteEndpoint
$settingContent = $settingContent -replace "\$\[upsCapitalApiConfirmationEndpoint\]", $upsCapitalApiConfirmationEndpoint
$settingContent = $settingContent -replace "\$\[upsCapitalApiBearerToken\]", $upsCapitalApiBearerToken
$settingContent = $settingContent -replace "\$\[upsCapitalApiClientIdToken\]", $upsCapitalApiClientIdToken
$settingContent = $settingContent -replace "\$\[upsCapitalApiClientSecretToken\]", $upsCapitalApiClientSecretToken
#
$settingContent = $settingContent -replace "\$\[GainsightAnalyticsAppId\]", $gainsightAnalyticsAppID
$settingContent = $settingContent -replace "\$\[SendGridOptionsApiKey\]", $sendGridOptionsApiKey
$settingContent = $settingContent -replace "\$\[ResetPasswordTokenLifetimeInDays\]", $resetPasswordTokenLifetimeInDays
$settingContent = $settingContent -replace "\$\[ReleaseVersion\]", $buildVersion
$settingContent = $settingContent -replace "\$\[DbConnectionString\]", "$dbConnectionString"
$settingContent = $settingContent -replace "\$\[IsPREnvironment\]", $isPREnvironment
$settingContent = $settingContent -replace "\$\[EnforceHttpsRedirection\]", $enforceHttpsRedirection
Write-Output "Here is new settingContent"
Write-Output "********************************************************************"
Write-Output $settingContent
Write-Output "********************************************************************"
$settingsRaw = $settingContent | Select-String -Pattern '^([^:]*): ([^\n]*)$'

$settings = @{}
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

# Angular config.json
Write-Output "Getting appsettings.json & config.json files in $jsonsearchpath"
Write-Output "here they are"
$configJsonFiles = @()
$configJsonFiles += Get-ChildItem $jsonsearchpath appsettings.json -recurse
$configJsonFiles += Get-ChildItem $jsonsearchpath config.json -recurse
Write-Output "********************************************************************"
Write-Output $configJsonFiles
Write-Output "********************************************************************"
Write-Output "now starting updates on each file"
Write-Output "********************************************************************"
ForEach ($file in $configJsonFiles) {
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

Write-Output "File update complete"