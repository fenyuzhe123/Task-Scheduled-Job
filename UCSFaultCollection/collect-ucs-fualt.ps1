#import UCS mode
Import-Module CiscoUCSps
set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $true
# Define UCS connection details
$ucsSysName = "10.107.121.13"
$ucsSysName1 = "uslas-c6296fi-01.active.tan"
$ucsSysName2 = "uslas-c6296fi-02.active.tan"
$ucsSysName3 = "uslas-c6296fi-03.active.tan"
#$ucsSysName4 = "uslas-c6120fi-04.active.tan"
$ucsSysName5 = "usash-c6296fi-01.active.tan"
$ucsSysName6 = "cator-c6296fi-01.active.tan"
$ucsSysName7 = "cakel-c6248fi-01.active.tan"

$ucsUserName = "ucs-TAN\svc.ucsbackup"
$ucsPassword = cat D:\schedule_jobs\UCSInventoryGet\keys\secure.key | convertto-securestring

#connect to UCS 
#$ucsPassword = ConvertTo-SecureString -String $ucsPassword -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $ucsUserName, $ucsPassword
# Create connection to UCS system
$ucsConnection = Connect-Ucs $ucsSysName  -Credential $cred
$ucsConnection = Connect-Ucs $ucsSysName1 -Credential $cred
$ucsConnection = Connect-Ucs $ucsSysName2 -Credential $cred
$ucsConnection = Connect-Ucs $ucsSysName3 -Credential $cred
#$ucsConnection = Connect-Ucs $ucsSysName4 -Credential $cred
$ucsConnection = Connect-Ucs $ucsSysName5 -Credential $cred
$ucsConnection = Connect-Ucs $ucsSysName6 -Credential $cred
$ucsConnection = Connect-Ucs $ucsSysName7 -Credential $cred

$UCS_infos = Get-UcsFault | Where-Object { ($_.Severity -ne 'cleared') -and ($_.Ack -ne 'yes') -and ($_.Severity  -notmatch 'info')} | sort Ucs,lasttransition -Descending | select Ucs,lasttransition,severity,status,type,dn,descr
$FI_Report = @()
foreach ($UCS_item in $UCS_infos)
{
$UCS_info = ""|select Ucs,lasttransition,severity,status,type,dn,descr
$UCS_info.Ucs = $UCS_item.ucs
$UCS_info.lasttransition = $UCS_item.lasttransition
$UCS_info.severity = $UCS_item.severity
$UCS_info.status =$UCS_item.status
$UCS_info.type = $UCS_item.type
$UCS_info.dn = $UCS_item.dn
$UCS_info.descr = $UCS_item.descr
Write-Host $UCS_info.Ucs","$UCS_info.lasttransition","$UCS_info.severity","$UCS_info.status","$UCS_info.type","$UCS_info.dn","$UCS_info.descr
$FI_Report = $FI_Report + $UCS_info
}

$Filename = "D:\schedule_jobs\UCSFaultCollection\output\ucs-faults.csv"

Disconnect-Ucs

$FI_Report | Export-Csv -NoTypeInformation $Filename




#Mail information 
$time= date

$EmailFrom = "soi_admins@activenetwork.com"
$EmailTo = "soi_admins@activenetwork.com","monitalert@activenetwork.com"
#$EmailTo ="Shayne.niu@activenetwork.com"
$EmailSubject = (get-date -Format yyyy/MM/dd)+ ' syslog information of Prod UCS FI ' 
$EmailSmtp = "lassmtpint01.active.local"
#Send Mail to mail group
if ($Filename)
	{
echo "Prepare for sending mail"
Send-MailMessage -To $EmailTo -From $EmailFrom -SmtpServer $EmailSmtp -Subject  $EmailSubject  -Body " $time syslog information of Prod UCS FI " -Attachments $Filename
echo "mail has been send out, please wait"
	}
else{
echo "Attchment can not be found or mail porcess fail"
}
#Remove the old file
#Remove-Item $Filename -Force
