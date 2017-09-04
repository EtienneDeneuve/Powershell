<#
.SYNOPSIS
    This cmdlet will get a key from your palo alto to use with other cmdlets.
.DESCRIPTION
    This cmdlet will get a key from your palo alto to use with other cmdlets.
.EXAMPLE
    PS C:\> Get-PaloaltoKey -PaloAltoIp 192.168.1.254 -IngnoreSSL -login xml -Verbose
    password: *******
    [Verbose] PaloAlto on 192.168.1.254 give us the XXXX
.NOTES
    This script is under MIT License. It's a series of script to get config of your PaloAlto
    In Azure.
    Made by Etienne Deneuve from Cellenza. etienne[at]deneuve.xyz
#>
function Get-PaloaltoKey {
    param(
        [string]
        $login,
        $password,
        [ValidateScript( {$_ -match [IPAddress]$_ })]  
        [string]
        $PaloAltoIp,
        [switch]
        $IngnoreSSL
    )
        if ($IngnoreSSL) {
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }
    $baseurl = "https://{0}/api/{1}"
    $firewallurl = "?type=keygen&user={0}&password={1}"
    $response = Invoke-RestMethod -Uri $([string]::Format($baseurl, $PaloAltoIp, ([string]::Format($firewallurl , $login, $password)))) 
    $key = $response.ChildNodes.result.key

    Write-Debug $response
        $response = $null
    Write-Verbose "PaloAlto on $PaloAltoIp give us the $key"
    New-Variable -Name PaloAltoIP -Scope Global -Value $PaloAltoIp -Force
    New-Variable -Name PaloAltoKey -Scope Global -Value $key -Force
}

<#
.SYNOPSIS
    This cmdlet will get the config of your palo alto.
.DESCRIPTION
    You need get a key from your palo alto to use from the Get-PaloAltoKey.
    This cmdlet will get the config of your palo alto.
.EXAMPLE
    PS C:\> Get-PaloAltoConfig -mode Full
  //TODO Add sample for Full Mode
    PS C:\> Get-PaloAltoConfig -mode Address
  //TODO Add sample for Address Mode
    PS C:\> Get-PaloAltoConfig -mode Address-Group
  //TODO Add sample for Address-Group Mode
.NOTES
    This script is under MIT License. It's a series of script to get config of your PaloAlto
    In Azure.
    Made by Etienne Deneuve from Cellenza. etienne[at]deneuve.xyz
#>
Function Get-PaloAltoConfig {
    param(
        [ValidateSet("Full", "Address", "Address-Group")]
        [string]
        $Mode = "Full"
    )
    if(!$($PaloAltoKey -or $PaloAltoIp)){ Write-Host "You aren't connected on a PaloAlto appliance, please run Get-PaloAltoKey"; break; }
    $baseurl = "https://{0}/api/{1}&key={2}"
    $exportconfig = '?type=export&category=configuration'
    $responseconfig = Invoke-RestMethod -Uri $([string]::Format($baseurl, $PaloAltoIp, $exportconfig, $PaloAltoKey))
    $ObjectResponse = $null
    switch ($mode) {
        {$mode -eq "Full"} { $ObjectResponse = $(Select-XML -Xml $responseconfig -XPath "/config" | Select -ExpandProperty Node) }
        {$mode -eq "Address"} { $ObjectResponse = $responseconfig.config.devices.entry.vsys.entry.address.entry }
        {$mode -eq "Address-Group"} {  $ObjectResponse =  $responseconfig.config.devices.entry.vsys.entry.'address-group'.entry }
        Default { $ObjectResponse = $responseconfig.config}
    }
    return $ObjectResponse
}

<#
.SYNOPSIS
    This cmdlet will get the system info of your palo alto.
.DESCRIPTION
    You need get a key from your palo alto to use from the Get-PaloAltoKey.
    This cmdlet will get the system info of your palo alto.
.EXAMPLE
    PS C:\> Get-PaloAltoSystemInfo
  //TODO Add sample
.NOTES
    This script is under MIT License. It's a series of script to get config of your PaloAlto
    In Azure.
    Made by Etienne Deneuve from Cellenza. etienne[at]deneuve.xyz
#>
Function Get-PaloAltoSystemInfo {
    $baseurl = "https://{0}/api/{1}&key={2}"
    $operationsystem = '?type=op&cmd=<show><system><info></info></system></show>'
    $response = Invoke-RestMethod -Uri $([string]::Format($baseurl, $PaloAltoIp, $operationsystem, $PaloAltoKey)) 
    return $response.response.result.system
}
