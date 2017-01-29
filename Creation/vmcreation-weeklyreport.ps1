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


$VIEvent = Get-VIEvent -maxsamples 100000 -Start (get-date).AddDays(-7)
$OutputCreatedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent"} | Select createdTime, UserName, fullFormattedMessage)

$OutputRemovedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmRemovedEvent" -and $_.username -ne "User"}| Select CreatedTime, UserName, fullFormattedMessage)

$All = @($VIEvent | where {$_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent" -or $_.Gettype().Name -eq "VmRemovedEvent" -and $_.username -ne "User"} | Select createdTime, UserName, fullFormattedMessage)




$Date = Get-Date -Format "yyyy-MM-dd-HH-mm"

$File_Name = "VM Create and Remove weekly report-" + $Date.ToString() + ".xlsx"  
  
$OutputCreatedVMs |sort -descending Createdtime | Export-excel -workSheetName "creation" -Path D:\schedule_jobs\Creation\output\"$File_Name"
$OutputRemovedVMs |sort -descending Createdtime | Export-excel -workSheetName "deletion" -Path D:\schedule_jobs\Creation\output\"$File_Name"
$All |sort -descending Createdtime | Export-excel -workSheetName "all" -Path D:\schedule_jobs\Creation\output\"$File_Name"
$File = "D:\schedule_jobs\Creation\output\"+"$File_Name"





#Mail information 

$EmailFrom = "soi_admins@activenetwork.com"
$EmailTo = "cookies.zhang@activenetwork.com","paul.hu@activenetwork.com","wesley.fan@activenetwork.com","shayne.niu@activenetwork.com"

$EmailSubject = ' VM Create and Remove weekly report ' +(get-date -Format yyyy/MM/dd)
$EmailSmtp = "lassmtpint01.active.local"
#Send Mail to mail group
if ($File)
	{
echo "Prepare for sending mail "
Send-MailMessage -To $EmailTo -From $EmailFrom -SmtpServer $EmailSmtp -Subject  $EmailSubject  -Body " VM Create and Remove weekly report $Date " -Attachments $File
echo "mail has been send out, please wait"
	}
else{
echo "Attchment can not be found or mail porcess fail"
}