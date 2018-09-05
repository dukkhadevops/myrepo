#$Computers = @("PC1", "PC2")
#Invoke-Command -Computername $RemoteComputers -ScriptBlock { Get-ChildItem "C:\Program Files" }

$computers = Get-Content -Path "C:\SVN\WindowsAdmins\Scripts\RemoteCopyAndExecute\computers.txt"

Foreach ($target in $computers) {
    
    $dest = "\\" + $target + "\c$\scripts"

    If (Test-WSMan -ComputerName $target -ErrorAction Stop -Verbose){
            
        Try {
        Copy-Item -Path "C:\SVN\WindowsAdmins\Scripts\DV\DV-ProdDailyMaint\DV-ProdDailyMaint.ps1" -Destination $dest -ErrorAction Stop
        echo "file copies & connection okay on " $target

        #Invoke-Command -Computername $target -ScriptBlock { Start-Process -Filepath "c:\windows\temp\QualysCloudAgent-2.0.2.192.exe" -ArgumentList "CustomerId=`{9c0e25d4-95a3-5af6-e040-10ac13043f6a`} ActivationId=`{b9db34da-ed8b-419d-82b8-3dd359c2a0e6`}" -Wait -NoNewWindow } -ErrorAction Stop
        #echo "Qualys install okay on " $target      

        #Invoke-Command -Computername $target -ScriptBlock { Start-Process -Filepath "c:\windows\temp\WindowsSensor.exe" -ArgumentList "/install /quiet /norestart CID=9ACDE6B844F64534A9E82B5224635FA6-AE" -Wait -NoNewWindow } -ErrorAction Stop
        #echo "Crowdstrike install okay on " $target

        }

        Catch {
        
        #echo "invoke command installs failed"
        #echo "try running winrm /quickconfig on the destination and try again"

        }
        
    }

    Else {

        echo "connection to " $target " failed"
         
    }

}
