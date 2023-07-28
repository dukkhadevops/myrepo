### TODO
```
- run browser in background
- do we need firefox install?
- actually read the report - what needs changed?
- do we want to automate cleaning up old files
- put things in functions - log function maybe
- parameterize smtp server & port
```

# To Install
```
1) Download install.bat
2) double click to run it
3) at the top of ScrapeAndEmail.ps1 & CreateScheduledTask.ps1 there is a reference to a values.txt file
4) values.txt file needs to be in the correct location & updated with all relevant info
5) due to python code you cannot have empty lines in values.txt
```

## install.bat
```
starts elevated powershell processes to run InstallDependencies.ps1 & CreateScheduledTask.ps1
```

## InstallDependencies.ps1
```
Sets up working directory. Installs Selenium and Geckodriver. Downloads everything from Git repo
```

## CreateScheduledTask.ps1
```
Just creates a Windows scheduled task to call ScrapeAndEmail.ps1 - relies on values.txt
```

## ScapeAndEmail.ps1
```
Does the heavy lifting. Scrapes the pages. Downloads report(s). Emails them.
```