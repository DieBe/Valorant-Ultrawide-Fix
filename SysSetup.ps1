﻿$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $env:HOMEPATH\Documents\ValorantUltrawideHack\SysSetup_log.log -append

$launcherPath = $env:HOMEPATH + '\ValorantUltrawideHack\ValorantLauncher.bat'
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$SearchDir = $env:LOCALAPPDATA + '\VALORANT\Saved\Config'
$TokenizedResults = gci -Recurse -Filter "GameUserSettings.ini" -File -Path $SearchDir -Force
$SrcPath = $ScriptDir + '\GameUserSettingsSrc.ini'
$TargetPath = $TokenizedResults.DirectoryName + '\GameUserSettingsSrc.ini'
$ExistingSettings = $TokenizedResults.DirectoryName + '\GameUserSettings.ini'

# Find Riot installation

$regKey = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\riotclient\DefaultIcon
$dirtyPath = $regKey.'(default)'
$riotPath = $dirtyPath.Substring(0, $dirtyPath.Length-2)

# Debugging variables
Write-Host "SearchDir: " $SearchDir
Write-Host "TokenizedResults: " $TokenizedResults
Write-Host $TokenizedResults.DirectoryName
Write-Host "ScriptDir: " $ScriptDir
Write-Host "SrcPath: " $SrcPath
Write-Host "TargetPath: " $TargetPath
Write-Host "ExistingSettings: " $ExistingSettings
Write-Host "riotPath: " $riotPath

function WriteLauncher {
    
    # Generate BAT file

    $fName = $ScriptDir + '\ValorantLauncher.bat'
    New-Item $fName
    'taskkill /IM RiotClientServices.exe /IM RiotClientCrashHandler.exe /F'  | Out-File $fName -Append -encoding "oem"
    'timeout /t 5 /nobreak > NUL'  | Out-File $fName -Append -encoding "oem"
    'del %HOMEPATH%\Documents\ValorantUltrawideHack\ValorantLauncher_log.log' | Out-File $fName -Append -encoding "oem"
    'set LOGFILE=%HOMEPATH%\Documents\ValorantUltrawideHack\ValorantLauncher_log.log' | Out-File $fName -Append -encoding "oem"
    'call :LOG > %LOGFILE%' | Out-File $fName -Append -encoding "oem"
    'exit /B' | Out-File $fName -Append -encoding "oem"
    ':LOG' | Out-File $fName -Append -encoding "oem"
    'echo Patching Valorant screen resolution...' | Out-File $fName -Append -encoding "oem"
    'copy ' + $TargetPath + ' ' + $TokenizedResults.DirectoryName + '\GameUserSettings.ini' | Out-File $fName -Append -encoding "oem"
    'echo Killing your Windows taskbar until game has closed...' | Out-File $fName -Append -encoding "oem"
    'echo Launching Valorant in Ultrawide' | Out-File $fName -Append -encoding "oem"
    'start "" ' + $riotPath + ' --launch-product=valorant --launch-patchline=live' | Out-File $fName -Append -encoding "oem"

    # Generate shortcut

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ScriptDir + '\Valorant Ultrawide Launcher.lnk') 
    $Shortcut.TargetPath = $launcherPath
    $Shortcut.IconLocation = $env:HOMEPATH + '\ValorantUltrawideHack\launcher.ico'
    $Shortcut.Save()

}

function GetGraphicsInfo5 {
    $existing_data = Get-Content $ExistingSettings
    $firstFive = $existing_data | Select-Object -First 5    
    return $firstFive
}

function GetGraphicsInfo15 {
    $existing_data = Get-Content $ExistingSettings
    $last = $existing_data | Select-Object -Last 15    
    return $last
}

function FindMonitors {

    Add-Type -AssemblyName System.Windows.Forms
    $test = [System.Windows.Forms.Screen]::AllScreens

    if ($test.Length -gt 1){
        $i = 1
        foreach ($monitor in $test){
    
            Write-Host "Multiple monitors found. Please choose the monitor that you play Valorant on."
            Write-Host " "
            Write-Host 'Monitor #' $i ': '
            Write-Host " "
            Write-Host $monitor.DeviceName
            Write-Host $monitor.Bounds
        

            $i += 1
        }
        Write-Host " "
        $num = Read-Host "Please select your monitor #"

        $int = $num -as [int]
    
        $ScreenWidth = $test[$int-1].Bounds.Width
        $ScreenHeight = $test[$int-1].Bounds.Height
    
        
    }

    else{

        $ScreenWidth = $test[0].Bounds.Width
        $ScreenHeight = $test[0].Bounds.Height
        
    }

    return $ScreenHeight, $ScreenWidth
}


function WriteGameSettings {
    $existingSettingsfile = Get-Content $ExistingSettings
    Write-Host "Getting your native monitor resolution..."
    $height, $width = FindMonitors
    Write-Host "ScreenResolution: " $height "x" $width
    Write-Host "Creating your Valorant graphics profile..."
    $SrcIniName = $ScriptDir + '\GameUserSettingsSrc.ini'
    New-Item $SrcIniName
    GetGraphicsInfo5 | Out-File $SrcIniName -Append -encoding "ascii"
    'bShouldLetterbox=False' | Out-File $SrcIniName -Append -encoding "ascii"
    'bLastConfirmedShouldLetterbox=False' | Out-File $SrcIniName -Append -encoding "ascii"
    'bUseVSync=False' | Out-File $SrcIniName -Append -encoding "ascii"
    'bUseDynamicResolution=False' | Out-File $SrcIniName -Append -encoding "ascii"
    'ResolutionSizeX=' + $width | Out-File $SrcIniName -Append -encoding "ascii"
    'ResolutionSizeY=' + $height | Out-File $SrcIniName -Append -encoding "ascii"
    'LastUserConfirmedResolutionSizeX=' + $width | Out-File $SrcIniName -Append -encoding "ascii"
    'LastUserConfirmedResolutionSizeY=' + $height | Out-File $SrcIniName -Append -encoding "ascii"
    'WindowPosX=0' | Out-File $SrcIniName -Append -encoding "ascii"
    'WindowPosY=0' | Out-File $SrcIniName -Append -encoding "ascii"
    'LastConfirmedFullscreenMode=2' | Out-File $SrcIniName -Append -encoding "ascii"
    'PreferredFullscreenMode=2' | Out-File $SrcIniName -Append -encoding "ascii"
    'AudioQualityLevel=0' | Out-File $SrcIniName -Append -encoding "ascii"
    'LastConfirmedAudioQualityLevel=0' | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 19 | Out-File $SrcIniName -Append -encoding "ascii"
    'DesiredScreenWidth=' + $width | Out-File $SrcIniName -Append -encoding "ascii"
    'DesiredScreenHeight=' + $height | Out-File $SrcIniName -Append -encoding "ascii"
    'LastUserConfirmedDesiredScreenWidth=' + $width | Out-File $SrcIniName -Append -encoding "ascii"
    'LastUserConfirmedDesiredScreenHeight=' + $height | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 24 | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 25 | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 26 | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 27 | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 28 | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 29 | Out-File $SrcIniName -Append -encoding "ascii"
    $existingSettingsfile | Select-Object -Index 30 | Out-File $SrcIniName -Append -encoding "ascii"
    'FullscreenMode=2' | Out-File $SrcIniName -Append -encoding "ascii"
    '' | Out-File $SrcIniName -Append -encoding "ascii"
    '[/Script/Engine.GameUserSettings]' | Out-File $SrcIniName -Append -encoding "ascii"
    'bUseDesiredScreenHeight=True' | Out-File $SrcIniName -Append -encoding "ascii"
    GetGraphicsInfo15 | Out-File $SrcIniName -Append -encoding "ascii"
}

function GenerateUninstaller($appDir) {
    $u_fName = $ScriptDir + '\uninstall.bat'
    New-Item $u_fName
    '@echo off' | Out-File $u_fName -Append -encoding "oem"
    'rmdir "%HOMEPATH%\Documents\ValorantUltrawideHack" /S /Q' | Out-File $u_fName -Append -encoding "oem"
    'del "' + $appDir + '\GameUserSettingsSrc.ini"' | Out-File $u_fName -Append -encoding "oem"
    'del "%HOMEPATH%\Desktop\Valorant Ultrawide Launcher.lnk"' | Out-File $u_fName -Append -encoding "oem"
    'echo Uninstall complete...Press any key to close.' | Out-File $u_fName -Append -encoding "oem"
    'pause' | Out-File $u_fName -Append -encoding "oem"
    'del "' + $ScriptDir + '\uninstall.bat"' | Out-File $u_fName -Append -encoding "oem"
}

$host.ui.RawUI.WindowTitle = "Kyle's Valorant Ultrawide Patch Installer"
Write-Host ""
Write-Host "Kyle's Valorant Ultrawide Patch Installer"
Write-Host " "
Write-Host "Elevating permissions..."
Write-Host "Getting system information..."

WriteGameSettings
Write-Host ""
Write-Host "Copying patch files to game directory..."
Write-Host ""
copy $SrcPath $TargetPath
Write-Host "Creating your custom Valorant launch script..."
WriteLauncher
Write-Host "Generating an uninstaller"
GenerateUninstaller($TokenizedResults.DirectoryName)
Stop-Transcript
pause
