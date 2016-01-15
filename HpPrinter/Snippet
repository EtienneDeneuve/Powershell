$Web = New-object System.Net.WebClient
[xml]$stringprinter = $Web.DownloadString("http://printerhp/DevMgmt/ConsumableConfigDyn.xml")
$stringprinter.ConsumableConfigDyn.ConsumableInfo | Select ConsumableLabelCode,ConsumablePercentageLevelRemaining 
