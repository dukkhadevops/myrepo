#assign variable where our computer list comes from
$computers = Get-Content -Path "C:\SVN\WindowsAdmins\Scripts\TALXCertInstall\computers.txt"
#assign variable for search term for friendlyname and subject
$searchterm = "searchterm"

Foreach ($target in $computers) {

    #region remove cert from cert snap in LocalMachine\My

    #if the connection to the target works, proceed
    If (Test-WSMan -ComputerName $target -ErrorAction Stop -Verbose){
        echo "test connection to $target SUCCESS"

        
        #invoke-command with the scriptblock to find the TALX cert and remove it
        Invoke-Command -Computername $target -ScriptBlock { 
            #Create object array of the correct certificate store
            $obj = New-Object System.Security.Cryptography.x509Certificates.x509Store("My","LocalMachine")
            #find the correct cert we want based on the name
            $mycert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { ($_.FriendlyName -like "*$searchterm*" -or $_.Subject -like "*$searchterm*") }

            #open the certificate store array for read/write. Remove our Cert object. Close the cert store.
            $obj.Open("ReadWrite")
            $obj.Remove($mycert)
            $obj.Close() 
        }
        echo "Remove cert command ran on target $target."

    #endif
    }
    Else { echo "test connection to $target failed" }
    #endregion

    #region remove cert from local c:\app\certs

        #check if cert is there
        If (Test-Path -Path "\\$target\c`$\app\certs\talxtestcert.cer"){

            #rename old cert
            Rename-Item -Path "\\$target\c`$\app\certs\talxtestcert.cer" -NewName "talxtestcert.old"
        }
    #endregion
    
#endforeach
}