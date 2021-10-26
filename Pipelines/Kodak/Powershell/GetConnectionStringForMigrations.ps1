[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)][string]$dbHostname,
    [Parameter(Mandatory = $True)][string]$dbUsername,
    [Parameter(Mandatory = $True)][securestring]$dbPassword,
    [Parameter(Mandatory=$True)][string]$variablePath #this is the path that contains the traject-variables file.
)

#Finding the needed settings
$environment = "$environment"

#showing variables with values
Write-Output "Environment: $environment"
Write-Output "VariablePath: $variablePath"

#replacing the settings
$settingContent = Get-Content "$variablePath/traject-variables.txt"
$settingContent = $settingContent -replace "\$\[DbHostname\]", $dbHostname
$settingContent = $settingContent -replace "\$\[DbUsername\]", $dbUsername
$settingContent = $settingContent -replace "\$\[DbPassword\]", $dbPassword

$settingsRaw = $settingContent | Select-String -Pattern '^([^:]*): ([^\n]*)$'

ForEach($variable in $settingsRaw)
{
    $key = $variable.Matches.Groups[1].Value
    
    if($key -eq "ConnectionStrings.DefaultConnection") {
        $value = $variable.Matches.Groups[2].Value
    
        Write-Host "##vso[task.setvariable variable=DatabaseConnectionString;isOutput=true]$value"

        Write-Host "Added Env Variables: $($env:SYSTEM_TASKINSTANCENAME)_DatabaseConnectionString = $value"        
        
        break;
    }
}

Write-Output "END OF CODE"