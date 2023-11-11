#Set-ExecutionPolicy Unrestricted

$whereToInstall = "C:\AutomatedReportDownloader"
$reportDirectory = Join-Path $whereToInstall "reports"
$installDependenciesLogFile = $whereToInstall + "\installDependenciesLog.txt"

# GitHub repository details
$repoUrl = "https://github.com/dukkhadevops/myrepo/tree/master/Scripts/ScrapeAndEmail"
$repoOwner = "dukkhadevops"
$repoName = "myrepo"
$repoPath = "Scripts/ScrapeAndEmail"

###############################
#region Setup Working directory & log function
###############################

#check if directory exists on C - if not then create
if (-not (Test-Path -Path $whereToInstall -PathType Container)) {
    Write-Host "Directory does not exist. Creating the directory..."
    try {
        New-Item -Path $whereToInstall -ItemType Directory -Force
        New-Item -Path $reportDirectory -ItemType Directory -Force
        Write-Host "Directory created successfully."
    } catch {
        Write-Host "Failed to create the directory: $_"
    }
} else {
    Write-Host "Directory already exists."
}

#Log function
function Write-Log {
    param(
        [string]$Message
    )

    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"

    # Ensure the log directory exists
    $logDirectory = Split-Path $installDependenciesLogFile
    if (-not (Test-Path -Path $logDirectory -PathType Container)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    # Write the log entry to the log file
    Add-Content -Path $installDependenciesLogFile -Value $logEntry
}

###############################
#endregion
###############################

###############################
#region Install Selenium
###############################
if (-not (Get-Module -Name Selenium -ListAvailable)) {
    # If not installed, attempt to install the module from the PowerShell Gallery
    try {
        $msg = "Installing Selenium module..."
        Write-Host $msg
        Write-Log $msg
        Install-Module -Name Selenium -Force -AllowClobber -Scope AllUsers
        $msg = "Selenium module has been installed."
        Write-Host $msg
        Write-Log $msg
    } catch {
        $msg = "Failed to install the Selenium module: $_"
        Write-Host $msg
        Write-Log $msg
        # You can choose to exit the script or handle the error as per your requirements.
        # exit 1  # Uncomment this line to exit the script if installation fails.
    }
}
###############################
#endregion
###############################

###############################
#region Install Web Driver
###############################
# Download the zip file

# Web Drivers - URL of the zip file to download
#$zipUrl = "https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-win64.zip"
#$chromeDriver = "https://sites.google.com/a/chromium.org/chromedriver/downloads"
#$zipUrl = "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/115.0.5790.102/win64/chrome-win64.zip"
$zipUrl = "http://chromedriver.storage.googleapis.com/114.0.5735.90/chromedriver_win32.zip"


$msg = "Download and unzip webdriver"
Write-Host $msg
Write-Log $msg
$zipFile = Join-Path $whereToInstall "webdriver.zip"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile

# Extract the contents of the zip file
$destinationPath = Join-Path $whereToInstall "webdriver"
Expand-Archive -Path $zipFile -DestinationPath $destinationPath -Force
$msg = "Done downloading and unzipping"
Write-Host $msg
Write-Log $msg

# Optional: Remove the downloaded zip file (uncomment the line below if you want to delete it)
# Remove-Item -Path $zipFile -Force
###############################
#endregion
###############################

###############################
#region Python install
###############################
# Python
#$pythonZip = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-embed-amd64.zip"  #didnt seem to work
$pythonInstall = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"

# Download the zip file
$msg = "Download and unzip python"
Write-Host $msg
Write-Log $msg
$File = Join-Path $whereToInstall "pythoninstall.exe"
Invoke-WebRequest -Uri $pythonInstall -OutFile $File

#call the exe with args
#python-3.9.0.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
$arguments = '/quiet', 'InstallAllUsers=1', 'PrependPath=1', 'Include_test=0'
Start-Process -FilePath $File -ArgumentList $arguments
$msg = "Done downloading and unzipping Python"
Write-Host $msg
Write-Log $msg

###############################
#endregion
###############################

###############################
#region Everything from Git repo
###############################
$msg = "Get everything from Git Repo"
Write-Host $msg
Write-Log $msg
function Get-GitHubRawFileUrls {
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$RepoPath
    )

    $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/git/trees/master?recursive=1"

    $response = Invoke-RestMethod -Uri $apiUrl
    $fileUrls = $response.tree | Where-Object { $_.path -like "$RepoPath/*" -and $_.type -eq "blob" } | ForEach-Object { $_.path }

    return $fileUrls
}

function Download-GitHubFiles {
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$RepoPath,
        [string]$DestinationDirectory
    )

    $fileUrls = Get-GitHubRawFileUrls -RepoOwner $RepoOwner -RepoName $RepoName -RepoPath $RepoPath

    if (-not (Test-Path -Path $DestinationDirectory -PathType Container)) {
        New-Item -Path $DestinationDirectory -ItemType Directory -Force | Out-Null
    }

    foreach ($url in $fileUrls) {
        $fileName = [System.IO.Path]::GetFileName($url)
        $destinationFile = Join-Path $DestinationDirectory $fileName

        $response = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/$RepoOwner/$RepoName/master/$url"
        #$decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.content))
        #$decodedContent | Set-Content -Path $destinationFile
        $response | Set-Content -Path $destinationFile
    }

    Write-Host "Files from $Path downloaded successfully to $DestinationDirectory."
}

Download-GitHubFiles -RepoOwner $repoOwner -RepoName $repoName -RepoPath $repoPath -DestinationDirectory $whereToInstall

$msg = "Done getting everything from Git Repo"
Write-Host $msg
Write-Log $msg

###############################
#endregion
###############################

#################################
#region Chrome madness
# must be 114 like Chrome driver
#################################
#doesnt work
#$chromeEnterpriseUrl = "https://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi"
#https://google-chrome.en.uptodown.com/windows/versions

#START HERE
#https://stackoverflow.com/questions/54927496/how-to-download-older-versions-of-chrome-from-a-google-official-site
# TUTORIAL DOESNT SEEM TO HAVE 114

#END HERE
# https://chromium.cypress.io/
# https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win_x64%2F1135619%2Fchrome-win.zip?generation=1682469079864558&alt=media
# https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win_x64%2F1135619%2Fmini_installer.exe?generation=1682469386699488&alt=media

$ChromeVersion = '114'

$requestId = ([String][Guid]::NewGuid()).ToUpper()
$sessionId = ([String][Guid]::NewGuid()).ToUpper()

$xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<request protocol="3.0" updater="Omaha" sessionid="{$sessionId}"
    installsource="update3web-ondemand" requestid="{$requestId}">
    <os platform="win" version="10.0" arch="x64" />
    <app appid="{8A69D345-D564-463C-AFF1-A69D9E530F96}" version="5.0.375"
        ap="x64-stable-statsdef_0" lang="" brand="GCEB">
        <updatecheck targetversionprefix="$ChromeVersion"/>
    </app>
</request>
"@

$webRequest = @{
    Method    = 'Post'
    Uri       = 'https://tools.google.com/service/update2'
    Headers   = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
        'X-Goog-Update-Interactivity' = 'fg'
    }
    Body      = $Xml
}

$result = Invoke-WebRequest @webRequest -UseBasicParsing
$contentXml = [xml]$result.Content
$status = $contentXml.response.app.updatecheck.status
if ($status -eq 'ok') {
    $package = $contentXml.response.app.updatecheck.manifest.packages.package
    $urls = $contentXml.response.app.updatecheck.urls.url | ForEach-Object { $_.codebase + $package.name }
    Write-Output "--- Chrome Windows 64-bit found. Hash=$($package.hash) Hash_sha256=$($package.hash_sha256)). ---"
    Write-Output $urls
}
else {
    Write-Output "Chrome not found (status: $status)"
}

#this outputs something like this - http://dl.google.com/release2/chrome/dcrhyd6kdj5w7yk3dxqr6xuwda_114.0.5735.199/114.0.5735.199_chrome_installer.exe

#now that we have a download link. download it a put it somewhere
$urls[0]

$destinationPath = "C:\AutomatedReportDownloader\chrome114.exe"
#set a better named variable for later use
$chromeInstaller = $destinationPath

# Create a WebClient object to download the file
$webClient = New-Object System.Net.WebClient

# Download the file
$webClient.DownloadFile($urls[0], $destinationPath)

# Check if the download was successful
if (Test-Path $destinationPath) {
    $msg = "File downloaded successfully to $destinationPath"
    Write-Host $msg
    Write-Log $msg
} else {
    Write-Host "Download failed."
    Write-Log "Download failed."
}

# Define the installation parameters for a verbose installation log
$installChromeHere = Join-Path $whereToInstall "chrome114"

$installParams = @{
    FilePath = $chromeInstaller
    PassThru = $true
    Wait = $true
    ArgumentList = @(
        "/S",                    # Silent installation
        "/D=$installChromeHere"     # Specify the installation directory
    )
}

# Install Google Chrome silently with verbose logging
Start-Process @installParams -Verbose

# Check the exit code to verify the installation status
if ($LASTEXITCODE -eq 0) {
    Write-Host "Google Chrome installed successfully."
    Write-Log "Google Chrome installed successfully."
} else {
    Write-Host "Google Chrome installation failed with exit code $LASTEXITCODE."
    Write-Log "Google Chrome installation failed with exit code $LASTEXITCODE."
}

# Wait for some time to ensure that the installation is complete
Start-Sleep -Seconds 10

# Find and close any running instances of Chrome
$chromeProcesses = Get-Process -Name chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    foreach ($process in $chromeProcesses) {
        $process | Stop-Process -Force
    }
}

#################################
#endregion
#################################


###############################
#region Install Chrome Enterprise DEPRECATED FOR NOW
###############################
# $msg = "Downloading Chrome Enterprise version we specifically need"
# Write-Host $msg
# Write-Log $msg

# # Destination path to save the downloaded file
# $destinationPath = "C:\AutomatedReportDownloader\googlechromestandaloneenterprise64.msi"
# #set a better named variable for later use
# $chromeInstaller = $destinationPath

# # Create a WebClient object to download the file
# $webClient = New-Object System.Net.WebClient

# # Download the file
# $webClient.DownloadFile($chromeEnterpriseUrl, $destinationPath)

# # Check if the download was successful
# if (Test-Path $destinationPath) {
#     $msg = "File downloaded successfully to $destinationPath"
#     Write-Host $msg
#     Write-Log $msg
# } else {
#     Write-Host "Download failed."
#     Write-Log "Download failed."
# }

# # Define the installation parameters for a verbose installation log
# $installParams = @{
#     FilePath = "msiexec.exe"
#     PassThru = $true
#     Wait = $true
#     ArgumentList = @(
#         "/i", $chromeInstaller,  # Specify the MSI file
#         "/qn",                   # Quiet mode (no UI)
#         "/norestart",            # Do not restart after installation
#         "/log",                  # Log installation progress
#         "C:\chrome_install.log"  # Path to the installation log file
#     )
# }

# # Install Google Chrome silently with verbose logging
# Start-Process @installParams -Verbose

# # Check the exit code to verify the installation status
# if ($LASTEXITCODE -eq 0) {
#     Write-Host "Google Chrome installed successfully."
#     Write-Log "Google Chrome installed successfully."
# } else {
#     Write-Host "Google Chrome installation failed with exit code $LASTEXITCODE."
#     Write-Log "Google Chrome installation failed with exit code $LASTEXITCODE."
# }

###############################
#endregion
###############################

###############################
#region disable Chrome updates
###############################
$msg = "disabling Chrome updates via registry..."
Write-Host $msg
Write-Log $msg

# Define the Registry key and value to update
$RegistryPath = "HKLM:\SOFTWARE\Policies\Google\Update"
$ValueName = "AutoUpdateCheckPeriodMinutes"
$ValueType = [Microsoft.Win32.RegistryValueKind]::DWord
$NewValue = 0

# Check if the Registry key exists, and if not, create it
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force
}

# Set the Registry value
$msg = "setting the registry value..."
Write-Host $msg
Write-Log $msg
Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $NewValue -Type $ValueType

# Verify the change
$msg = "show what we set....."
Write-Host $msg
Write-Log $msg
Get-ItemProperty -Path $RegistryPath -Name $ValueName

###############################
#endregion
###############################

$msg = "----------------------------------"
Write-Host $msg
Write-Log $msg
Write-Host "End of InstallDependencies.ps1"
Write-Log "End of InstallDependencies.ps1"
Write-Host $msg
Write-Log $msg