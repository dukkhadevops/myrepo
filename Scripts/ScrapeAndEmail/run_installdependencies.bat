@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0InstallDependencies.ps1\"' -Verb RunAs"
