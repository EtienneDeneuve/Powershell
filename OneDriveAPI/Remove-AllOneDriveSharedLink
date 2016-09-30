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
        Invoke-RestMethod -Method Delete -uri "https://api.onedrive.com/v1.0/drive/items/$($item.id)/permissions/$($permission.id)?access_token=EwAgA61DBAAUGCCXc8wU/zFu9QnLdZXy+YnElFkAAT63WBtn+x0QhCKgJxN/C2By2rHAgl0WvFvVv+DbPjjfQqdeWUKr4zgNnF/mgN+63ogKWhDWehYQ+/7slLRWY7MwZTOjzGsBQ/uS0L7onOp3nywbGOcj93hrz0GZJ6QZJ+dgvljDGIGKskHsOMq4TIjl7ntKG08TX5B8oubGxUmEMIfDq+wMGF18LoLgQz4QLuhEW0AGRKNVVvL7dbKGTjCM0zKMLzaHW8quIHInVU/pCcLQSHtQk8yXVTD26bxBnjIRORgqgMPRezd9T3bybjlDGPbNE7qxnoxDD+LuxU46uY2oCxosSWRaKLbB8p/wqcc4kVjBOnvxJ75tH9CQRJoDZgAACJVsWViSac5W8AEJl1gzDqDCQVKz3rDsdngfwkQalGVn4M7VQuSfeoJJo7eH0UtDTo7QYg4uygsee2peKEB1cAALS+6GFNdusGnERgE6hveAqbEAWntr0/k4MCTFPKQnBs1j4BvChJvvfGXGl6D4/7+Wr/nIbwO17xr2jyJrDOSuqek+llGmY5dbZ5BL49EX+UfnWAfm4XV6Gi0RsGuwduDA9YVdDV4w5kWf8yg3lw2HbXOCRIwDiuvpfpFVUty1jdAhaGAmb7FuvoIav+r8g1CELZVsADUDPHOXjKko0oTxIT3iZVua7wneJZUqmrS1vO6g2HufBD1PkmV04CdOpF6MXrZF/WdxD1Lz+Aiq+ecNp0j8nmi4WP5W5KniJP+h/W6c4Tpi6X3Y4XywAg20m15V42OMzIuz4mckQm8sBFeQ/aWGHUKA0qaqHLJhR7Q32Gw+ZV0vBW8LSgR7hcLZz/kBzJ135/aNlkg3ZYdWMOvFrTKVLSV3DLfZgqXlzJNPA6g+X+oK4YfDMsxXRAOChW7vUUFxei1TngV020Qmc+sR4JpNF/ZQOHGrl5qK/wZrEEd3m6lW9xaiP1xXYDKtcq3alb2Tsm53tpEr1Zy1+N/rRCMdMb1tBUYZaCuIcVpujS4YAy8hcrTV4qS88z1U4GTuoYc47t9ql7dsCAI="
    }
}
