####HOW TO USE THIS####

#$dynatracefileshare = "\\fileserver\Dynatrace 7\dynatrace-agent-7.0.0.2469-x86.msi"
#$target = "server"

#InstallDynatrace $target $dynatracefileshare

####END HOW TO
#idea - OPTIONAL PARAMS make the function take in a NAME & SERVER:PORT so you can dynamically create the ini files on the fly if you want otherwise look at the destination in source control

function InstallDynatrace{ 
    param($computername, $dynatracefileshare)

    #test if can connect to machine
    If (Test-WSMan -ComputerName $computername -Verbose)
    {
        $destpath = "\\" + $computername + "\C$\scripts"
        $localpath = "C:\scripts"
        $dynatracefile = Split-Path $dynatracefileshare -Leaf
        $dynatracedest = $localpath + "\" + $dynatracefile
        $dynatraceinstallparams = "/i $dynatracedest ADDLOCAL=DiagnosticsAgent,IIS7Agent,IISAgents,DotNetAgent,WebServerAgent,DotNetAgent20x64,IIS7Agentx64 /qn"
        #dynatrace ini install
        $dynatraceinifile = "C:\SVN\WindowsAdmins\Scripts\DV\InstallDynatrace\inifiles\$computername"
        $dynatraceinidest = "\\" + $computername + "\C$\Program Files (x86)\Dynatrace\Dynatrace Agent 7.0\agent\conf"

        #dynatrace service name (in case it changes in the future)
        $servicename = "Dynatrace Web Server Agent 7.0"

        #region check if c:\scripts exists on host, if not, create it.
        #invoke command on $target passing a scriptblock to execute makedir(md) with $p1 parameter($p1 is the path argument for md). -Argumentlist specifies $p1 parameter becomes $localpath

        If(!(test-path $destpath))
        {
            Invoke-Command -Computername $computername -ScriptBlock { param($p1) md $p1 } -ArgumentList $localpath -ErrorAction Stop
        }
             
        #endregion

        #region copy file locally from $dynatracefileshare and install with params we want
        #copy file from $dynatracefileshare to destpath we know exists
        Copy-Item -Path $dynatracefileshare -Destination $destpath -ErrorAction Stop

        #invoke command start-process msiexec with our $dynatraceinstallparams
        Invoke-Command -Computername $computername -ScriptBlock { param($p1) Start-Process -Filepath msiexec $p1 -Wait } -ArgumentList "$dynatraceinstallparams" -ErrorAction Stop
        #endregion

        #region .ini copy and rename tasks
        Copy-Item -Path $dynatraceinifile -Destination $dynatraceinidest -ErrorAction Stop

        $check1 = "$dynatraceinidest" + "\dtwsagent.ini"
        $check2 = "$dynatraceinidest" + "\dtwsagent.ini.default"
        $check3 = "$dynatraceinidest" + "\$computername"

        #if ini file exists...
        If (Test-Path $check1) {
                
            #if ini.default exists, delete it
            If (Test-Path $check2) {
                Remove-Item $check2
            }

            #if ini file exists, rename to .ini.default
            Rename-Item -path $check1 -NewName "dtwsagent.ini.default" -Force
            #rename .ini.matt to .ini
            Rename-Item -path $check3 -NewName "dtwsagent.ini" -Force
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

        #region configure native modules

        #endregion
    }
    Else{echo "cannot connect to $computername"}

}