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
$amazonLoginUrl = $values["amazonloginurl"]
$workingFolderPath = $values["workingfolderpath"]
$pathToReports = $values["path_to_reports"]
$firefoxDownloadPath = $values["firefoxdownloadpath"]

# Import the Selenium module
Import-Module Selenium

# Display the values for verification
# Write-Host "SMTP Username: $smtpUsername"
# Write-Host "SMTP Password: $smtpPassword"
# Write-Host "Amazon Username: $amazonUsername"
# Write-Host "Amazon Password: $amazonPassword"
######################
#endregion
######################

######################
#region Amazon Webscrape
####################

# Specify the path to the Selenium WebDriver executable (geckodriver for Firefox in this example)
#$driverPath = "C:\Users\Matt\Downloads\geckodriver\geckodriver.exe"
#$driverPath = "C:\Users\Matt\Downloads\geckodriver\"

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

# THIS IS NOT WORKING IN HERE. LOOK AT PYTHON FOR STEALTH MODE
######################
#region Barnes & Noble Webscrape
######################
# $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($chromeBinaryPath)

# # Navigate to the Amazon login page
# $driver.Navigate().GoToUrl($bnLoginUrl)
# # Wait for the login process to complete
# Start-Sleep -Seconds 1

# # Find the email or phone number input field and enter the username
# $usernameInput = $driver.FindElementById("signin_email")
# $usernameInput.SendKeys($bnUsername)
# # Wait for the login process to complete
# Start-Sleep -Seconds 1

# # Find the password input field and enter the password
# $passwordInput = $driver.FindElementById("signin_password")
# $passwordInput.SendKeys($bnPassword)
# # Wait for the login process to complete
# Start-Sleep -Seconds 1

# # Find the sign-in button and click it
# #$signInButton = $driver.FindElementById("signInSubmit")
# #$signInButton.Click()
# $signInButton = $driver.FindElementByXPath("//button[contains(text(),'Sign In')]")
# $signInButton.Click()
# # Wait for the login process to complete
# Start-Sleep -Seconds 3

# #Find the yesterday button within the overview-header and click it
# $yesterdayButton = $driver.FindElementByXPath("//button[@mdn-tab-value='YESTERDAY']")
# $yesterdayButton.Click()
# Start-Sleep -Seconds 3

# # Find the download button which is apart of reports-content element and click it
# $downloadButton = $driver.FindElementByXPath("//div[@id='reports-content']//div[contains(@class, 'overview-download-button')]/div[contains(@class, 'download-button-wrapper')]/div/button[contains(@class, 'download-button')]")
# $downloadButton.Click()
# Start-Sleep -Seconds 5

# #Close out
# $driver.Quit()

####################
#endregion Webscrape
######################

######################
#region rename & move file
######################
$searchPattern = "KDP_*.xlsx"  # Specify the search pattern to match the desired files

# Get the list of XLSX files that match the search pattern in the specified folder
$files = Get-ChildItem -Path $firefoxDownloadPath -Filter $searchPattern | Where-Object { $_.Extension -eq ".xlsx" }

if ($files.Count -gt 0) {
    # Sort the files by creation time in descending order to get the latest file
    $latestFile = $files | Sort-Object -Property CreationTime -Descending | Select-Object -First 1

    # Move the file from browser download dir to reports dir
    $latestFileFullPath = $firefoxDownloadPath + $latestFile.Name
    Move-Item -Path $latestFileFullPath -Destination $pathToReports -Force

    # Grab the file from the new location
    $files2 = Get-ChildItem -Path $pathToReports -Filter $searchPattern | Where-Object { $_.Extension -eq ".xlsx" }
    if ($files2.Count -gt 0){
        # Sort again
        $latestFile2 = $files2 | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
        
        # Get the date and switch it to yesterdays date to keep consistent between all reports
        $currentDate = Get-Date
        # Subtract one day from the current date to get yesterday's date
        $yesterdayDate = $currentDate.AddDays(-1)
        # Format the date as "M-d-yyyy-hhmmss"
        $formattedDate = $yesterdayDate.ToString("M-d-yyyy-hhmmss")

        # Generate the new name based on the desired format
        $newName = "KDP-" + $formattedDate + ".xlsx"

        # Rename the file
        #$newPath = [System.IO.Path]::Combine($workingFolderPath, $newName)
        Rename-Item -Path $latestFile2.FullName -NewName $newName
    }
    else {
        Write-Host "did not find file after moving it"
    }
}
######################
#endregion
######################
