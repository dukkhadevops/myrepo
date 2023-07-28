$whereToInstall = "C:\AutomatedReportDownloader"
# Gecko - URL of the zip file to download
$zipUrl = "https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-win64.zip"
# URL of the GitHub repository directory
$repoUrl = "https://github.com/dukkhadevops/myrepo/tree/master/Scripts/ScrapeAndEmail"

###############################
#region Setup Working directory
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

###############################
#endregion
###############################

###############################
#region Install Selenium
###############################
if (-not (Get-Module -Name Selenium -ListAvailable)) {
    # If not installed, attempt to install the module from the PowerShell Gallery
    try {
        Write-Host "Installing Selenium module..."
        Install-Module -Name Selenium -Force -AllowClobber -Scope AllUsers
        Write-Host "Selenium module has been installed."
    } catch {
        Write-Host "Failed to install the Selenium module: $_"
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
# Create the destination directory if it doesn't exist
if (-not (Test-Path -Path $whereToInstall -PathType Container)) {
    New-Item -Path $whereToInstall -ItemType Directory -Force | Out-Null
}

# Fetch the GitHub repository page and parse the HTML content
$response = Invoke-WebRequest -Uri $repoUrl
$links = $response.Links | Where-Object { $_.rel -eq "noopener" }

# Download each file from the repository
foreach ($link in $links) {
    $url = $link.href
    $filename = $url.Split('/')[-1]
    $destinationFile = Join-Path $whereToInstall $filename
    Invoke-WebRequest -Uri $url -OutFile $destinationFile
}

Write-Host "Files downloaded successfully to $whereToInstall."

###############################
#endregion
###############################