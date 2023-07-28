# Specify the path to the text file
$valuesFile = "C:\Users\Matt\Documents\values.txt"



# Read the content of the text file
$content = Get-Content -Path $valuesFile -Raw

# Convert the content to a hashtable and store it in credentials variable
$values = $content | ConvertFrom-StringData

# Extract the values we want from the hashtable
$scheduledTask_StartTime = $values["scheduledtask_startime"]
$scriptAndPathToRun = $values["script_and_path_to_run"]

# Create a new task action that runs the specified command
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptAndPathToRun`""

# Create a trigger that will activate the task daily scheduled time
$trigger = New-ScheduledTaskTrigger -Daily -At $scheduledTask_StartTime

# Create a task principal (security context under which the task runs, here using the current user)
#$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken

# Create the scheduled task using the provided action, trigger, and principal
#Register-ScheduledTask -TaskName "AutomatedReportDownloader" -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask -TaskName "AutomatedReportDownloader" -Action $action -Trigger $trigger -Force

# Optional: If you want to allow the task to run even when the computer is on battery power
#Set-ScheduledTask -TaskName "MyDailyTask" -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries $true)