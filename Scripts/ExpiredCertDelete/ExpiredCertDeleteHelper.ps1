enable-psremoting -force
#cd C:\SVN\WindowsAdmins\Scripts\ExpiredCertDelete

$computers = Get-Content -Path "C:\SVN\WindowsAdmins\Scripts\ExpiredCertDelete\computers.txt"
$scriptpath = "C:\SVN\WindowsAdmins\Scripts\ExpiredCertDelete\MattsExpiredCertDelete.ps1"

#region LogWrite function
        $logfile = "C:\SVN\WindowsAdmins\Scripts\ExpiredCertDelete\log.txt"
        Function LogWrite{
            Param ([string]$logstring)
            $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
            $Line = "$Stamp -- $target -- $logstring"
            Add-Content $logfile -Value $Line
        }
        #endregion

Foreach ($target in $computers) {

    If (Test-WSMan -ComputerName $target -ErrorAction Stop -Verbose){

        $message = "connection to $target success"
        echo " "
        echo $message
        LogWrite $message

        Try {
            $message = "trying cert delete"
            echo $message
            LogWrite $message
            invoke-command -ComputerName $target -FilePath $scriptpath -ErrorAction Stop 
            $message = "success!"
            echo $message
            LogWrite $message
        }

        Catch {
            $message = "failed to delete expired certs"
            echo $message
            LogWrite $message
            break
        }
    }
    Else {
        $message = "connection to $target failed. Try running winrm /quickconfig on the destination host and try again"
        echo $message
        LogWrite $message
    }
    $message = "done with $target"
    echo $message
    LogWrite $message
}