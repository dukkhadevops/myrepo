$computers = Get-Content -Path "C:\SVN\WindowsAdmins\Scripts\DV\RemoveXPoweredBy\computers.txt"

Foreach ($target in $computers) {

    Invoke-Command -computername $target -ScriptBlock{
        Import-module WebAdministration
        #Remove-WebConfigurationProperty -PSPath MACHINE/WEBROOT/APPHOST -Name . -Filter system.webServer/httpProtocol/customHeaders -AtElement @{name="x-powered-by" ; value='ASP.NET'} -ErrorAction Stop
        #Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/httpProtocol/customHeaders" -name "." -AtElement @{name='x-powered-by'}
        Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST/Dataverify.com'  -filter "system.webServer/httpProtocol/customHeaders" -name "." -AtElement @{name='x-powered-by'}
        
    }

#endforeach
}