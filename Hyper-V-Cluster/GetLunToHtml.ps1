#Load the Microsoft Storage VDS Library 
#This is an undocumented, unsupported library, there is no warrantee nor gaurantees. 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Storage.Vds") | Out-Null 
$VdsServiceLoader = New-Object Microsoft.Storage.Vds.ServiceLoader 
$VdsService = $VdsServiceLoader.LoadService($null) 
$VdsService.WaitForServiceReady() 
$VdsService.Reenumerate() 

#Build up a collection of all disks presented to the os 
$Disks = ($VdsService.Providers |% {$_.Packs}) |% {$_.Disks} 

#Import the FailoverClusters module 
Import-Module FailoverClusters 

#Retreve all of the CSV Lun's 
$AllCSVs = Get-ClusterSharedVolume | Format-Custom
$Header = @"
<style>
    TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
    TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
    TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
    TR:Nth-Child(Even) {Background-Color: #dddddd;}
    TR:Hover TD {Background-Color: #C1D5F8;}
    .odd  { background-color:#ffffff; }
    .even { background-color:#dddddd; }
</style>
<title>
    Cluster Shared Storage of $($env:COMPUTERNAME) at $(Get-Date)
</title>
"@
$precontent = @"
<H1>Cluster Shared Storage of $($env:COMPUTERNAME) at $(Get-Date)</H1>
"@
$compellent = @"
Serial,Name
SerialNumber,Volume1
SerialNumber,Volume2
SerialNumber,Volume3
"@ 
$csvcompellent = ConvertFrom-Csv $compellent
#$csvcompellent

$objs = @()
foreach ($Csv in $AllCSVs) 
{ 
    $CSVParams = Get-ClusterParameter -InputObject $Csv 
    $csvinfos = $csv | select -Property Name -ExpandProperty SharedVolumeInfo | select -Expand Partition 
    #Retreve the DiskIDGuid Object from the Cluster Parameters 
    $DiskGUIDString = ($CSVParams | Where-object -FilterScript {$_.Name -eq "DiskIdGuid"}).Value 
     
    #Match up the DiskID's 
        $Disk = ($Disks | Where-Object -FilterScript {$_.DiskGuid -eq $DiskGUIDString}) 
        $DiskWmi = Gwmi -Class Win32_DiskDrive |?{ $_.SCSILogicalUnit -eq  ($Disk.DiskAddress -split 'Lun*')[-1] }
        $compellentname = $csvcompellent |?{ $_.Serial -eq $DiskWmi.SerialNumber }
        #$csv.SharedVolumeInfo
        if(($Disk.Size / 1GB) -gt 1000){$size = "$($Disk.Size / 1TB) TB"}else{$size = "$($Disk.Size / 1GB) GB"}
        $obj = New-Object PSObject -Property @{
                    "Cluster Resource Name" = $Csv.Name 
                    "Compellent Volume Name" = $compellentname.Name
                    "Disk Lun"   = ($Disk.DiskAddress -split 'Lun*')[-1] 
                    "Disk Size" = $size
                    "Disk Status" = $Disk.Status
                    "Disk Health" = $disk.Health
                    "Free Space" = "$([Math]::Truncate($csvinfos.FreeSpace /1GB) )GB"
                    "Used Space" = "$([Math]::Truncate($csvinfos.UsedSpace / 1GB) )GB"
      
                    }
        $objs += $obj
      
       
} 

Write-Output $objs | Select "Cluster Resource Name","Compellent Volume Name","Disk Lun","Disk Size","Free Space","Used Space","Disk Health" | ConvertTo-HTML -Head $Header -PreContent $precontent | Out-File C:\temp\Test.htm 




Get-Command -Verb Format | Get-Alias

