# Specify the path to the text file
$valuesFile = "C:\Users\Matt\Documents\values.txt"
######################
#region Read in values
######################
# Read the content of the text file
$content = Get-Content -Path $valuesFile -Raw

# Convert the content to a hashtable and store it in credentials variable
$values = $content | ConvertFrom-StringData

# Extract the values we want from the hashtable
$smtpUsername = $values["smtp_username"]
$smtpPassword = $values["smtp_password"]
$emailRecipient1 = $values["email_recipient1"]
$emailRecipient2 = $values["email_recipient2"]
$ccEmail = $values["cc_on_email"]
$workingFolderPath = $values["workingfolderpath"]
$pathToReports = $values["path_to_reports"]
$browserDownloadPath = $values["browserdownloadpath"]

# Display the values for verification
# Write-Host "SMTP Username: $smtpUsername"
# Write-Host "SMTP Password: $smtpPassword"
# Write-Host "Amazon Username: $amazonUsername"
# Write-Host "Amazon Password: $amazonPassword"
######################
#endregion
######################

######################
#region email file
######################
# Define the file path and email details
$smtpServer = "smtp.mail.yahoo.com"

# Define files you are looking for
#$kdpSearchPattern = "KDP-"
#$bnSearchPattern = "BN-"

# Grab Amazon file
$files1 = Get-ChildItem -Path $pathToReports | Where-Object { $_.Extension -eq ".xlsx" }
if ($files1.Count -gt 0){
    $latestFile1 = $files1 | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
    $latestFile1FullPath = $pathToReports + $latestFile1.Name
} else {
    Write-Host "did not find xlsx file"
}

#BN File
$files2 = Get-ChildItem -Path $pathToReports | Where-Object { $_.Extension -eq ".csv" }
if ($files2.Count -gt 0){
    $latestFile2 = $files2 | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
    $latestFile2FullPath = $pathToReports + $latestFile2.Name
} else {
    Write-Host "did not find xlsx file"
}

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

#Email structure
$msg.From = $smtpUsername
$msg.To.Add($emailRecipient1)
$msg.To.Add($emailRecipient2)
#add myself
$msg.To.Add($ccEmail)
$msg.subject = "Report - KDP & BN"
$msg.body = "Yay automation"

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.EnableSsl = 1
$smtp.Port = 587
$cred = New-Object Net.NetworkCredential($smtpUsername,$smtpPassword)
$smtp.Credentials = $cred

# Attach the files to the email
$attachment1 = New-Object System.Net.Mail.Attachment($latestFile1FullPath)
$attachment2 = New-Object System.Net.Mail.Attachment($latestFile2FullPath)
$msg.Attachments.Add($attachment1)
$msg.Attachments.Add($attachment2)

#Send
try{
    $smtp.Send($msg)
    Write-Host "email sent successfully"
}
catch {
    Write-Host "Failed to send email. Error: $($_.Exception.Message)"
}
# Dispose the attachment and email objects
$attachment.Dispose()
$msg.Dispose()

####################
#endregion
####################