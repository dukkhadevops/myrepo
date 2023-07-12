#TODO - run browser in background
#TODO - readme on where & how to install geckodriver
#TODO - readme on making sure powershell & modules are up to date
#TODO - where will we actually run this thing + scheduled task setup?
#TODO - actually read the report - what needs changed?
#TODO - do we want to automate cleaning up old files
#TODO - put things in functions - log function maybe
#TODO - parameterize smtp server & port

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
$amazonUsername = $values["amazon_username"]
$amazonPassword = $values["amazon_password"]
$smtpUsername = $values["smtp_username"]
$smtpPassword = $values["smtp_password"]
$emailRecipient = $values["email_recipient"]
$ccEmail = $values["cc_on_email"]
$workingFolderPath = $values["workingfolderpath"]
$browserDownloadPath = $values["browserdownloadpath"]
$geckoFolderPath = $values["geckofolderpath"]

# Display the values for verification
# Write-Host "SMTP Username: $smtpUsername"
# Write-Host "SMTP Password: $smtpPassword"
# Write-Host "Amazon Username: $amazonUsername"
# Write-Host "Amazon Password: $amazonPassword"
######################
#endregion
######################

######################
#region WebScrape
####################
# Import the Selenium module
Import-Module Selenium

# Specify the path to the Selenium WebDriver executable (geckodriver for Firefox in this example)
#$driverPath = "C:\Users\Matt\Downloads\geckodriver\geckodriver.exe"
#$driverPath = "C:\Users\Matt\Downloads\geckodriver\"

# Specify the URL of the Amazon login page
$amazonLoginUrl = "https://kdpreports.amazon.com/dashboard"

# Create a new Firefox browser instance
$driver = New-Object OpenQA.Selenium.Firefox.FirefoxDriver($geckoFolderPath)

# Maximize the browser window (optional)
$driver.Manage().Window.Maximize()

# Navigate to the Amazon login page
$driver.Navigate().GoToUrl($amazonLoginUrl)
# Wait for the login process to complete
Start-Sleep -Seconds 1

# Find the email or phone number input field and enter the username
$usernameInput = $driver.FindElementById("ap_email")
$usernameInput.SendKeys($amazonUsername)
# Wait for the login process to complete
Start-Sleep -Seconds 1

# Find the password input field and enter the password
$passwordInput = $driver.FindElementById("ap_password")
$passwordInput.SendKeys($amazonPassword)
# Wait for the login process to complete
Start-Sleep -Seconds 1

# Find the sign-in button and click it
$signInButton = $driver.FindElementById("signInSubmit")
$signInButton.Click()
# Wait for the login process to complete
Start-Sleep -Seconds 3

#Find the yesterday button within the overview-header and click it
$yesterdayButton = $driver.FindElementByXPath("//button[@mdn-tab-value='YESTERDAY']")
$yesterdayButton.Click()
Start-Sleep -Seconds 3

# Find the download button which is apart of reports-content element and click it
$downloadButton = $driver.FindElementByXPath("//div[@id='reports-content']//div[contains(@class, 'overview-download-button')]/div[contains(@class, 'download-button-wrapper')]/div/button[contains(@class, 'download-button')]")
$downloadButton.Click()
Start-Sleep -Seconds 5

#Close out
$driver.Quit()

####################
#endregion Webscrape
######################

######################
#region rename & move file
######################
$searchPattern = "KDP_*.xlsx"  # Specify the search pattern to match the desired files

# Get the list of XLSX files that match the search pattern in the specified folder
$files = Get-ChildItem -Path $browserDownloadPath -Filter $searchPattern | Where-Object { $_.Extension -eq ".xlsx" }

if ($files.Count -gt 0) {
    # Sort the files by creation time in descending order to get the latest file
    $latestFile = $files | Sort-Object -Property CreationTime -Descending | Select-Object -First 1

    # Move the file from browser download dir to working dir
    $latestFileFullPath = $browserDownloadPath + $latestFile.Name
    Move-Item -Path $latestFileFullPath -Destination $workingFolderPath -Force

    # Grab the file from the new location
    $files2 = Get-ChildItem -Path $workingFolderPath -Filter $searchPattern | Where-Object { $_.Extension -eq ".xlsx" }
    if ($files2.Count -gt 0){
        # Sort again
        $latestFile2 = $files2 | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
        # Generate the new name based on the desired format
        $newName = "KDP-" + (Get-Date).ToString("M-d-yyyy-hhmmss") + ".xlsx"

        # Rename the file
        #$newPath = [System.IO.Path]::Combine($workingFolderPath, $newName)
        Rename-Item -Path $latestFile2.FullName -NewName $newName
    }
    else {
        Write-Host "did not find file after moving it"
    }
}
else {
    Write-Host "didn't find an xlsx file that starts with KDP_"
}


######################
#endregion
######################

######################
#region email file
######################
# Define the file path and email details
$smtpServer = "smtp.mail.yahoo.com"
$searchPattern = "KDP-*.xlsx"  # Specify the search pattern to match the desired files

# Grab the file from the new location
$files2 = Get-ChildItem -Path $workingFolderPath -Filter $searchPattern | Where-Object { $_.Extension -eq ".xlsx" }
if ($files2.Count -gt 0){
    $latestFile2 = $files2 | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
    $latestFile2FullPath = $workingFolderPath + $latestFile2.Name
}
else {
    Write-Host "did not find file for sending email"
}

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

#Email structure
$msg.From = $smtpUsername
$msg.To.Add($emailRecipient)
#add myself
$msg.To.Add($ccEmail)
$msg.subject = "Report File"
$msg.body = "I know this looks weird but this is Matts automated script sending you an email. Take a look at the attached report"

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.EnableSsl = 1
$smtp.Port = 587
$cred = New-Object Net.NetworkCredential($smtpUsername,$smtpPassword)
$smtp.Credentials = $cred

# Attach the file to the email

$attachment = New-Object System.Net.Mail.Attachment($latestFile2FullPath)
$msg.Attachments.Add($attachment)

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