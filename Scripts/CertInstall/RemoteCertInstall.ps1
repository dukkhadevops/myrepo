#region cert variables
#assign variables for each cert
$cert1 = "\\fileserver\path\talxtestcert.pfx"
$cert2 = "\\fileserver\path\talxtestcert.cer"
$cert3 = "\\fileserver\path\Test DigiCert SHA2 Assured ID CA.cer"
$cert4 = "\\fileserver\path\Test DigiCert Assured ID Root CA.cer"

#this returns the rightmost element from the path above (the cert name essentially)
$cert1name = Split-Path -Path $cert1 -Leaf
$cert2name = Split-Path -Path $cert2 -Leaf
$cert3name = Split-Path -Path $cert3 -Leaf
$cert4name = Split-Path -Path $cert4 -Leaf

#For the region where we set the Permissions on the private key - you need to update these variables
#This is the thumbprint for the cert we're looking for and the service account we need to set permissions on
#these will change based on the environment(service account) and whether it uses the test cert or prod cert
$testthumbvar = "‎64d2e505a3384382aa41b185607f3e50886712e5"
$testaccountvar1 = "serviceaccount1"
$testaccountvar2 = "serviceaccount2"
$testaccountvar3 = "serviceaccount3"
$testaccountvar4 = "serviceaccount4"
$prodthumbvar = "‎40d8345312536c416e1ce39a1622b5f27660ab39"
$prodaccountvar1 = ""

#endregion

#assign variable where our computer list comes from
$computers = Get-Content -Path "C:\SVN\WindowsAdmins\Scripts\TALXCertInstall\DEV.txt"

#region LogWrite function
$logfile = "C:\SVN\WindowsAdmins\Scripts\TALXCertInstall\log.txt"
Function LogWrite{
    Param ([string]$logstring)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp -- $target -- $logstring"
    Add-Content $logfile -Value $Line
}
#endregion

#region 2008r2 compatibility - need quick and dirty import-pfxcertificate function
#Invoke-Command -ComputerName $target -ScriptBlock ${Function:Import-PfxCertificate1} -ArgumentList ("c:\temp\certs\DATAVER5.pfx","LocalMachine","My", "Summer09")
Function Import-PfxCertificate1 {
param([String]$certPath,[String]$certRootStore = “CurrentUser”,[String]$certStore = “My”,$pfxPass = $null)
$pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 
if ($pfxPass -eq $null) {$pfxPass = read-host “Enter the pfx password” -assecurestring}
$pfx.import($certPath,$pfxPass,“Exportable,PersistKeySet”)
$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
$store.open(“MaxAllowed”)
$store.add($pfx)
$store.close()
}
#endregion

#region funtion to set certificate permissions
Function Set-CertificatePermission
{
 param
 (
    [Parameter(Position=1, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$pfxThumbPrint,

    [Parameter(Position=2, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$serviceAccount
 )

 $cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object -FilterScript { $PSItem.ThumbPrint -eq $pfxThumbPrint; };

 # Specify the user, the permissions and the permission type
 $permission = "$($serviceAccount)","Read,FullControl","Allow"
 $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission;

 # Location of the machine related keys
 $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
 $keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
 $keyFullPath = $keyPath + $keyName;

 try
 {
    # Get the current acl of the private key
    $acl = (Get-Item $keyFullPath).GetAccessControl('Access')

    # Add the new ace to the acl of the private key
    $acl.AddAccessRule($accessRule);

    # Write back the new acl
    Set-Acl -Path $keyFullPath -AclObject $acl;
 }
 catch
 {
    throw $_;
 }
}
#endregion


Foreach ($target in $computers) {
        #more variables
        $destpath = "\\" + $target + "\c$\temp\certs\"
        $localpath = "c:\temp\certs\"
        $appcertsdestpath = "\\" + $target + "\c$\app\certs\"

        #test connection. if connection works, then proceed, erroraction = stop
        If (Test-WSMan -ComputerName $target -ErrorAction Stop -Verbose){
        echo "test connection to $target SUCCESS"
        echo " "
        LogWrite "Test connection to $target SUCCESS"

        #region setup each targets local c:\temp\certs
        Try {
                If(!(test-path $destpath))
                {
                    #invoke command on $target passing a scriptblock to execute makedir(md) with $p1 parameter($p1 is the path argument for md). -Argumentlist specifies $p1 parameter becomes $localpath
                    Invoke-Command -Computername $target -ScriptBlock { param($p1) md $p1 } -ArgumentList $localpath -ErrorAction Stop
                }
                echo " "
                echo "$destpath exists or was created on $target"
            }

        Catch {
                echo "failed creating $destpath on $target"
                break
              }
        #endregion

        #region copy each cert to c:\temp\certs

        #Do until tries = 3, try the copies and if success then success=true. catch and write to log and also sleep for 5s before continue
        #catch with erroraction = silentylycontinue so the retry loop continues
        $tries = 0
        $success = $null
        Do {
            Try {
                    #copy everything to c:\temp\certs
                    Copy-Item -Path $cert1 -Destination $destpath  -Force -ErrorAction Stop
                    Copy-Item -Path $cert2 -Destination $destpath  -Force -ErrorAction Stop
                    Copy-Item -Path $cert3 -Destination $destpath  -Force -ErrorAction Stop
                    Copy-Item -Path $cert4 -Destination $destpath  -Force -ErrorAction Stop

                    #success
                    $success = $true

                    echo " "
                    echo "cert copies okay on $target"
                    LogWrite "cert copies okay"
                 }

            Catch {
                    echo "failed copying certs on $target. number of tries = $tries"
                    LogWrite "cert copies failed. trycounter = $tries" 
                    Start-Sleep -s 5
                    $erroractionpreference="SilentlyContinue"

                    #break
                   }

            #increment tries
            $tries++

        #end do
        }

        Until ($tries -eq 3 -or $success)
        if (-not($success)){exit}
        
        #endregion

        #region rename c:\app\certs\talxtestcert.cer to .old & copy new talxtestcert.cer to c:\app\certs
        $check1 = $appcertsdestpath + "talxtestcert.cer"
        $check2 = $appcertsdestpath + "talxtestcert.cer.old"

        #if api server then skip this part
        If ($target -notlike "*api*"){
            Try {
                    #if talxtestcert.cer exists...
                    If (Test-Path $check1) {
                
                        #if talxtestcert.cer.old exists, delete it
                                If (Test-Path $check2) {
                        Remove-Item $check2
                        }

                        #rename talxtestcert.cer to talxtestcert.cer.old
                        Rename-Item -path $check1 -NewName "talxtestcert.cer.old" -Force
                        #copy non-private-key cert to c:\app\certs
                        Copy-Item -path $cert2 -Destination $appcertsdestpath -Force -ErrorAction Stop
                    }

                    #else if talxtestcert.cer doesnt exist, just copy it
                    Else {
                    Copy-Item -path $cert2 -Destination $appcertsdestpath -Force -ErrorAction Stop
                    }

                    echo " "
                    echo "############################################################################################################################################"
                    echo "c:\app\certs\ renaming success on $target"
                    echo "############################################################################################################################################"
                    echo " "
                    LogWrite "successfully renamed certs in c:\app\certs\"
            }
            Catch {

                    echo "failed to rename certs in c:\app\certs on $target"
                    LogWrite "failed to rename certs in c:\app\certs"
                    break
                   }
        Else {
            echo " "
            echo "$target has name like API so skip copying to c:\app\certs"
            echo " "
            LogWrite "$target has name like API so skip copying to c:\app\certs"
        }
        #endif
        }
        #endregion

        #region for solo cert with password - invoke cert import command with password
    
        $PlainTextPass = "password"
        $cred = $PlainTextPass | ConvertTo-SecureString -AsPlainText -Force
        $localcert1 = $localpath + $cert1name

        Try {
                ###########
                #If the server is 2012 or later, Import-PfxCertificate should work. 
                #since it doesnt work on 08r2, we have to run an invoke-command calling our import-pfxcertificate1 function above
                ###########
                #invoke command on $target passing a scriptblock to execute import-pfxcertificate with $p1 & $p2 params. -Argumentlist specifies the ordered params so $p1 becomes $localscert1 & $p2 becomes $cred
                #Invoke-Command -Computername $target -ScriptBlock { param($p1,$p2) Import-PfxCertificate -FilePath $p1 -CertStoreLocation Cert:\LocalMachine\My -Password $p2 } -ArgumentList ($localcert1,$cred) -ErrorAction Stop

                #since these are mostly on 08r2 servers, we use our little pfxcertificate1 function instead
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Import-PfxCertificate1} -ArgumentList ($localcert1, "LocalMachine", "My", $PlainTextPass)
           
                echo " "
                echo "############################################################################################################################################"
                echo "solo cert import okay on $target"
                echo "############################################################################################################################################"
                LogWrite "solo cert import okay"
             }

        Catch {
                echo "failed solo cert import on $target"
                LogWrite "failed solo cert import"
                break
               }
        #endregion 

        #region for rest of certs with no password - invoke import command
        Try {
                #trusted root
                $localcert4 = $localpath + $cert4name
                #Invoke-Command -Computername $target -ScriptBlock { param($p1) Import-Certificate -FilePath $p1 -CertStoreLocation Cert:\LocalMachine\Root } -ArgumentList $localcert5 -ErrorAction Stop
                #Invoke-Command -Computername $target -ScriptBlock { param($p1) Import-Certificate -FilePath $p1 -CertStoreLocation Cert:\LocalMachine\Root } -ArgumentList $localcert7 -ErrorAction Stop
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Import-PfxCertificate1} -ArgumentList ($localcert4, "LocalMachine", "Root", $PlainTextPass)
                echo " "
                echo "############################################################################################################################################"
                echo "ROOT cert imports okay on $target"
                echo "############################################################################################################################################"
                echo " "
                LogWrite "ROOT cert imports okay"

                #intermediate
                $localcert3 = $localpath + $cert3name
                #Invoke-Command -Computername $target -ScriptBlock { param($p1) Import-Certificate -FilePath $p1 -CertStoreLocation Cert:\LocalMachine\CA } -ArgumentList $localcert3 -ErrorAction Stop
                #Invoke-Command -Computername $target -ScriptBlock { param($p1) Import-Certificate -FilePath $p1 -CertStoreLocation Cert:\LocalMachine\CA } -ArgumentList $localcert4 -ErrorAction Stop
                #Invoke-Command -Computername $target -ScriptBlock { param($p1) Import-Certificate -FilePath $p1 -CertStoreLocation Cert:\LocalMachine\CA } -ArgumentList $localcert6 -ErrorAction Stop
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Import-PfxCertificate1} -ArgumentList ($localcert3, "LocalMachine", "CA", $PlainTextPass)
                echo "############################################################################################################################################"
                echo "INTERMEDIATE cert imports okay on $target"
                echo "############################################################################################################################################"
                LogWrite "INTERMEDIATE cert imports okay"
            }

        Catch {
                echo "failed cert imports on $target"
                LogWrite "ROOT or INTERMEDIATE cert imports failed"
                break
                }

        #endregion

        #region for setting private key permissions on TALX cert
        Try {
                #Set-CertificatePermission $testthumbvar $accountvar1, 2, & 3
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Set-CertificatePermission} -ArgumentList ($testthumbvar, $testaccountvar1)
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Set-CertificatePermission} -ArgumentList ($testthumbvar, $testaccountvar2)
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Set-CertificatePermission} -ArgumentList ($testthumbvar, $testaccountvar3)
                Invoke-Command -ComputerName $target -ScriptBlock ${Function:Set-CertificatePermission} -ArgumentList ($testthumbvar, $testaccountvar4)
                echo " "
                echo "############################################################################################################################################"
                echo "Certificate Private Key Permissions set on $target"
                echo "############################################################################################################################################"
                echo " "
                LogWrite "Certificate Private Key Permissions set on $target"
            }

        Catch {
                echo "failed to set Certificate Private Key Permissions on $target"
                LogWrite "setting Certificate Private Key Permissions failed"
                break
                }
        #endregion

        #region cleanup c:\temp\certs
        Try {
            
                Invoke-Command -Computername $target -ScriptBlock { param($p1) remove-item -Path $p1 -recurse -Force } -ArgumentList $localpath -ErrorAction Stop
                echo " "
                echo "############################################################################################################################################"
                echo "$localpath deleted on $target"
                echo "############################################################################################################################################"
                echo " "
                LogWrite "c:\temp\certs cleanup success"
            }

        Catch {
                echo "failed to delete $localpath on $target"
                LogWrite "failed to delete c:\temp\certs"
                break
                }
        #endregion

        #sleep for 15 seconds before starting on the next target
        Start-Sleep -s 15

        #iisreset if you want it
        #invoke-command -computername $target {cd C:\Windows\System32\; ./cmd.exe /c "iisreset" }

        #end if for test connection
        }

        Else { 
        echo "connection to $target failed. Try running winrm /quickconfig on the destination host and try again"
        LogWrite "connection to $target failed. Try running winrm /quickconfig on the destination host and try again" 
        }
        

#end for each target in computers
}