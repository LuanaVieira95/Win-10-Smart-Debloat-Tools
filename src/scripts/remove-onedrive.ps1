Import-Module -DisableNameChecking $PSScriptRoot\..\lib\original\"New-FolderForced.psm1"

function Remove-OneDrive() {
    # Description: This script will remove and disable OneDrive integration.
    Write-Host "Kill OneDrive process..."
    taskkill.exe /F /IM "OneDrive.exe"
    taskkill.exe /F /IM "explorer.exe"

    Write-Host "Remove OneDrive."
    if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
        & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
    }
    if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
        & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
    }

    Write-Host "Removing OneDrive leftovers..."
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp"
    # check if directory is empty before removing:
    If ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse | Measure-Object).Count -eq 0) {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:userprofile\OneDrive"
    }

    Write-Host "Disable OneDrive via Group Policies."
    New-FolderForced -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1

    Write-Host "Remove Onedrive from explorer sidebar."
    New-PSDrive -PSProvider "Registry" -Root "HKEY_CLASSES_ROOT" -Name "HKCR"
    mkdir -Force "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
    mkdir -Force "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
    Remove-PSDrive "HKCR"

    # Thank you Matthew Israelsson
    Write-Host "Removing run hook for new users..."
    reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
    reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
    reg unload "hku\Default"

    Write-Host "Removing startmenu entry..."
    Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

    Write-Host "Removing scheduled task..."
    Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ea SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

    Write-Host "Restarting explorer..."
    Start-Process "explorer.exe"

    Write-Host "Waiting for explorer to complete loading..."
    Start-Sleep 5
}

function Main() {
    Remove-OneDrive
}

Main