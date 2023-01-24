Write-Verbose "$('*'*30)`n$(Get-Date -UFormat '%Y-%m-%d %T') Starting $PSCommandPath"

#Configure the default background
$bgDir="C:\Support\BackgroundInfo"

if (Test-Path -Path "$bgDir\bginfo.exe") {
    Copy-Item -Path $Global:codeDir\*\assets\Windows\config.bgi -Destination "$bgDir"
    . "$bgDir\bginfo.exe" /iq$bgDir\config.bgi /timer:0
}

Write-Output "*** DONE $PSCommandPath"