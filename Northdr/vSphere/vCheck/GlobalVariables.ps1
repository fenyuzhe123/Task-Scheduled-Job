# You can change the following defaults by altering the below settings:
#


# Set the following to true to enable the setup wizard for first time run
$SetupWizard = $False


# Start of Settings
# Please Specify the address (and optional port) of the server to connect to [servername(:port)]
$Server = "vcnorthdr.active.tan"
# Would you like the report displayed in the local browser once completed ?
$DisplaytoScreen = $False
# Use the following item to define if an email report should be sent once completed
$SendEmail = $True
# Please Specify the SMTP server address (and optional port) [servername(:port)]
$SMTPSRV = "lassmtpint01.active.local"
# Would you like to use SSL to send email?
$EmailSSL = $false
# Please specify the email address who will send the vCheck report
$EmailFrom = "vcnorthdr@activenetwork.com"
# Please specify the email address(es) who will receive the vCheck report (separate multiple addresses with comma)
$EmailTo ="soi_admins@activenetwork.com,GTOStorageEngineering@activenetwork.com"
# Please specify the email address(es) who will be CCd to receive the vCheck report (separate multiple addresses with comma)
$EmailCc = ""
# Please specify an email subject
$EmailSubject = "vCheck Report - vcnorthdr.active.tan"
# Send the report by e-mail even if it is empty?
$EmailReportEvenIfEmpty = $true
# If you would prefer the HTML file as an attachment then enable the following:
$SendAttachment = $True
# Set the style template to use.
$Style = "CleanGreen"
# Set the following setting to $true to see how long each Plugin takes to run as part of the report
$TimeToRun = $true
# Report an plugins that take longer than the following amount of seconds
$PluginSeconds = 60
# End of Settings

# End of Global Variables
