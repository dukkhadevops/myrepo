$outpath = "C:\SVN\WindowsAdmins\Scripts\IPRangeLookup\output.txt"
$subnet = "172.16.200"

$stuff = 1..254 | ForEach-Object {Get-WmiObject Win32_PingStatus -Filter "Address='$subnet.$_' and Timeout=200 and ResolveAddressNames='true' and StatusCode=0" | select ProtocolAddress*}
$stuff | Format-Table | Out-File $outpath
