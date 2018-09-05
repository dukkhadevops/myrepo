$erroractionpreference = "SilentlyContinue"
$Error.Clear()
$lf = "C:\Inetpub\Logs\LogFiles\*"
$colItems = Get-ChildItem $lf -Recurse
$date = (Get-Date).AddDays(-7)
$date = Get-Date $date -Format yyMMdd
#$date
foreach ($i in $colItems)
{
	#$i.Name.toString().SubString(4,6)
	if ($i.PsIsContainer -eq $false -and $i.Name.toString().substring(4,6) -lt $date -and `
		$i.extension -eq ".log" -and $i.Name.toString().subString(0,4) -eq "u_ex")
	{
		#"Deleting " + $i.FullName
		Remove-Item $i.pspath
	}
}
