<#
    .SYNOPSIS
        Create a Set of new empty GPO in a domain from parameters
    .DESCRIPTION
        Create a fullset of GPO from a bunch of parameters
    .EXAMPLE
        PS C:\> New-GpoSet -domain $env:userdnsdomain -gpoprefix "XXX_" -gpolist @("Firewall Enable";"Firewall IIS")
        This command will add new GPO 
    .NOTES
        This commandlet have been created by Etienne Deneuve from Cellenza
        You can also lookup for other *GPO* commandlets
    #>
function New-GpoSet {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        $gpolist = @("Firewall Enable"; "Firewall Base"; "Firewall IPSec"; "Firewall IIS"; "Firewall SMTP"; "Firewall SQL"; "Firewall Message Queuing"; "Firewall Temoin"; "Firewall WSUS"),
        $domain = $env:USERDNSDOMAIN,
        $GPOPrefix = "XXX_"
    )
    Write-Verbose "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")GPOList is: $gpolist"
    Write-Verbose "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")Domain is $domain"
    $comment = @"
    This GPO is one of the following list :`n $(
    foreach($gpo in $gpolist){    
    "`t`t{0}`n" -f  "$GPOPrefix$gpo"
    })
"@
    Write-Verbose "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")$comment"
    foreach ($gpo in $gpolist) {
        $gponame = "$GPOPrefix$gpo"
        if (!$(Get-GPO -Name $gponame -ErrorAction SilentlyContinue)) {
            New-GPO -Name $gponame -Comment $comment -Domain $domain 
            Write-Verbose "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Create GPO]`t$gponame created"
        }
        else {
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Create GPO]`t$gponame exists"
        }
    }
}
    
<#
  .SYNOPSIS
      Add new Firewall Rule in the passed GPOSession
  .DESCRIPTION
      Add new Firewall Rule in the passed GPOSession. You must get a GPOSession from `
        $GPOSession = Open-NetGPO -PolicyStore "$($domain)\$GPOName" 
        and after adding a net-firewall rule, you need to 
        Save-NetGPO -GPOSession $GPOSession
  .EXAMPLE
      PS C:\> Add-NetFirewallRuleGPO  -RuleName "Firewall Server" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 80 -Action allow -GPOSession $GPOSession
      This command will add a new firewall rule in the GPO
  .NOTES
      This commandlet have been created by Etienne Deneuve
      You can also lookup for Add-GPONetFirewallRule and other GPO* commandlets
#>
function Add-NetFirewallRuleGPO {
    [CmdletBinding()]
    param(
        $RuleName,
        $Direction,
        $Protocol,
        $LocalPort,
        $Action = "Allow",
        $Program = $null,
        $Service = $null,
        $IcmpType = $null,
        $Source = $null,
        $GPOSession

    )
 
    try {
        $gpo = Get-NetFirewallRule  -DisplayName $RuleName -GPOSession $GPOSession -ErrorAction Stop 
        Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t" $gpo.DisplayName  -ForegroundColor Green
    }
    catch [System.Management.Automation.RuntimeException] {
        Write-Verbose "Rule not found"
        if ($program -ne $null) { 
            $gpo = New-NetFirewallRule -DisplayName $($RuleName) `
                -Direction $($Direction) -Protocol $($Protocol) `
                -LocalPort $($LocalPort) -Action $($Action) `
                -Program $($program)  -GPOSession $($GPOSession) 
            $RuleName = $Direction = $Protocol = $LocalPort = $Action = $Program = $Service = $GPOSession = $null
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t"+ $gpo.DisplayName -ForegroundColor Yellow
 
        }
        elseif ($Service -ne $null) {
            $gpo = New-NetFirewallRule -DisplayName $($RuleName) `
                -Direction $($Direction) -Protocol $($Protocol) `
                -LocalPort $($LocalPort) -Action $($Action) `
                -Service $($Service)  -GPOSession $($GPOSession) 
            $RuleName = $Direction = $Protocol = $LocalPort = $Action = $Program = $Service = $GPOSession = $null
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t"+ $gpo.DisplayName -ForegroundColor Yellow
        }
        elseif ($program -ne $null -and $Service -ne $null) {
            $gpo = New-NetFirewallRule -DisplayName $($RuleName) `
                -Direction $($Direction) -Protocol $($Protocol) `
                -LocalPort $($LocalPort) -Action $($Action) `
                -Program $($program) -Service $($Service)  -GPOSession $($GPOSession)
            $RuleName = $Direction = $Protocol = $LocalPort = $Action = $Program = $Service = $GPOSession = $null
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t"+ $gpo.DisplayName -ForegroundColor Yellow
        }
        elseif ($IcmpType -ne $null) {
            $gpo = New-NetFirewallRule -DisplayName $($RuleName) `
                -Direction $($Direction) -Protocol $($Protocol) `
                -LocalPort $($LocalPort) -Action $($Action) `
                -IcmpType $($IcmpType)`
                -GPOSession $($GPOSession) 
            $RuleName = $Direction = $Protocol = $LocalPort = $Action = $Program = $Service = $GPOSession = $null
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t"+ $gpo.DisplayName -ForegroundColor Yellow
        }
                  elseif ($Source -ne $null) {
            $gpo = New-NetFirewallRule -DisplayName $($RuleName) `
                -Direction $($Direction) -Protocol $($Protocol) `
                -LocalPort $($LocalPort) -Action $($Action) `
                -IcmpType $($IcmpType) -RemoteAddress $($Source) `
                -GPOSession $($GPOSession) 
            $RuleName = $Direction = $Protocol = $LocalPort = $Action = $Program = $Service = $GPOSession = $null
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t"+ $gpo.DisplayName -ForegroundColor Yellow
        }
        else {
            $gpo = New-NetFirewallRule -DisplayName $($RuleName) -Direction $($Direction) `
                -Protocol $($Protocol) -LocalPort $($LocalPort) -Action $($Action) `
                -GPOSession $($GPOSession) 
            $RuleName = $Direction = $Protocol = $LocalPort = $Action = $Program = $Service = $GPOSession = $null
            Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add Rule]`t`t"+ $gpo.DisplayName -ForegroundColor Yellow
        }
    }
}


<#
    .SYNOPSIS
        Set Firewall GPO for SQL, IIS, SMTP, Message Queuing, Base, Enable, IPSec
    .DESCRIPTION
        Create a fullset of GPO for smooth enabling IpSec transports mode
    .EXAMPLE
        PS C:\> Set-GPONetFirewallRules -link -OuRootPath "OU=Server,OU=XXX,DC=contoso,DC=local"  `
            
        This command will set firewall rule in the GPO
    .NOTES
        This commandlet have been created by Etienne Deneuve from Cellenza
        You can also lookup for other *GPO* commandlets
    #>
Function Set-GPONetFirewallRules {
    [CmdletBinding()]  
    param(
        $domain = $env:USERDNSDOMAIN,
        $GPOPrefix = "XXX_",
        $modes = @("SQL"; "IIS"; "SMTP"; "Message Queuing"; "Base"; "Enable"; "IPSec"; "WSUS")
    )

    foreach ($mode in $modes) {
        switch ($mode) {
            'SQL' {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
    
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Server" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 1433 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName AlwaysOn Agent" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 5022 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Admin Connection" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 1434 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Database Management" `
                    -Direction Inbound -Protocol UDP `
                    -LocalPort 1434 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Service Broker" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 4022 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Debugger/RPC" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 135 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Analysis Services" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 2383 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Browser" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 2382 -Action allow -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Azure ILB" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 59999 -Source 168.63.129.16 `
                    -Action allow -GPOSession $GPOSession
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "IIS" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Add-NetFirewallRuleGPO -RuleName  "$GPOName WWW Services" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 80 `
                    -Program "System" `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName WWW Secure Services" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 443 `
                    -Program "System" `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName WWW Management Service" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 8172 `
                    -Program "System" `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO  -RuleName "$GPOName Azure ILB" `
                    -Direction Inbound -Protocol TCP `
                    -LocalPort 59999 -Source 168.63.129.16 `
                    -Action allow -GPOSession $GPOSession
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "WSUS" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Add-NetFirewallRuleGPO -RuleName  "$GPOName WSUS" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 8530 `
                    -Program "System" `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName WSUS Report" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 8531 `
                    -Program "System" `
                    -GPOSession $GPOSession
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "SMTP" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Add-NetFirewallRuleGPO -RuleName "$GPOName Simple Mail Transfer Protocol" `
                    -Protocol TCP `
                    -LocalPort 25 `
                    -Direction Inbound `
                    -GPOSession $GPOSession `
                    -Program "%windir%\system32\inetsrv\inetinfo.exe" `
                    -Service "smtpsvc"
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "Message Queuing" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Add-NetFirewallRuleGPO -RuleName  "$GPOName Message Queuing TCP Inbound"  `
                    -Program "%systemroot%\system32\mqsvc.exe" `
                    -Direction Inbound `
                    -LocalPort Any `
                    -Protocol TCP `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName Message Queuing TCP Outbound" `
                    -Program "%systemroot%\system32\mqsvc.exe" `
                    -Direction OutBound `
                    -LocalPort Any `
                    -Protocol TCP `
                    -GPOSession $GPOSession 
                Add-NetFirewallRuleGPO -RuleName  "$GPOName Message Queuing UDP Inbound" `
                    -Program "%systemroot%\system32\mqsvc.exe" `
                    -Direction Inbound `
                    -LocalPort Any `
                    -Protocol UDP `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName Message Queuing UDP Outbound" `
                    -Program "%systemroot%\system32\mqsvc.exe" `
                    -Direction OutBound `
                    -LocalPort Any `
                    -Protocol UDP `
                    -GPOSession $GPOSession
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "Base" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $GPONAME = "XXX_Firewall Base"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Add-NetFirewallRuleGPO -RuleName  "$GPOName SMB-IN"  `
                    -Program "system" `
                    -Direction Inbound `
                    -LocalPort 445 `
                    -Protocol TCP `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName Echo-in"  `
                    -Direction Inbound `
                    -LocalPort Any `
                    -Protocol ICMPv4 `
                    -IcmpType 8 `
                    -GPOSession $GPOSession
                Add-NetFirewallRuleGPO -RuleName  "$GPOName Win-RM"  `
                    -Program "system" `
                    -Direction Inbound `
                    -LocalPort 5985 `
                    -Protocol TCP `
                    -GPOSession $GPOSession
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "Enable" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                Set-NetFirewallProfile -DefaultInboundAction Block `
                    -Enabled True `
                    -DefaultOutboundAction Allow `
                    -NotifyOnListen True `
                    -AllowUnicastResponseToMulticast True `
                    -LogBlocked True `
                    -LogMaxSizeKilobytes 4096 `
                    -LogFileName %SystemRoot%\System32\LogFiles\Firewall\pfirewall.log `
                    -GPOSession $GPOSession
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $null
            }
            "IPSec" {
                $GPOSession = $GPOName = $policystore = $null
                $GPOName = "$($GPOPrefix)Firewall $mode"
                $policystore = "$($domain)\$GPOName"
                $GPOSession = Open-NetGPO -PolicyStore $policystore
                $AHandESPQM = New-NetIPsecQuickModeCryptoProposal -Encapsulation AH, ESP `
                    -AHHash SHA256 `
                    -ESPHash SHA256 `
                    -Encryption AES256
                $QMCryptoSet = New-NetIPsecQuickModeCryptoSet -DisplayName "ah:SHA256+esp:SHA256-AES256" `
                    -Proposal $AHandESPQM `
                    -GPOSession $GPOSession
                try {
                    $ipsec = Get-NetIPsecRule -DisplayName "XXX_Ipsec Settings" -GPOSession $GPOSession -ErrorAction Stop
                    Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add IPSec]`t`t"$ipsec.DisplayName  -ForegroundColor Green
                }
                catch [System.Management.Automation.RuntimeException] {
                    $ipsec = New-NetIPsecRule -DisplayName "XXX_Ipsec Settings" `
                        -InboundSecurity Request `
                        -OutboundSecurity Request `
                        -QuickModeCryptoSet $QMCryptoSet.Name `
                        -GPOSession $GPOSession
                    Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Add IPSec]`t`t"$ipsec.DisplayName  -ForegroundColor Yellow
                }
                Save-NetGPO -GPOSession $GPOSession
                $GPOSession = $GPOName = $policystore = $AHandESPQM = $QMCryptoSet = $null
            }
        }
    }
}

<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
function Set-GPOLink {
    [CmdletBinding()]  
    param(
        $filepath ,
        $OURootPath = "DC=contoso,DC=local"
    )
    $ServerScope = "OU=Server,OU=XXX," + $OURootPath
    $DCScope = "OU=Domain Controllers," + $OURootPath
    $IPSecScope = "OU=ipSec,OU={0}Server," + $ServerScope 

    $csv = Import-Csv -Path $filepath -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {
       
        foreach ($type in $($line."Scope".Split(','))) {
            if ($type -eq "DC") {
                Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Link GPO]`t`t$($line."Gpo Name")" -ForegroundColor Green
                New-GPLink -Name "$($line."Gpo Name")" -Target $DCScope -ErrorAction SilentlyContinue
            }
            elseif ($type -eq "Server") {
                Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Link GPO]`t`t$($line."Gpo Name")" -ForegroundColor Green
                New-GPLink -Name "$($line."Gpo Name")" -Target $ServerScope -ErrorAction SilentlyContinue 
            }
            else {
                Write-Host "$(get-date -f "[dd/MM/yyyy-HH:mm:ss]`t")`t[Link GPO]`t`t$($line."Gpo Name")" -ForegroundColor Green
                $TempScope = [string]::Format($IPSecScope, $type) 
                New-GPLink -Name "$($line."Gpo Name")" -Target $TempScope -ErrorAction SilentlyContinue 
            }
        }
    }
}

<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> Invoke-IPsec -filepath "c:\fichier.csv" -OURootPath "DC=contoso,DC=com"
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
function Invoke-IPsec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $filepath,
        [Parameter(Mandatory = $true)]
        $OURootPath,
        $domain = $env:USERDNSDOMAIN
    )
  
    Write-Verbose "Create blank GPO"
    New-GpoSet -domain $domain
    Write-Verbose "Create blank GPO => Done"
    Write-Verbose "Set Firewall Rules on blank GPO"
    Set-GPONetFirewallRules -domain $domain
    Write-Verbose "Set Firewall Rules on blank GPO => Done"
    Write-Verbose "Link GPO to the expected OU"
    Set-GPOLink -filepath $filepath -OURootPath $OURootPath
    Write-Verbose "Link GPO to the expected OU => Done"
}


Clear-Host
Invoke-IPsec -filepath Base-GpoLink.csv -OURootPath "DC=contoso,DC=local"
