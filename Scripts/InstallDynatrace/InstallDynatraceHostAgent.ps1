$computers = Get-Content -Path "C:\SVN\WindowsAdmins\Scripts\DV\InstallDynatrace\computers.txt"

#ini directory
$inidirectory = "C:\Program Files (x86)\Dynatrace\Dynatrace Agent 7.0\agent\conf\dthostagent.ini"

Foreach ($target in $computers) {
    
    $destpath = "\\" + $target + "\C$\scripts"
    $localpath = "C:\scripts"

    #dynatrace install

    #.msi path
    $dynatracefileshare = "\\fileserver\Dynatrace 7\dynatrace-agent-7.0.0.2469-x86.msi"

    $dynatracefile = Split-Path $dynatracefileshare -Leaf
    $dynatracedest = $localpath + "\" + $dynatracefile
    $localparam = "/i $dynatracedest ADDLOCAL=HostAgent /qn"

    #dynatrace ini install
    $dynatraceinifile = "C:\SVN\WindowsAdmins\Scripts\DV\InstallDynatrace\dthostagent_inifiles\$target"
    $dynatraceinidest = "\\" + $target + "\C$\Program Files (x86)\Dynatrace\Dynatrace Agent 7.0\agent\conf"

    #dynatrace service name (in case it changes in the future)
    $servicename = "Dynatrace Host Agent 7.0"

    If (Test-WSMan -ComputerName $target -ErrorAction Stop -Verbose)
    {

        #region actually install dynatrace
        Try 
        {
            #copy jobs and echoes first
            echo "starting dynatrace copy to $target"
            Copy-Item -Path $dynatracefileshare -Destination $destpath -ErrorAction Stop
            echo "dynatrace copy okay on $target"

            #trigger install with echoes before and after
            echo "starting dynatrace install on $target, this takes a couple minutes on the very first install attempt. its quicker on subsequent runs"
            Invoke-Command -Computername $target -ScriptBlock { param($p5) Start-Process -Filepath msiexec $p5 -Wait } -ArgumentList "$localparam" -ErrorAction Stop
            echo "dynatrace install okay on $target"

            #register dynatrace service
            #echo "starting to try and register the service on $target"
            #Invoke-Command -ComputerName $target -ScriptBlock { & 'C:\Program Files (x86)\Dynatrace\Dynatrace Agent 7.0\agent\lib64\dthostagent.exe' -service install }
            #echo "done registering the service"

        }
        Catch
        {
            echo "dynatrace install failed on $target"
            break
        }
        #endregion

        #region .ini copy and rename tasks
        echo "starting .ini overwrite to $target"
        Copy-Item -Path $dynatraceinifile -Destination $dynatraceinidest -ErrorAction Stop
        echo "ini copy okay on $target"

        $check1 = "$dynatraceinidest" + "\dthostagent.ini"
        $check2 = "$dynatraceinidest" + "\dthostagent.ini.default"
        $check3 = "$dynatraceinidest" + "\$target"

        echo "starting ini renames on $target"
        #if ini file exists...
        If (Test-Path $check1) {
                
            #if ini.default exists, delete it
            If (Test-Path $check2) {
                Remove-Item $check2
            }

            #if ini file exists, rename to .ini.default
            Rename-Item -path $check1 -NewName "dthostagent.ini.default" -Force
            #rename .ini.matt to .ini
            Rename-Item -path $check3 -NewName "dthostagent.ini" -Force
            
            echo "ini renames success on $target"
        }
        
        #else if ini file doesnt exist, check installer
        Else {
            echo "$check1 doesnt exist somehow. check the install or re-run the install piece of this script"
        }

        #endregion

        #region now that the .ini is in place, start dynatrace service
        echo "trying to start Dynatrace service on $target"
        (Get-Service -ComputerName $target -Name $servicename).Start()
        Get-Service -ComputerName $target -Name $servicename
        #endregion

    #endif
    }

#endforeach
}