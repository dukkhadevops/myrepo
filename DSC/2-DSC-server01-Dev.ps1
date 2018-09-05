#########
# Description:  Powershell DSC to configure Windows Features & setup files/folders for API Servers to be used in conjunction with other API Server DSC
# Changes:      03/28/2018      Initial creation
#               05/2/2018       change everything over for use with Web Servers
#               05/22/2018      added ISAPI restrctions
#               06/05/2018      added SessionStateTimeout & DeleteXPoweredByHTTPResponseHeader
#               06/18/2018      remove restartschedule timespan array (not what we needed) add script resource to handle PeriodRestart time property
#               06/18/2018      update LCM config to ApplyAndMonitor & remove DVConfig file resource & add scheduled task to run script on regular interval
#               06/28/2018      change over server
#
#########
#########
#ASSUMPTION: You are copying this script out to the server then executing it from there
#########

Set-ExecutionPolicy Unrestricted

#these are all the pools/sites/webapps we'll be creating & their identities
$appPools = @(
        @{ AppPool = "pool01"; AppPoolIdentity = "world\account01" }
        @{ AppPool = "pool02"; AppPoolIdentity = "world\account02" }
        @{ AppPool = "pool03"; AppPoolIdentity = "world\account03" }
    )

#these are all the default pools we'll be deleting
$defaultAppPools = @(
    "DefaultAppPool",
    ".NET v4.5",
    ".NET v4.5 Classic"
)

#lets create a variable that holds our config name since we'll be calling it up here and then all the way at the bottom.
#now we only have to change it in one place..... hopefully...
$DSCconfigName = "DSC-server01-Dev"

#create our configuration with the "Configuration" keyword. Now lets use that variable we created above.
#note the resources we're importing here. they must be included in the 1st scripts copy job
#also note the webadministration module. this should be installed by default on 2012 & up servers but not 2008 R2 etc.
Configuration $DSCconfigName {
    Import-Module WebAdministration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName xSmbShare
    Import-DscResource -ModuleName ComputerManagementDsc

    Node $env:computername {

        #disclaimer
        #do not reorder these sections, they build off one another

        ########
        #region Basic File & Folder section. 
        #Some permissions for c:\app subdirs handled in SMB share region
        ########
        
        #$dvconfigpath = "\\dfs\nas\DV_Shared\AppConfig\Servers\dvweb01uwwl\conf\dvconfig.xml"
        $path4 = "c:\www"
        $path6 = "C:\inetpub\logs\LogFiles\W3SVC1"

        File wwwDir #c:\www
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = $path4
        }

        File WebLogDir #C:\inetpub\logs\LogFiles\W3SVC1
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $path6
        }

        #endregion

        ########
        #region Windows Roles & Features section. These should all be relatively in order based on how they appear when you do a get-windowsfeature -name *web*
        ########

        WindowsFeature Web-Server  # Web Server (IIS) base/root feature
        {
               Name = "Web-Server"
               Ensure = "Present"
        }

        WindowsFeature Web-WebServer  # Web Server continued (IIS) parent featureset
        {
               Name = "Web-WebServer"
               Ensure = "Present"
        }

        WindowsFeature Web-Common-Http  # Common Http Features parent featureset
        {
               Name = "Web-Common-Http"
               Ensure = "Present"
        }

        WindowsFeature Web-Default-Doc  # Default Document
        {
               Name = "Web-Default-Doc"
               Ensure = "Present"
        }

        WindowsFeature Web-Dir-Browsing  # Directory Browsing
        {
               Name = "Web-Dir-Browsing"
               Ensure = "Present"
        }

        WindowsFeature Web-Http-Errors  # Http Errors
        {
               Name = "Web-Http-Errors"
               Ensure = "Present"
        }

        WindowsFeature Web-Static-Content  # Static Content
        {
               Name = "Web-Static-Content"
               Ensure = "Present"
        }

        WindowsFeature Web-Health # Health and Diagnostics parent featureset
        {
               Name = "Web-Health"
               Ensure = "Present"
        }

        WindowsFeature Web-Http-Logging # Http Logging
        {
               Name = "Web-Http-Logging"
               Ensure = "Present"
        }

        WindowsFeature Web-Performance  # Performance parent featureset
        {
               Name = "Web-Performance"
               Ensure = "Present"
        }

        WindowsFeature Web-Stat-Compression  # Static Content Compression
        {
               Name = "Web-Stat-Compression"
               Ensure = "Present"
        }

        WindowsFeature Web-Security  # Security parent featureset
        {
               Name = "Web-Security"
               Ensure = "Present"
        }

        WindowsFeature Web-Filtering  # Request Filtering
        {
               Name = "Web-Filtering"
               Ensure = "Present"
        }

        WindowsFeature Web-App-Dev  # Application Development parent featureset
        {
               Name = "Web-App-Dev"
               Ensure = "Present"
        }

        WindowsFeature Web-AppInit  # Application Initialization
        {
             Name = "Web-AppInit"
             Ensure = "Present"
        }

        WindowsFeature Web-ISAPI-Ext  # ISAPI Extensions
        {
             Name = "Web-ISAPI-Ext"
             Ensure = "Present"
        }

        WindowsFeature Web-ISAPI-Filter  # ISAPI Filters
        {
             Name = "Web-ISAPI-Filter"
             Ensure = "Present"
        }

        #endregion
        
        ########
        #region NON IIS Windows Features section
        ########
        WindowsFeature Net-Framework-Features  # .Net Framework 3.5 Features parent featureset
        {
             Name = "Net-Framework-Features"
             Ensure = "Present"
        }

        WindowsFeature Net-Framework-Core  # .Net Framework 3.5 (.NET 2.0 and 3.0)
        {
             Name = "Net-Framework-Core"
             Ensure = "Present"
        }

        WindowsFeature Net-Framework-45-Features  # .Net Framework 4.5 Features parent featureset
        {
             Name = "Net-Framework-45-Features"
             Ensure = "Present"
        }

        WindowsFeature Net-Framework-45-Core  # .Net Framework 4.5
        {
             Name = "Net-Framework-45-Core"
             Ensure = "Present"
        }

        WindowsFeature NET-Framework-45-ASPNET # ASP.NET 4.5
        {
            Name = "NET-Framework-45-ASPNET"
            Ensure = "Present"
        }

        WindowsFeature Net-WCF-Services45  # WCF Services
        {
             Name = "Net-WCF-Services45"
             Ensure = "Present"
        }

        WindowsFeature Net-WCF-TCP-PortSharing45  # TCP Port Sharing
        {
             Name = "Net-Framework-Core"
             Ensure = "Present"
        }

        WindowsFeature RDC #Remote Differential Compression
        {
             Name = "RDC"
             Ensure = "Present"
        }

        WindowsFeature SNMP-Service #SNMP Service Parent
        {
            Name = "SNMP-Service"
            Ensure = "Present"
        }

        WindowsFeature Telnet-Client #Telnet Client
        {
            Name = "Telnet-Client"
            Ensure = "Present"
        }

        WindowsFeature PowershellRoot #Windows Powershell parent featureset
        {
            Name = "PowershellRoot"
            Ensure = "Present"
        }

        WindowsFeature Powershell #Windows Powershell
        {
            Name = "Powershell"
            Ensure = "Present"
        }

        WindowsFeature Powershell-ISE #Powershell ISE
        {
            Name = "Powershell-ISE"
            Ensure = "Present"
        }

        #endregion

        ########
        #region App Pool & folder creation section
        ########

        #setup site folder structure & permissions
        foreach($pool in $appPools)
        {
            #if the app pool name = dataverify then create the folder in c:\www & assign permissions for it
            If ( $pool.appPool -eq "application01" )
            {
                $poolName = $pool.AppPool
                $permissionname = $poolname + "permissions"
                $identity = $pool.AppPoolIdentity

                File $poolName #setup parent dataverify directory
                {
                    Ensure = "Present"  # You can also set Ensure to "Absent"
                    Type = "Directory" # Default is "File".
                    DestinationPath = "C:\www\$poolName"
                }

                cNtfsPermissionEntry $permissionname #setup permissions on each directory
                {
                    Ensure = 'Present'
                    Path = "C:\www\$poolname"
                    Principal = $identity
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Modify'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'ReadAndExecute'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                    DependsOn = "[File]$poolname"
                }
            }
                
            #else create the folders for each apppool/app & assign permissions specific to each app pool identity/corresponding app
            #also create permissions for each identity on the dataverify parent folder with no inheritance
            ElseIf ( $pool.appPool -ne "Dataverify" )
            {
                $poolName = $pool.AppPool
                $permissionname = $poolname + "permissions"
                $identity = $pool.AppPoolIdentity

                File $poolName #setup each sites directory
                {
                    Ensure = "Present"  # You can also set Ensure to "Absent"
                    Type = "Directory" # Default is "File".
                    DestinationPath = "C:\www\Dataverify\$poolName"
                }
            
                cNtfsPermissionEntry $permissionname #setup permissions on each directory
                {
                    Ensure = 'Present'
                    Path = "C:\www\Dataverify\$poolname"
                    Principal = $identity
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Modify'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'ReadAndExecute'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                    DependsOn = "[File]$poolname"
                }

                #comment out additional dataverify folder permissions for now
                <#
                cNtfsPermissionEntry moreDataverifypermissions #setup permissions on dataverify parent dir, no inheritance to subdirs
                {
                    Ensure = 'Present'
                    Path = "C:\www\Dataverify"
                    Principal = $identity
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Modify'
                            Inheritance = 'ThisFolderOnly'
                            NoPropagateInherit = $false
                        }
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'ReadAndExecute'
                            Inheritance = 'ThisFolderOnly'
                            NoPropagateInherit = $false
                        }
                    )
                    #depends on the dataverify file path creation from the above if statement
                    DependsOn = "[File]Dataverify"
                }
                #>
            }

        }

        #create each app pool with particular properties
        #we handle the identity assignment in another script 
        #Also there is a ClearAppPoolPeriodRestart script resource to handle those app pool properties.
        foreach($pool in $appPools) {
            $poolName = $pool.AppPool
            xWebAppPool "$poolName-Configure" {
                Name = $pool.AppPool
                Ensure = "Present"
                State = "Started"
                autoStart = $true
                queueLength = 4000
                maxProcesses = 2
                enable32BitAppOnWin64 = $true
                rapidFailProtection = $false
                restartSchedule = ""
            }

        #script to clear the periodic restart value since its not supported via xWebAdministration
        #Check out this link for an explanation of why we had to use $Using:variables in these script resources
        #Using variables normally, they would just end up blank
        #https://www.petri.com/extend-native-capabilities-dsc-script-resource
        $scriptname = "ClearAppPoolPeriodicRestart" + $poolname
        Script $scriptname {

              #get the periodic restart value. store the value in a hastable with the key "result"
              GetScript = {
                $periodicrestartvalue = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='$Using:poolname']/recycling/periodicRestart" -name "time"
                $periodicrestartvaluetotalminutes = $periodicrestartvalue.Value.TotalMinutes
                $int = [int]$periodicrestartvaluetotalminutes
                @{ "Result" = $int }
              }

              #use GetScript and check the "Result" key/value pair. If the value = 0, return true. Else return false which
              #will trigger the running of SetScript
              TestScript = {
                $state = $GetScript
                if( $state["Result"] -eq 0 ) 
                {
                    Write-Verbose -Message "The target resource is already in the desired state. No action is required."
                    return $true
                }
                Else
                {
                    Write-Verbose -Message "Periodic restart value does not = 0, running SetScript"
                    return $false
                }
              }

              #if TestScript returns $false, set the web configuration property "time" to a value of 0
              SetScript = {
                Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='$Using:poolname']/recycling/periodicRestart" -name "time" -value "00:00:00"
                Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='$Using:poolname']/recycling/periodicRestart/schedule" -name "." -AtElement @{value='00:00:00'}
                }
           }

        #end foreach
        }

        #delete each app pool in defaultapppools
        foreach($pool in $defaultAppPools) {
            xWebAppPool "$pool-Delete" {
                Name = $pool
                Ensure = "Absent"
            }
        }

        #endregion

        ########
        #region Site creation section
        ########

        #setup each site
        #specify the base site name, destination and app pool names you want (make sure the app pool is still setup with app pool section)
        $sitename = "application01"
        $sitedestination = "C:\www\" + $sitename
        $basesiteapppool = "pool01"
        #using an existing cert created during OSD
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My -DnsName "$env:computername.cbc.local" -eku "Server Authentication*"
        xWebsite $sitename
        {
            Ensure          = "Present"
            Name            = $sitename
            State           = "Started"
            PreloadEnabled  = $true
            PhysicalPath    = $sitedestination
            ApplicationPool = $basesiteapppool
            BindingInfo = 
                        @(
                            MSFT_xWebBindingInformation 
                            {
                                Protocol = "https"
                                Port = "443"
                                IPAddress = "*"
                                CertificateThumbprint = $cert.thumbprint
                                CertificateStoreName  = "My"
                            }
                            MSFT_xWebBindingInformation 
                            {
                                Protocol = "http"
                                Port = "4080"
                                IPAddress = "*"
                            }
                        )
        }

        foreach($webapp in $appPools){
            
            If( $webapp.appPool -ne "application01")
            {                                                                                
                #grab the correct name from the apppool array above & set a unique destination for each
                $webappname = $webapp.AppPool
                $webappdestination = "c:\www\application01\" + $webappname
                xWebApplication $webappname
                {
                    Website = $sitename
                    Ensure = "Present"
                    Name = $webappname
                    PhysicalPath = $webappdestination
                    WebAppPool = $webappname
                    AuthenticationInfo = MSFT_xWebApplicationAuthenticationInformation
                    {
                        Anonymous = $true
                        Basic     = $false
                        Digest    = $false
                        Windows   = $false
                    }
                    PreloadEnabled = $true
                    EnabledProtocols = @("http")

                    DependsOn = "[xWebsite]$sitename"
                }
            }
        }

        #C:\inetpub\wwwroot
        # Stop the default website before we remove it
        xWebsite DefaultWebSite 
        {
            State           = "Stopped"
            Ensure          = "Absent"
            Name            = "Default Web Site"
            PhysicalPath    = "C:\inetpub\wwwroot"
        }

        #endregion
        
        ########
        #region lbmonitor page deploy
        ########
        $lbmonitorsourcepath = "\\fileserver\sitepath\sitefiles"
        $lbmonitordestpath = "C:\www\application01"

        #copy from share path to local site dir. keep in mind we want to keep permissions in tact and not overwrite permissions.
        #may have to copy file by file
        Copy-Item -Path $lbmonitorsourcepath -Recurse -Force -Destination $lbmonitordestpath -ErrorAction Stop

        #endregion
        
        ########
        #region ISAPI Restrictions
        ########

        ########
        #made a decision here not to include asp.net 2.0 entries into ISAPI/CGI
        #i doubt the code still uses ASP 2.0
        #also i was not able to find c:\windows\system32\inetsrv\asp.dll so i excluded that as well
        ########

        ########
        #See the technet article on how Script resources are used to get an understanding of get, set and test scripts here
        ########

        #clear the current ISAPI configs so we can set new ones
        Clear-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/security/isapiCgiRestriction'

        Script IsapiRestriction1 {
              GetScript = {
                $frameworkPath = "$env:windir\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
                #$isapiConfiguration = Get-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed"
                @{ Result = Get-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed" }
              }

              SetScript = {
                $frameworkPath = "$env:windir\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
                Add-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/security/isapiCgiRestriction' -value @{
                  description = 'ASP.NET v4.0.30319'
                  path        = $frameworkPath
                  allowed     = 'True'
                }

                Set-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed" -value 'True' -PSPath:IIS:\
              }

              TestScript = {
                $frameworkPath = "$env:windir\Microsoft.NET\Framework64\v4.0.30319\aspnet_isapi.dll"
                $isapiConfiguration = Get-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed"
                ($isapiConfiguration.value -ne $null)
              }
            }

        Script IsapiRestriction2 {
              GetScript = {
                $frameworkPath = "$env:windir\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll"
                @{ Result = Get-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed" }
              }

              SetScript = {
                $frameworkPath = "$env:windir\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll"
                Add-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/security/isapiCgiRestriction' -value @{
                  description = 'ASP.NET v4.0.30319'
                  path        = $frameworkPath
                  allowed     = 'True'
                }

                Set-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed" -value 'True' -PSPath:IIS:\
              }

              TestScript = {
                $frameworkPath = "$env:windir\Microsoft.NET\Framework\v4.0.30319\aspnet_isapi.dll"
                $isapiConfiguration = Get-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$frameworkPath']/@allowed"
                ($isapiConfiguration.value -ne $null)
              }
            }

        #endregion
        
        ########
        #region HTTP Response Headers
        ########

        Script DeleteXPoweredByHttpResponseHeader {

            #get the http response web configuration property. store the value in a hashtable with key "Result"
            GetScript = {
            $state = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/application01'  -filter "system.webServer/httpProtocol/customHeaders/add[@name='X-Powered-By']" -name "."
            @{ "Result" = $state.name }
            }

            #use GetScript and check the "Result" key/value pair. If the value equals "" (an empty string), return true. Else return false which
            #will trigger the running of SetScript
            TestScript = {
                $state = $GetScript
                if( $state["Result"] -eq "" ) 
                {
                    Write-Verbose -Message "X-Powered-By header does not exist"
                    return $true
                }
                Write-Verbose -Message "X-Powered-By header exists, running SetScript"
                return $false
            }

            #if TestScript returns $false, remove the web configuration property that matches name "X-Powered-By"
            SetScript = {
            Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST/application01'  -filter "system.webServer/httpProtocol/customHeaders" -name "." -AtElement @{name='X-Powered-By'}
            }
        }

        #endregion
        
        ########
        #region Local Configuration Manager
        ########

        #all the settings we want for the Local Configuration Manager (LCM)
        #[DSCLocalConfigurationManager()]
        LocalConfigurationManager
        {
            ConfigurationModeFrequencyMins = 1440
            ConfigurationMode = "ApplyAndMonitor"
            RefreshMode = "Push"
            RebootNodeIfNeeded = $false
            AllowModuleOverwrite = $true
        }

        #endregion

        ########
        #region TASKS
        ########
        #Please see the wealth of examples on https://github.com/PowerShell/ComputerManagementDsc/wiki/ScheduledTask
        ########
        $taskname1 = "2-" + $DSCconfigName
        $taskname2 = "3-" + $DSCconfigName
        $scriptname1 = $taskname1 + ".ps1"
        $scriptname2 = $taskname2 + ".ps1"

        #remove all non-Microsoft existing tasks first
        Remove-Item "C:\Windows\System32\tasks\*" -exclude "Microsoft"

        ScheduledTask $taskname1
        {
            TaskName                = $taskname1
            ActionExecutable        = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments         = "-File `"C:\scripts\$scriptname1`""
            ScheduleType            = 'Daily'
            DaysInterval            = 1
            StartTime               = "00:00:00"
        }

        ScheduledTask $taskname2
        {
            TaskName                = $taskname2
            ActionExecutable        = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments         = "-File `"C:\scripts\$scriptname2`""
            ScheduleType            = 'Daily'
            DaysInterval            = 1
            StartTime               = "00:15:00"
        }

        #endregion

    #end node
    }

#end configuration
}

#call the configuration we specified above which will compile it down into a .mof
#use "&" to call the variable/name of the configuration. the alternative is just specifying the whole name not in a variable like...
#DSC-Web-Dev -OutputPath C:\dsc-mof\$DSCconfigName
&$DSCconfigName -OutputPath C:\dsc-mof\$DSCconfigName

########
#region pre-config-run stuffs 
#delete IIS stuffs
########

#remove all sites
remove-website -name *

#remove all app pools
Get-ChildItem -Path IIS:\AppPools\ | ForEach-Object { Remove-WebAppPool $_.Name }

#cleanup folders?

#endregion

#cleanup is finished so now lets trigger the config
#start the configuration using the same path we just specified where the .mof is
Start-DscConfiguration -ComputerName $env:computername -Path C:\dsc-mof\$DSCconfigName -Wait -ErrorAction Stop -Force -Verbose


