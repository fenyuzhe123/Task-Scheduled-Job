$window = $host.UI.RawUI
$size = $window.BufferSize
$size.Height = 3000
$size.Width = 200
$window.BufferSize = $size
(Get-Host).UI.RawUI.BufferSize | Format-List


# Find and execute VMwarePowerCLI initialization
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.VimAutomation.Vds
$PowerCLIInitScript = "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
$existsPowerCLIInitScript = Test-Path $PowerCLIInitScript
if($existsPowerCLIInitScript) {
   & $PowerCLIInitScript
}
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -DefaultVIServerMode multiple -Confirm:$false

#vCenters
$vcwcdc = "vcwest.active.tan"
$vcecdc = "vceast.active.tan"
$vccadc = "vcnorth.active.tan"
$vcbcdc = "vcnorthdr.active.tan"
$vcxadc = "xavc01.active.tan"

$vcprod = @($vcwcdc,$vcecdc,$vccadc,$vcbcdc,$vcxadc)
$user = "TAN\vmadmin"
$password = cat D:\schedule_jobs\Creation\securestring.txt | convertto-securestring
$cred1 = new-object -typename System.Management.Automation.PSCredential -argumentlist $user, $password
Connect-VIServer $vcprod -Credential $cred1


$VIEvent = Get-VIEvent -maxsamples 10000 -Start (get-date).AddDays(-10)
$OutputCreatedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmCreateEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent"} | Select createdTime, UserName, fullFormattedMessage )



$smtpServer = "lassmtpint01.active.local" 
$mailfrom = "soi_admins@activenetwork.com"


function Find-User ($username){
   if ($username -ne $null)
   {
      $usr = (($username.split("\"))[1])
      $root = [ADSI]""
      $filter = ("(&(objectCategory=user)(samAccountName=$Usr))")
      $ds = new-object system.DirectoryServices.DirectorySearcher($root,$filter)
      $ds.PageSize = 1000
      $ds.FindOne()
   }
}


$mailuser= $OutputCreatedVMs|select username
$namelist=''
foreach($name in $mailuser)
{$mail_user =  Find-User $name.username
 $mailto = (($mail_user.Properties.cn -replace (" ","."))|Out-String).ToString().Trim()
$namelist+=$mailto+','
}

$namelist

  
