# to make the script change some stuff in your env, set the $debug as $false
# otherwise, nothing will be changed ;)
<#

  Launch the script one time in debug before set it to false !

#> 
$debug = $true
$users = Get-ADUser -filter * -Properties mail,ProxyAddresses
foreach($users in $user){
    $wrong = $false
    # some account don't have valid upn, as they are admin, guest or krb (system account)
    # You can also change the UPN to have something like 
    #   $upn = "$($user.samaccountname)@yournicedomain.com"
    # in this case, you need to also change the mail attribute
    if($($user.UserPrincipalName) -ne $null) {
        $upn = $user.UserPrincipalName
    }else{
        Write-Host "$($user.name) don't have any UPN" -ForegroundColor Yellow
        $wrong = $true
    }
    # if the account is valid (with a good upn)
    if($wrong = $false){
        # set the principal SMTP with the concatenate of SMTP: and the UPN 
        #(if your UPN suffix is the same as your office 365 account)
        $proxyaddresses = "SMTP:$($upn)"
        # set the user instance with the new ProxyAddress
        $user.ProxyAddresses = $proxyaddresses 
        # if you use the $upn = "$($user.samaccountname)@yournicedomain.com" uncomment :
        # $user.mail = "$($user.samaccountname)@yournicedomain.com"
        if($debug -eq $true){
            Write-Host "changing the proxyAddresses" -ForegroundColor Red
            Write-Host "$($user.ProxyAddresses)"
            Write-Host "$($user.mail)"
        }else{ 
            #test avant puis change la variable $debug 
            Set-ADUser -instance $user -whatif
        }
    }
}
