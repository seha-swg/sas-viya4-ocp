Write-Verbose "$('*'*30)`n$(Get-Date -UFormat '%Y-%m-%d %T') Starting $PSCommandPath"

#Prepare a warning in bginfo so that, if a user logs in while this is still running, they get a warning.
$bgDir="C:\Support\BackgroundInfo"

if (Test-Path -Path "$bgDir\bginfo.exe") {
    Copy-Item -Path $Global:codeDir\*\assets\Windows\gelWarning.bgi -Destination "$bgDir\config.bgi"
}

Write-Output "*** DONE $PSCommandPath"