# Specify the path to the text file
$valuesFile = "C:\Users\Matt\Documents\values.txt"



# Read the content of the text file
$content = Get-Content -Path $valuesFile -Raw

# Convert the content to a hashtable and store it in credentials variable
$values = $content | ConvertFrom-StringData

# Extract the values we want from the hashtable
$scheduledTask_StartTime = $values["scheduledtask_startime"]
$script1 = $values["script1"]
$script2 = $values["script2"]
$script3 = $values["script3"]

# Create a new task action that runs the specified command
$action1 = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script1`""
$action2 = New-ScheduledTaskAction -Execute "python.exe" -Argument "$script2"
$action3 = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script3`""

# Create a trigger that will activate the task daily scheduled time
$trigger1 = New-ScheduledTaskTrigger -Daily -At $scheduledTask_StartTime
$trigger2 = New-ScheduledTaskTrigger -Daily -At "09:05"
$trigger3 = New-ScheduledTaskTrigger -Daily -At "09:10"

# Create a task principal (security context under which the task runs, here using the current user)
#$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken

# Create the scheduled task using the provided action, trigger, and principal
#Register-ScheduledTask -TaskName "AutomatedReportDownloader" -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask -TaskName "AutomatedReportDownloader-KDP" -Action $action1 -Trigger $trigger1 -Force
Register-ScheduledTask -TaskName "AutomatedReportDownloader-BN" -Action $action2 -Trigger $trigger2 -Force
Register-ScheduledTask -TaskName "AutomatedReportDownloader-Email" -Action $action3 -Trigger $trigger3 -Force

# Optional: If you want to allow the task to run even when the computer is on battery power
#Set-ScheduledTask -TaskName "MyDailyTask" -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries $true)