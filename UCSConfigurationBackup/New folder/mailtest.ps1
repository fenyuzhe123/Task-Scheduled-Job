#Mail information
$time= date

$EmailFrom = "soi_admins@activenetwork.com"

$EmailTo ="soi_admins@activenetwork.com"

$EmailSubject = (get-date -Format yyyy/MM/dd)+'  UCS Configuration Backup'

$EmailSmtp = "lassmtpint01.active.local"

#Send Mail to mail group

if (1)

         {

echo "Prepare for sending mail "

Send-MailMessage -To $EmailTo -From $EmailFrom -SmtpServer $EmailSmtp -Subject  $EmailSubject  -Body " $time UCS Configuration Backup Successfully." 

echo "mail has been send out, please wait"

         }

else{

echo "UCS Configuration Backup Unsuccessful."

}