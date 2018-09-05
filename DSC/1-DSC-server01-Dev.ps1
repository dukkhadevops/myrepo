########
# Author:               Matt Keller
# Description:          Creates C:\scripts and copies DSC modules out to the server before DSC configs are executed
# Changes:              04/2/2018      Initial creation
#                       04/17/2018     change pre-work script to use unified config model
#                       06/14/2018     update for server
#                       06/15/2018     add IIS windows feature install (fix ISAPI first run problem)
#                       06/18/2018     add copy job for ComputerManagementDSC module so I can setup scheduled tasks
#                       06/28/2018     change over server. removed tls .reg file, dynatrace, & cert install regions for now
#
# Future Enhancements:  Add a way to read which modules you want to install from text file then install them
########
# $destPSModulepath should construct to = either c:\program Files\WindowsPowerShell\Modules or C:\Windows\system32\WindowsPowershell\v1.0\Modules

$computers = Get-Content -Path "C:\SVN\WindowsAdmins\DSC\DV\Dev\server01\computers.txt"

#for each computer target in our computers.txt file
Foreach ($target in $computers) {
    
    $destpath = "\\" + $target + "\c$\scripts"
    $localpath = "C:\scripts"

    #where we are copying our required powershell modules
    $destPSModulepath = "\\" + $target + "\c$\Program Files\WindowsPowerShell\Modules"

    #full path where we are pulling the DSC scripts from
    $localdscscriptpath1 = "C:\SVN\WindowsAdmins\DSC\DV\Dev\server01\2-DSC-server01-Dev.ps1"
    $localdscscriptpath2 = "C:\SVN\WindowsAdmins\DSC\DV\Dev\server01\3-DSC-server01-Dev.ps1"

    #full path to where we are copying the DSC scripts to
    $destfilepath1 = $destpath + "\2-DSC-server01-Dev.ps1"
    $destfilepath2 = $destpath + "\3-DSC-server01-Dev.ps1"
    $localfilepath1 = $localpath + "\2-DSC-server01-Dev.ps1"
    $localfilepath2 = $localpath + "\3-DSC-server01-Dev.ps1"

    If (Test-WSMan -ComputerName $target -ErrorAction Stop -Verbose)
    {
        <# Select the master branch and download the zip of the repository from something like: https://github.com/PowerShell/xTimeZone/tree/master
        Extract the zip file to a folder.
        Rename the folder if you need to xTimeZone for example
        Copy xTimeZone to C:\Program Files\WindowsPowerShell\Modules or C:\Windows\system32\WindowsPowershell\v1.0\Modules
        Verify you can discover the DSCResource:
            Get-DscResource
        #>

        #region check if c:\scripts exists on hosts, if not, create it.
        #invoke command on $target passing a scriptblock to execute makedir(md) with $p1 parameter($p1 is the path argument for md). -Argumentlist specifies $p1 parameter becomes $localpath
        Try {
             If(!(test-path $destpath)){
             Invoke-Command -Computername $target -ScriptBlock { param($p1) md $p1 } -ArgumentList $localpath -ErrorAction Stop
                }
                echo " "
                echo "c:\scripts exists or was created on $target"
             }

        Catch {
                echo "failed creating c:\scripts on $target"
                break
              }
        #endregion

        #region copy DSC script out to hosts
        #use -force to overwrite
        Try {
            Copy-Item -Path $localdscscriptpath1 -Destination $destfilepath1 -Force -ErrorAction Stop
            Copy-Item -Path $localdscscriptpath2 -Destination $destfilepath2 -ErrorAction Stop
            #Copy-Item -Path $localdscscriptpath3 -Destination $destfilepath3 -ErrorAction Stop
            echo "DSC script copies okay on $target"
            }

        Catch {
                echo "failed copying DSC scripts on $target"
                break
                }
        #endregion

        #region DSC modules & resources for use. Copy them to the Powershell Modules folder.
        Try {
            Copy-Item -Path "C:\SVN\WindowsAdmins\DSC\Modules\xWebAdministration" -Recurse -Force -Destination $destPSModulepath -ErrorAction Stop
            echo "xWebAdministration module copy okay on $target"

            Copy-Item -Path "C:\SVN\WindowsAdmins\DSC\Modules\cNtfsAccessControl" -Recurse -Force -Destination $destPSModulepath -ErrorAction Stop
            echo "cNtfsAccessControl module copy okay on $target"

            Copy-Item -Path "C:\SVN\WindowsAdmins\DSC\Modules\xSmbShare" -Recurse -Force -Destination $destPSModulepath -ErrorAction Stop
            echo "xSmbShare module copy okay on $target"

            Copy-Item -Path "C:\SVN\WindowsAdmins\DSC\Modules\ComputerManagementDsc" -Recurse -Force -Destination $destPSModulepath -ErrorAction Stop
            echo "ComputerManagementDSC module copy okay on $target"

            #more copies
            #more echoes
            }

        Catch {
                echo "copy of DSC modules to powershell directory failed on $target"
                break
                }
        #endregion

        #region install IIS feature remotely first
        #this was added to fix the ISAPI first run problem. 
        #I need to run Clear-WebConfiguration in the other script FIRST which is included in the WebAdministration module which is included in Server 2016 IIS feature

        Try
        {
            echo "starting IIS feature install. This takes a couple minutes the very first time. Should be faster on subsequent runs"
            Install-WindowsFeature -Name Web-Server,Web-Mgmt-Console -ComputerName $target -ErrorAction Stop
            echo " "
            echo "IIS feature install okay"
        }
        Catch
        {
            echo " "
            echo "IIS feature install failed"
            break
        }

        #endregion

        #region start #2 script
        Try 
        {
            echo "starting #2 DSC script run. This compiles the script into a .mof and runs the entire script. Its slow on first run but should be faster on subsequent runs"
            echo "use your .cbc account credential here"
            $credential = Get-Credential
            $session = New-PSSession $target -Name $target -Authentication Credssp -Credential $credential
            Invoke-Command –Session $session –scriptblock { param($p6) . $p6} -ArgumentList $localfilepath1 -ErrorAction Stop
            echo " "
            echo "#2 DSC script finished running."
        }
        Catch
        {
            echo " "
            echo "#2 DSC script failed. try running it locally first"
            break
        }
        #endregion

        #region start #3 script

        Try
        {
            echo "starting #3 script run. This script is just assigning app pool identities for the most part so it should be fast."
            #we're just gonna use that same $session to run another script now
            Invoke-Command -Session $session -scriptblock { param($p7) . $p7 } -ArgumentList $localfilepath2 -ErrorAction Stop
            echo "#3 script finished running."
        }
        Catch
        {
            echo " "
            echo "#3 script failed. try running it locally first"
            break
        }


        #endregion

        #bunch of echoes to break things up
        echo " "
        echo "##### Done with $target #####"
        echo " "
        
    #endif
    }

    Else {
        echo "connection to $target failed. Try running winrm /quickconfig on the destination host and try again"
    }
}
