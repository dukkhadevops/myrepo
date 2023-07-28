$whereToInstall = "C:\AutomatedReportDownloader"
$installDependenciesLogFile = $whereToInstall + "\installDependenciesLog.txt"

# Gecko - URL of the zip file to download
$zipUrl = "https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-win64.zip"
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
#region Install Gecko Driver
###############################
# Download the zip file
$zipFile = Join-Path $whereToInstall "geckodriver.zip"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile

# Extract the contents of the zip file
$destinationPath = Join-Path $whereToInstall "geckodriver"
Expand-Archive -Path $zipFile -DestinationPath $destinationPath -Force

# Optional: Remove the downloaded zip file (uncomment the line below if you want to delete it)
# Remove-Item -Path $zipFile -Force
###############################
#endregion
###############################

###############################
#region Everything from Git repo
###############################
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

###############################
#endregion
###############################