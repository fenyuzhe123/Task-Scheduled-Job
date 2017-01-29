New-Item "keys" -ItemType directory -ea silentlycontinue
$secure = Read-Host "Enter Password" -asSecureString 
$bytes = ConvertFrom-SecureString $secure 
$bytes | Out-File keys\secure.key