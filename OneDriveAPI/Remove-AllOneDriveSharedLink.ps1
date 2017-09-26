$baseurl = "https://api.onedrive.com/v1.0/{0}?access_token={1}"
#get your token here : https://dev.onedrive.com/auth/msa_oauth.htm (Look for "try it now section")
$accesstoken = "YOUR TOKEN HERE AFTER THE WORD Authorization: bearer"
$liveurl = [string]::Format($baseurl,"drive/shared",$accesstoken)
$shareditems = Invoke-RestMethod -Uri $liveurl
foreach($item in $shareditems.value){
    Write-Host "Processing :`t$($item.name)`twith the following id :`t$($item.id)"
    $permissions = Invoke-RestMethod -uri $([string]::Format($baseurl,$("drive/items/$($item.id)/permissions"),$accesstoken))
    foreach($permission in $permissions.value){
        Write-Host "`tRemove Permissions on this URL :`t`thttps://1drv.ms/f/$($permission.shareId) "
        Invoke-RestMethod -Method Delete -uri "https://api.onedrive.com/v1.0/drive/items/$($item.id)/permissions/$($permission.id)?access_token=="
    }
}
