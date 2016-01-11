Function Update-AppxBundleCert{
param(
    $packagesourcename  = "xxx.appxbundle",
    $packagesourcepath = "C:\Users\adm_etienne\Desktop\folderofthedependcies",
    $destinationroot = "C:\Users\adm_etienne\Desktop\Destination",
    $vstool = "C:\Program Files (x86)\Windows Kits\8.1\bin\x64",
    $certificateSAN = "CN=XXXX, OU=XXX, O=XXX, L=XXX, S=XXX, C=XX",
    $certificatePath = "x:\whereyouhaveputyour\cert.pfx",
    $certificatetimestampurl = "http://timestamp.digicert.com(usetheoneofyourcertificateprovider",
    $certificatepass = "ThePasskeyofyourcertificatedon'tletinyourscript!!!",
    $logfile = "$($destinationroot)\logs\makeappx-$(get-date -f ddMMyyyyHHmmss).log",
    $7ZipSFXToolsPath = "${env:ProgramFiles(x86)}\7z SFX Tools",
    $7ZipExecutable = "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )
    begin{
        #check if VStools are installed and add it to the current path
        if($(Test-Path $vstool)){
            $env:Path = $env:Path + ";" + $vstool
        }else{
            Write-Host "VS tools aren't found !" -ForegroundColor Red
        }
        if(!$(Test-path $logfile)){
            New-Item -ItemType Directory -Path "$($destinationroot)\logs" | Out-Null
            New-Item -ItemType File -Path $logfile | Out-Null
        }
        if(!$(Test-Path $destinationroot)){
            New-Item -ItemType Directory -Path "$($destinationroot)" | Out-Null
        }
        if(!$(Test-Path $certificatePath)){
            Write-Host "The certificate isn't found !" -ForegroundColor Red
            break;
        }
        if($(Test-Connection $certificatetimestampurl -Count 1 -Quiet )){
            Write-Host "timestamp.digicert.com isn't reacheable !" -ForegroundColor Red
            break;
        }
        if(!$(Test-Path $7ZipSFXToolsPath)){
            Write-Host "7Zip aren't installed ?" -ForegroundColor Red
                $title = "Download 7Zip Tools"
                $message = "Do you want to download it ?"
                $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                "Download and Launch the installer."
                $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "Exit the script."
                $other = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "Continue without SFX Created."
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $other)
                $result = $host.ui.PromptForChoice($title, $message, $options, 0) 
                switch ($result)
                {
                0 {Get-7zipSFXTools}
                1 {break;}
                2 {$noarchive = $true}
                }

        }
        if(!$(Test-Path $7ZipExecutable)){
            Write-Host "7 Zip isn't found!" -ForegroundColor Red
            break;
        }

    }
    process{
        Write-Host "Unbunling the package $($packagesourcename) in :`t $($destinationroot) !" -ForegroundColor Green
        makeappx unbundle /p $($packagesourcepath + "\" + $packagesourcename) /d "$($destinationroot)\expanded\bundle" *>$logfile
        $appxs = Get-ChildItem -Filter *.appx -Path "$($destinationroot)\expanded\bundle" -recurse
            foreach($appx in $appxs){
                Write-Host "Unpacking the package $($appx.Name) in :`t $($destinationroot)\expanded\Appx\$($appx.BaseName)\ " -ForegroundColor Green
                makeappx unpack /p $($appx.Fullname) /d "$($destinationroot)\expanded\Appx\$($appx.BaseName)"  *>>$logfile
            }
        #region manifest
            Write-Host "Getting the manifest in :`t $("$($destinationroot)\expanded\") !" -ForegroundColor Green
            $ManifestBundle = Get-ChildItem -Filter AppxBundleManifest.xml -Path "$($destinationroot)\expanded\bundle" -Recurse
            $ManifestAppxs = Get-ChildItem -Filter AppxManifest.xml -Path "$($destinationroot)\expanded\Appx\" -Recurse
            #region bundle manifest
            Write-Host "Settings the Bundle manifest in :`t $("$($destinationroot)\expanded\") !" -ForegroundColor Green
            if($($ManifestBundle.count)){
                foreach($Manifest in $ManifestBundle){
                    [xml]$manifestxml = Get-Content $Manifest.FullName
                    Set-Manifest -Mode Bundle -certificate $certificateSAN -filename $($Manifest.fullname)  -xmlfile $manifestxml | Out-Null
                }
            }else{
                [xml]$ManifestXML = Get-Content $ManifestBundle.FullName
                Set-Manifest -Mode Bundle -certificate $certificateSAN -filename $($ManifestBundle.fullname)  -xmlfile $ManifestXML | Out-Null
            }
            #endregion
            #region Appxs Manifests 
            Write-Host "Settings the Appx manifest in :`t $("$($destinationroot)\expanded\") !" -ForegroundColor Green
            if($($ManifestAppxs.count)){
                foreach($ManifestAppx in $ManifestAppxs){
                    [xml]$ManifestXML = Get-Content $ManifestAppx.FullName
                    Set-Manifest -Mode Manifest -certificate $certificateSAN -filename $($ManifestAppx.fullname)  -xmlfile $ManifestXML | Out-Null
                }
            }else{
                [xml]$manifestxml = Get-Content $ManifestAppx.FullName
                Set-Manifest -Mode Manifest -certificate $certificateSAN -filename $($ManifestAppx.fullname)  -xmlfile $ManifestXML | Out-Null
            }
            #endregion
        #endregion
        #region bundle BlockMaps
            $ManifestBundleBlockMaps = Get-ChildItem -Filter AppxBlockMap.xml -Path "$($destinationroot)\expanded\bundle" -Recurse
            $ManifestAppxBlockMaps = Get-ChildItem -Filter AppxBlockMap.xml -Path "$($destinationroot)\expanded\Appx\" -Recurse
            Write-Host "Settings the Bundle Block Maps in :`t $("$($destinationroot)\expanded\") !" -ForegroundColor Green
            if($($ManifestBundleBlockMaps.count)){
                foreach($BlockMaps in $ManifestBundleBlockMaps){
                    [xml]$BlockMapsXml = Get-Content $BlockMaps.FullName
                    Set-Manifest -Mode Block -certificate $certificateSAN -filename $($BlockMaps.fullname)  -xmlfile $BlockMapsXml | Out-Null
                }
            }else{
                [xml]$BlockMapsXML = Get-Content $BlockMaps.FullName
                Set-Manifest -Mode Block -certificate $certificateSAN -filename $($BlockMaps.fullname)  -xmlfile $BlockMapsXML | Out-Null
            }
            #endregion
            #region Appxs BlockMaps
            Write-Host "Settings the Appx Block Maps in :`t $("$($destinationroot)\expanded\") !" -ForegroundColor Green
            if($($ManifestAppxBlockMaps.count)){
                foreach($BlockMaps in $ManifestAppxBlockMaps){
                    [xml]$BlockMapsXml = Get-Content $BlockMaps.FullName
                    Set-Manifest -Mode BlockAppx -certificate $certificateSAN -filename $($BlockMaps.fullname)  -xmlfile $BlockMapsXML | Out-Null
                }
            }else{
                [xml]$BlockMapsXml = Get-Content $ManifestAppxBlockMaps.FullName
                Set-Manifest -Mode BlockAppx -certificate $certificateSAN -filename $($ManifestAppxBlockMaps.fullname)  -xmlfile $BlockMapsXml | Out-Null
            }
            #endregion
        #endregion
        #region packing appx
            Write-Host "Packing and Singin the Appxs in :`t $("$($destinationroot)\expanded\Appx") !" -ForegroundColor Green
            $AppxsExpanded = Get-ChildItem -Directory -Path "$($destinationroot)\expanded\Appx\"
            if($($AppxsExpanded.Count)){
                $x = 1
                foreach($AppxExpanded in $AppxsExpanded){
                        Write-Host "Packing the $($x) appx :`t $("$($destinationroot)\expanded\Appx") !" -ForegroundColor Green
                        Write-Host "Packing..." -ForegroundColor Yellow
                        makeappx pack /o /d $($AppxExpanded.fullname) /nv /p "$($destinationroot)\expanded\bundle\$($AppxExpanded.name).appx" *>>$logfile 
                        Write-Host "Signin..." -ForegroundColor Yellow
                        signtool.exe sign /fd sha256 /t $($certificatetimestampurl)  /f "$($certificatePath)" /p $($certificatepass) "$($destinationroot)\expanded\bundle\$($AppxExpanded.name).appx" *>>$logfile
                        $x = $x+1
                }
            }else{
             Write-Host "Packing the only one appx :`t $("$($destinationroot)\expanded\Appx") !" -ForegroundColor Green
                Write-Host "Packing..." -ForegroundColor Yellow
                makeappx pack /d $($AppxsExpanded.fullname) /nv /p "$($destinationroot)\expanded\bundle\$($AppxsExpanded.name).appx" *>>$logfile
                Write-Host "Signin..." -ForegroundColor Yellow
                signtool.exe sign /fd sha256 /t $($certificatetimestampurl)  /f "$($certificatePath)" /p $($certificatepass) "$($destinationroot)\expanded\bundle\$($AppxsExpanded.name).appx" *>>$logfile
            }
        #endregion
        #region Bundling
        Write-Host "Bundling and Singin the bundle :`t $("$($destinationroot)\expanded\bundle") !" -ForegroundColor Green
        Write-Host "Bundling..." -ForegroundColor Yellow
        makeappx bundle /v /d "$($destinationroot)\expanded\bundle"  /p "$($destinationroot)\$packagesourcename" *>>$logfile
        Write-Host "Singin..." -ForegroundColor Yellow
        signtool.exe sign /fd sha256 /t $($certificatetimestampurl)  /f "$($certificatePath)" /p $($certificatepass) "$($destinationroot)\$packagesourcename" *>>$logfile
        #endregion
        #region create Archives
        Write-Host "Creating the archives tree to $($destinationroot)\compress\" -ForegroundColor Green
        Copy-Item "$($packagesourcepath)\Dependencies" -Destination "$($destinationroot)\compress\Dependencies" -Recurse
        Copy-Item "$($destinationroot)\$packagesourcename" -Destination "$($destinationroot)\compress\"
        [string]$compresspath = "$($destinationroot)\compress\"
        $Dependencies = Get-ChildItem "$($destinationroot)\compress" -Filter *.appx* -Recurse
        $allfiles = $Dependencies |%{ $_.FullName.ToString().Replace([String]$compresspath,".\")  } 
        $powershellinstall = @"
            Add-AppxPackage -Path {0}
"@
        $tempappx1 = $tempappx2 = $tempappx3 = $null
        foreach($file in $allfiles){
            switch ($file)
            {
                {$_ -like "*Dependencies\*.appx" -and $_ -notlike "*Dependencies\*\*"} { [array]$tempappx1 += $_ }
                {$_ -like "*Dependencies\???\*.appx"} { [array]$tempappx2 += $_ }
                {$_ -like "*.appxbundle"} { [array]$tempappx3 += $_ }
            }
            }
           if(!$($tempappx1.Count)){
                [String]::Format($powershellinstall,$tempappx1) | Out-File -Encoding utf8 -FilePath "$($destinationroot)\compress\Setup.ps1"
           }
           else{
                Foreach($tempappx in $tempappx1){
                     [String]::Format($powershellinstall,$tempappx) | Out-File -Encoding utf8 -FilePath "$($destinationroot)\compress\Setup.ps1" -Append
                }
           }
           if(!$($tempappx2.Count)){
           [String]::Format($powershellinstall,$tempappx2) | Out-File -Encoding utf8 -FilePath "$($destinationroot)\compress\Setup.ps1" -Append
           }
           else{
                Foreach($tempappx in $tempappx2){
                     [String]::Format($powershellinstall,$tempappx) | Out-File -Encoding utf8 -FilePath "$($destinationroot)\compress\Setup.ps1" -Append
                }
           }
           if(!$($tempappx3.Count)){
           [String]::Format($powershellinstall,$tempappx3) | Out-File -Encoding utf8 -FilePath "$($destinationroot)\compress\Setup.ps1" -Append
           }
           else{
            Foreach($tempappx in $tempappx3){
                 [String]::Format($powershellinstall,$tempappx) | Out-File -Encoding utf8 -FilePath "$($destinationroot)\compress\Setup.ps1" -Append
                 }
           }
           & 'C:\Program Files (x86)\7-Zip\7z.exe' a -t7z -mx9 $($packagesourcename -replace ".appxbundle",".7z") "$($destinationroot)\compress\*" -r
            
    }
    end
    {
        Write-Host "The bundle has been updated sucessfully in :`t $("$($destinationroot)\$packagesourcename") !" -ForegroundColor Green
        Write-Host "The logs of makeappx and signtool are here :`t $($logfile)" -ForegroundColor Green
    }
}
#region Functions
Function Set-Manifest {
param(
    [String]
    [ValidateSet("Bundle","Block","Manifest","BlockAppx")]
    $Mode,
    [XML]
    $xmlfile,
    [String]
    $CertificateSAN,
    [String]
    $filename,
    [String]
    $BlockMap
)

switch ($Mode)
{
    'Bundle' 
    {
    $xmlfile.Bundle.Identity.Publisher = $CertificateSAN
    $xmlfile.Save($filename) 
    }
    'Block' 
    {
    $xmlfile.BlockMap.File.RemoveAttribute("Size")
    $xmlfile.BlockMap.File.RemoveAttribute("LfhSize")
    $xmlfile.BlockMap.File.RemoveChild($xmlfile.BlockMap.File.Block)
    $xmlfile.Save($filename)
    }
    'Manifest' 
    {
    $xmlfile.Package.Identity.Publisher = $CertificateSAN
    $xmlfile.Save($filename) 
    }
    'BlockAppx' 
    {
    $xmltemp = $xmlfile.BlockMap.File |? { $_.Name -eq "AppxManifest.xml"}
    $xmlfile.BlockMap.RemoveChild($xmltemp)
    $xmltemp.RemoveChild($xmltemp.Block)
    $xmltemp.RemoveAttribute("Size")
    $xmltemp.RemoveAttribute("LfhSize")
    $xmlfile.BlockMap.AppendChild($xmltemp) 
    $xmlfile.Save($filename) 
    }
}
}
#endregion


Function Get-7zipSFXTools
{
    param(
    [String]
    $url = "http://7zsfx.info/files/7zsd_tools_150_2712.exe",
    [String]
    $installpath = "$($PWD)/7zsd_tools_150_2712.exe"
    )
    Begin
    {
        if(!$(Test-Connection $url -Count 2 -Quiet)){
           Write-Host "Couldn't Connect to 7zsfx.info" -ForegroundColor Red
           break;
        }
    }
    process
    {
        $WebClient = New-Object -TypeName System.Net.WebClient
        $WebClient.DownloadFile($url,$installpath)
        ./$installpath
    }
    end
    {
         Write-Host "SFX Tools Installed !" -ForegroundColor Green
    }
}



