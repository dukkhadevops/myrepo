param(
    [Parameter(Mandatory=$True)][string]$envPrefix,
    [Parameter(Mandatory=$True)][string]$envResourceId
)

Write-Host "here is your incoming param - envPrefix = $envPrefix"
Write-Host "envResourceId incoming parameter, which we need for db connection = $envResourceId"
#WE LOOKUP THE ADMIN PASS USING 'DEV' but the dbconnection actually needs something like "trjc-007-sql" >> thats why we need both here

#admin lookup
$adminsecretlookupvalue = $envPrefix + "-traject-admin-SQLpassword"
$UPSpasswordsecretlookupvalue = 'All-traject-UPSpassword'

Write-Host "our adminlookup value = $adminsecretlookupvalue"
Write-Host "our UPSpasswordlookup value = $UPSpasswordsecretlookupvalue"

#new UPS Capital Api Client keys/tokens/values lookups
$upsCapitalApiBearerTokenLookupValue = $envPrefix + "-traject-UpsCapitalApiBearerToken"
$upsCapitalApiClientIdTokenLookupValue = $envPrefix + "-traject-UpsCapitalApiClientIdToken"
$upsCapitalApiClientSecretTokenLookupValue = $envPrefix + "-traject-UpsCapitalApiClientSecretToken"
Write-Host "our upsCapitalApiBearerToken value = $upsCapitalApiBearerTokenLookupValue"
Write-Host "our upsCapitalApiClientIdToken value = $upsCapitalApiClientIdTokenLookupValue"
Write-Host "our upsCapitalApiClientSecretToken value = $upsCapitalApiClientSecretTokenLookupValue"
Write-Host "*************************************************************************************************"

#lookup the secrets in the keyvault
Write-Host "starting get-azkeyvaultsecret commands to get the values from vault"
#
$upsApiPassword = Get-AzKeyVaultSecret -VaultName 'vault' -Name $UPSpasswordsecretlookupvalue
$adminsecret = Get-AzKeyVaultSecret -VaultName 'vault' -Name $adminsecretlookupvalue
#new values from Wilson
$upsCapitalApiBearerToken = Get-AzKeyVaultSecret -VaultName 'vault' -Name $upsCapitalApiBearerTokenLookupValue
$upsCapitalApiClientIdToken = Get-AzKeyVaultSecret -VaultName 'vault' -Name $upsCapitalApiClientIdTokenLookupValue
$upsCapitalApiClientSecretToken = Get-AzKeyVaultSecret -VaultName 'vault' -Name $upsCapitalApiClientSecretTokenLookupValue

#store secretvaluetext in the variable so we can see it
#$adminsecret = $adminsecret.SecretValueText
$adminsecret = $adminsecret.SecretValue
$upsApiPassword = $upsApiPassword.SecretValue
#new values from Wilson
$upsCapitalApiBearerToken = $upsCapitalApiBearerToken.SecretValue
$upsCapitalApiClientIdToken = $upsCapitalApiClientIdToken.SecretValue
$upsCapitalApiClientSecretToken = $upsCapitalApiClientSecretToken.SecretValue
#####
#now each secret is in a secure string
#####
#here's the code to take it back out of a Secure String. We only have to do this because we need the dbpassword set in the db connection string
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($adminsecret)
$adminsecret = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
#$upsApiPassword
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($upsApiPassword)
$upsApiPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
#$upsCapitalApiBearerToken
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($upsCapitalApiBearerToken)
$upsCapitalApiBearerToken = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
#$upsCapitalApiClientIdToken
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($upsCapitalApiClientIdToken)
$upsCapitalApiClientIdToken = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
#$upsCapitalApiClientSecretToken
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($upsCapitalApiClientSecretToken)
$upsCapitalApiClientSecretToken = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)

Write-Host "*************************************************************************************************"
Write-Host "what we found for adminsecret = $adminsecret"
Write-Host "what we found for upsApiPassword  = $upsApiPassword"
Write-Host "what we found for upsCapitalApiBearerToken = $upsCapitalApiBearerToken"
Write-Host "what we found for upsCapitalApiClientIdToken = $upsCapitalApiClientIdToken"
Write-Host "what we found for upsCapitalApiClientSecretToken = $upsCapitalApiClientSecretToken"

Write-Host "##vso[task.setvariable variable=adminsecret;isOutput=true]$adminsecret"
Write-Host "now create db connection string using admin"
$dbHostname = "$envResourceId-traject-sqlserver"
$dbConnectionString = "Server=$($dbHostname).database.windows.net;Database=traject;User Id=admin;Password=$adminsecret;MultipleActiveResultSets=True"
$integrationTestsConnString = "Server=$($dbHostname).database.windows.net;Database=traject_integrationtests;User Id=admin;Password=$adminsecret;MultipleActiveResultSets=True"

Write-Host "heres the connection string: $dbConnectionString"
Write-Host "##vso[task.setvariable variable=DatabaseConnectionString;isOutput=true]$dbConnectionString"
Write-Host "here the integrationTestsConnString: $integrationTestsConnString"
Write-Host "##vso[task.setvariable variable=integrationTestsConnString;isOutput=true]$integrationTestsConnString"
Write-Host "##vso[task.setvariable variable=upsApiPassword;isOutput=true]$upsApiPassword"
#new tasks for new upscapitalapi values
Write-Host "##vso[task.setvariable variable=upsCapitalApiBearerToken;isOutput=true]$upsCapitalApiBearerToken"
Write-Host "##vso[task.setvariable variable=upsCapitalApiClientIdToken;isOutput=true]$upsCapitalApiClientIdToken"

#IN THE CASE OF PROD the upscapitalapiclientsecrettoken needs to be empty/null so try
if ($envPrefix -like '*prod*'){
    $null = $upsCapitalApiClientSecretToken
    Write-Host "envprefix is like prod so null out the upsCapitalApiClientSecretToken and show here: $upsCapitalApiClientSecretToken"
    Write-Host "the value shown here is about to try and be set in the pipeline variable - hopefully its allowed to be null"
}
Write-Host "##vso[task.setvariable variable=upsCapitalApiClientSecretToken;isOutput=true]$upsCapitalApiClientSecretToken"

Write-Host "done running pull_security script"