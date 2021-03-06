# You can change the following defaults by altering the below settings:
#

# Set the following to true to enable the setup wizard for first time run
$SetupWizard =$False

# Start of Settings
# Please Specify the IP address or Hostname of the server to connect to
$Server ="vcwest.active.tan"
# Please Specify the SMTP server address
$SMTPSRV ="lassmtpint01.active.local"
# Please specify the email address who will send the vCheck report
$EmailFrom ="wcdcvc@activenetwork.com"
# Please specify the email address who will receive the vCheck report
$EmailTo ="soi_admins@activenetwork.com"
# Please specify an email subject
$EmailSubject="vCheck Report - vcwest.active.tan"
# Would you like the report displayed in the local browser once completed ?
$DisplaytoScreen =$True
# Use the following item to define if an email report should be sent once completed
$SendEmail =$true
# If you would prefer the HTML file as an attachment then enable the following:
$SendAttachment =$True
# Use the following area to define the title color
$Colour1 ="545456"
# Use the following area to define the Heading color
$Colour2 ="545456"
# Use the following area to define the Title text color
$TitleTxtColour ="FBAD18"
# Set the following setting to $true to see how long each Plugin takes to run as part of the report
$TimeToRun = $true
# Report an plugins that take longer than the following amount of seconds
$PluginSeconds = 60
# End of Settings

$Date = Get-Date
