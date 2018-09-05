########
# Description:  Powershell DSC to configure APP Pools & Sites in IIS for API Servers to be used in conjunction with other API Server DSC
# Changes:      04/17/2018      Initial creation
#               05/2/2018       change everything over for use with Web Servers
#               
########

##########
#ASSUMPTION: You are copying this script out to the server then executing it from there
##########

#########
#region for functions for grabbing Secrets from SecretServer
#########
$url = "https://sercretserver/webservices/sswebservice.asmx"
$username = "serviceaccount"
$password = "password"
$domain = 'domain'   # leave blank for local users

#if you're using TLS1.2 instead of 1.0, you need this
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#we need this module in order to use set-itemproperty below
Import-Module WebAdministration

# function that takes in a search term and returns the SecretServer ID. Use the ID to get the password you want in another function.
Function FindSecretID ($searchterm){

    #initial setup of webservice proxy using the url we set
    $proxy = New-WebServiceProxy $url -UseDefaultCredential

    #try to authenticate using the user, pass and domain we provided. this is the login to SecretServer
    $result1 = $proxy.Authenticate($username, $password, '', $domain)
    if ($result1.Errors.length -gt 0)
        {
            $result1.Errors[0]
            exit
        } 
    else 
        {
            #save our login session token into $token
            $token = $result1.Token
        }
    
    #use search term to find the ID of the Secret 
    $result2 = $proxy.SearchSecrets($token, $searchterm,$null,$null)
    if ($result2.Errors.length -gt 0)
        {
            $result2.Errors[0]
        }
    else
        {
        $secretname = $result2.SecretSummaries.SecretName
        $return1 = $result2.SecretSummaries.SecretID
        #Write-Host $secretname " $secretid"

        #return the secret ID we need for the other function
        Return $return1
        }
}

#call function
#FindSecretID $searchterm

# function that takes in a secret ID and returns the password for that Secret. Use the Find function to get the ID first.
Function GetSecret ($secretID){
    
    $proxy = New-WebServiceProxy $url -UseDefaultCredential
    $result1 = $proxy.Authenticate($username, $password, '', $domain)
    if ($result1.Errors.length -gt 0)
        {
            $result1.Errors[0]
            exit
        } 
    else 
        {
            $token = $result1.Token
        }
    $result2 = $proxy.GetSecret($token, $secretId, $false, $null)

    #return the password
    $return2 = $result2.Secret.Items[2].Value
    Return $return2

}

#########
#endregion function stuffs
#########

#just copy paste this from your #2 script where you specify this initially
$appPools = @(
        @{ AppPool = "application01"; AppPoolIdentity = "world\account01" }
        @{ AppPool = "application02"; AppPoolIdentity = "world\account02" }
        @{ AppPool = "application03"; AppPoolIdentity = "world\account03" }
    )

foreach($pool in $appPools) {
    $poolidentity = $pool.AppPoolIdentity
    $poolname = $pool.AppPool
    #create our searchterm by removing the world\ in front of the app pool identity
    $searchterm = $poolidentity.Replace("domain\","")
    #call our function to get our id, based on the search term
    $secretid = FindSecretID $searchterm
    #pass the id we just found to a function that returns the password
    $poolpass = GetSecret $secretid
    #set the app pool properties to have the identity we want with the password
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name processModel -Value @{ userName=$pool.AppPoolIdentity; password=$poolpass; identitytype=3 }
}