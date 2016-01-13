Workflow Get-AdServerUpdate
{
$adservers = Get-ADComputer -Filter { operatingsystem -like "*Server*" -and enabled -eq $true} 

foreach -parallel ($adserver in $adservers)
{
    Get-WindowsUpdate -computername $adserver.name
}
}
 

Function Get-WindowsUpdate
{
    param(
        $computername
    )
    $sendto = @("Powershell <edeneuve@xxx>")
    $subject = @"
Mise a jour de {0} a faire !
"@
$body = 
@"
Il y a des mise a jours sur {0} :`n
"@
    #try{
        #Write-Host "Checking $($computername)" -foreground yellow
     #   if(Test-Connection $computername -quiet -Count 1){
        $UpdateSession = Invoke-Command -ComputerName  $computername  -scriptblock {
            $UpdateSession = New-Object -ComObject 'Microsoft.Update.Session';
            $UpdateSession.ClientApplicationID = 'Install Windows Updates via PowerShell';
            $ReBootRequired = $false;
            $UpdateSearcher = $UpdateSession.CreateUpdateSearcher();
            $SearchQuery = "IsInstalled=0 and Type='Software'";
            $SearchResult = $UpdateSearcher.Search($SearchQuery);
                ForEach ($Update in $SearchResult.Updates) {
                    New-Object -TypeName PSObject -Property @{
                        Title = $Update.Title; Description = $Update.Description; SupportUrl = $Update.SupportUrl; 
                        UninstallationNotes = $Update.UninstallationNotes; RebootRequired = $Update.RebootRequired
                    }
                }
            } 
      #   }else{
       #     Write-Host "$($computername) is offline?" -foreground red
        #    }
    #}
    #catch
    #{
    #    Write-Error "Access Denied !"        
    #} 
        if($UpdateSession.Count -or $UpdateSession -ne $null){
            foreach($update in $UpdateSession){
                $body += "`n`t" + $($update.Title)
            }
            $body += "`n`t Pensez a les faire !"
            $sendsub = [String]::Format($subject,$computername)
            $sendbody = [String]::Format($body,$computername)
            Send-MailMessage -From edeneuve@xxx.com  -Encoding UTF8  -SmtpServer xxx -Port 25 -To $sendto -Subject $sendsub -Body $sendbody
            }
            else{
            $body += "`n`t C'est bien ! !"
            $sendsub = [String]::Format($subject,$computername)
            $sendbody = [String]::Format($body,$computername)
            Send-MailMessage -From edeneuve@xxx.com  -Encoding UTF8  -SmtpServer xxx -Port 25 -To $sendto -Subject $sendsub -Body $sendbody
            }
}
