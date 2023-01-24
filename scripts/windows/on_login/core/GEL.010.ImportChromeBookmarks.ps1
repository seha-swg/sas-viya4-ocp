Write-Verbose "$('*'*30)`n$(Get-Date -UFormat '%Y-%m-%d %T') Starting $PSCommandPath"
$MODULE="$Global:codeDir\gellow\scripts\common\common_functions.psm1"

Import-Module $MODULE -Force

#Get the hostname of the linux jumphost from vars file
$sasnode01=$(Get-VarsFile).race_node01

$ChromeBase="$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
$BookmarksFile="Bookmarks"

$ViyaURL="https://gel-viya.apps." + $sasnode01 + ".gelenable.sas.com"

$OCPConsoleURL="https://console-openshift-console.apps." + $sasnode01 + ".gelenable.sas.com"

# Only if Chrome dir exist
if (Test-Path $ChromeBase) {
    # Force-Copy Bookmarks file (this overwrites any change)
    Write-Verbose "Copying Google Chrome Bookmarks into $ChromeBase"
    #Copy-Item -Path "$Global:codeDir\*\assets\Windows\$BookmarksFile" `
    #    -Destination "$ChromeBase\$BookmarksFile" `
    #    -Force

    # Replace placeholders
    ((Get-Content -path "$Global:codeDir\*\assets\Windows\$BookmarksFile" -Raw) `
        -replace '{{ VIYA_URL }}', $ViyaURL `
        -replace '{{ OCP_CONSOLE_URL }}', $OCPConsoleURL `
    ) | Set-Content -path "$ChromeBase\$BookmarksFile"
}

Write-Output "*** DONE $PSCommandPath"