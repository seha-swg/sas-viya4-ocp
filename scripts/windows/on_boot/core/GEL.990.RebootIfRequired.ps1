Write-Verbose "$('*'*30)`n$(Get-Date -UFormat '%Y-%m-%d %T') Starting $PSCommandPath"

$pendingRebootTests = @(
 @{
 Name = 'RebootPending'
 Test = { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Name 'RebootPending' -ErrorAction Ignore }
 TestType = 'ValueExists'
 }
 @{
 Name = 'RebootRequired'
 Test = { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction Ignore }
 TestType = 'ValueExists'
 }
 @{
 Name = 'PendingFileRenameOperations'
 Test = { Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Ignore }
 TestType = 'NonNullValue'
 }
)
$pendingReboot=$false

foreach ($test in $pendingRebootTests) {
 $result = Invoke-Command -ScriptBlock $test.Test
 if ($test.TestType -eq 'ValueExists' -and $result) {
 $pendingReboot=$true
 } elseif ($test.TestType -eq 'NonNullValue' -and $result -and $result.($test.Name)) {
 $pendingReboot=$true
 }
}

Write-Verbose "Testing for a pending reboot returned: $pendingReboot"

if ( $pendingReboot ) {
    Write-Output "It seems a reboot is pending. Rebooting in 10 seconds."
    #p:4.2 means "planned, Application: Installation"
    Shutdown /t 10 /f /r /d p:4:2
}

Write-Output "*** DONE $PSCommandPath"