$baseinstaller = Get-ChildItem -Path youwant
Write-host "There's $($baseinstaller.Count) installer in this folder"
    $InstallerList = ,@()
foreach($folder in $baseinstaller){
    $subfolderinstallers = Get-ChildItem $($folder.FullName) -Recurse -Filter *.msi
    #$subfolderinstallers
    If($subfolderinstallers.Count -gt 1){
         foreach($subfolderinstaller in $subfolderinstallers){
            #Write-host "$($subfolderinstaller.fullname) seems to be a valid MSI" -ForegroundColor Green
            $ProductCode = Get-MSIInfo -Path $($subfolderinstaller.fullname) -Property ProductCode
            $ProductName = Get-MSIInfo -Path $($subfolderinstaller.fullname) -Property ProductName
            $ProductVersion = Get-MSIInfo -Path $($subfolderinstaller.fullname) -Property ProductVersion
            #Write-Host $ProductCode $ProductName $ProductVersion
            $hash = @{
                Version=$($ProductVersion.Item(1));
                ProductCode=$($ProductCode.Item(1));
                Path=$($($subfolderinstaller.fullname))
            }
            $InstallerObject = New-Object PSObject -Property $hash
            $InstallerList += $InstallerObject
         }
    }
    Else
    {
        #Write-host "$($subfolderinstallers.fullname) seems to be a valid MSI" -ForegroundColor Green
        $ProductCode =         Get-MSIInfo -Path $($subfolderinstallers.fullname) -Property ProductCode
        $ProductName =         Get-MSIInfo -Path $($subfolderinstallers.fullname) -Property ProductName
        $ProductVersion =      Get-MSIInfo -Path $($subfolderinstallers.fullname) -Property ProductVersion
        #Write-Host $ProductCode $ProductName $ProductVersion
        #$ProductVersion.Item(1)        
        $hash = @{
                Version=$($ProductVersion.Item(1));
                ProductCode=$($ProductCode.Item(1));
                Path=$($($subfolderinstallers.fullname))
            }
            $InstallerObject = New-Object PSObject -Property $hash
            $InstallerList += $InstallerObject
    }
   
}
Write-Output $InstallerList | Select-Object Path,Version,ProductCode | Export-Csv -Delimiter ";" -NoTypeInformation -Path InstallerList.CSV
function Get-MSIInfo{
 param(
[parameter(Mandatory=$true)]
[IO.FileInfo]$Path,
[parameter(Mandatory=$true)]
[ValidateSet("ProductCode","ProductVersion","ProductName")]
[string]$Property
)
try {
    $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase","InvokeMethod",$Null,$WindowsInstaller,@($Path.FullName,0))
    $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
    $View = $MSIDatabase.GetType().InvokeMember("OpenView","InvokeMethod",$null,$MSIDatabase,($Query))
    $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
    $Record = $View.GetType().InvokeMember("Fetch","InvokeMethod",$null,$View,$null)
    $Value = $Record.GetType().InvokeMember("StringData","GetProperty",$null,$Record,1)
    return $Value
} 
catch {
    Write-Output $_.Exception.Message
}
}
