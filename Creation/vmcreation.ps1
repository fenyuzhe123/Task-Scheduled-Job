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


$VIEvent = Get-VIEvent -maxsamples 30000 -Start (get-date).AddDays(-1)
$OutputCreatedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent"} | Select createdTime, UserName, fullFormattedMessage |Fl)
$Record=$OutputCreatedVMs|out-string
$OutputRemovedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmRemovedEvent"}| Select CreatedTime, UserName, fullFormattedMessage|Fl)
$Record1=$OutputRemovedVMs|out-string

$smtpServer = "lassmtpint01.active.local" 
$mailfrom = "soi_admins@activenetwork.com"
$mailto = "cookies.zhang@activenetwork.com,mary.xu@activenetwork.com,Wesley.Fan@activenetwork.com,shayne.niu@activenetwork.com"

$MailText = @"
VM Create
--------------------------------------------------------------------------------------------------------------------------------------
$($Record)

VM Remove
--------------------------------------------------------------------------------------------------------------------------------------
$($Record1)
"@

  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($smtpServer) 
  $msg.From = $mailfrom
  $msg.To.Add($mailto) 
  $msg.Subject = "VM Create and Remove Record"
  $msg.Body = $MailText
  $smtp.Send($msg)
