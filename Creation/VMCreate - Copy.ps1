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


$VIEvent = Get-VIEvent -maxsamples 10000 -Start (get-date).AddDays(-1)
$OutputCreatedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmBeingClonedEvent" -or $_.Gettype().Name -eq "VmBeingDeployedEvent"} | Select createdTime, UserName, fullFormattedMessage )







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


$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>
VM Create Yesterday
</title>
"@

#$image = "http://soivminventory.active.tan/pic/pic.png"
#$Pre = "<img src=$image ><P>Create VM:</P>"
#$top = "D:\schedule_jobs\Creation\pic.png"
#$bottom = "D:\schedule_jobs\Creation\bottom.png"


#
#$attachment = New-Object System.Net.Mail.Attachment –ArgumentList "D:\schedule_jobs\Creation\pic.png"
#$attachment.ContentDisposition.Inline = $True
#$attachment.ContentDisposition.DispositionType = "Inline"
#$attachment.ContentType.MediaType = "image/png"
#$attachment.ContentId = 'pic.png'
#
Function AttachImage(){
$path = "D:\schedule_jobs\Creation\image"
$files= Get-ChildItem $path
 
Foreach($file in $files)
{
$attachment = New-Object System.Net.Mail.Attachment –ArgumentList "$Path\$file" #convert file-system object type to string 
$attachment.ContentDisposition.Inline = $True
$attachment.ContentDisposition.DispositionType = "Inline"
$attachment.ContentType.MediaType = "image/png"
$attachment.ContentId = $file.ToString()
$msg.Attachments.Add($attachment)
 
}
}

$Pre = "<img src='cid:top.png'><P>Create VM:</p>"
$Post = "<img src='cid:bottom.png'>"


Function Set-AlternatingRows {
	<#
	.SYNOPSIS
		Simple function to alternate the row colors in an HTML table
	.DESCRIPTION
		This function accepts pipeline input from ConvertTo-HTML or any
		string with HTML in it.  It will then search for <tr> and replace 
		it with <tr class=(something)>.  With the combination of CSS it
		can set alternating colors on table rows.
		
		CSS requirements:
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		
		Classnames can be anything and are configurable when executing the
		function.  Colors can, of course, be set to your preference.
		
		This function does not add CSS to your report, so you must provide
		the style sheet, typically part of the ConvertTo-HTML cmdlet using
		the -Head parameter.
	.PARAMETER Line
		String containing the HTML line, typically piped in through the
		pipeline.
	.PARAMETER CSSEvenClass
		Define which CSS class is your "even" row and color.
	.PARAMETER CSSOddClass
		Define which CSS class is your "odd" row and color.
	.EXAMPLE $Report | ConvertTo-HTML -Head $Header | Set-AlternateRows -CSSEvenClass even -CSSOddClass odd | Out-File HTMLReport.html
	
		$Header can be defined with a here-string as:
		$Header = @"
		<style>
		TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
		TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
		TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		</style>
		"@
		
		This will produce a table with alternating white and grey rows.  Custom CSS
		is defined in the $Header string and included with the table thanks to the -Head
		parameter in ConvertTo-HTML.
	.NOTES
		Author:         Martin Pugh
		Twitter:        @thesurlyadm1n
		Spiceworks:     Martin9700
		Blog:           www.thesurlyadmin.com
		
		Changelog:
			1.1         Modified replace to include the <td> tag, as it was changing the class
                        for the TH row as well.
            1.0         Initial function release
	.LINK
		http://community.spiceworks.com/scripts/show/1745-set-alternatingrows-function-modify-your-html-table-to-have-alternating-row-colors
    .LINK
        http://thesurlyadmin.com/2013/01/21/how-to-create-html-reports/
	#>
    [CmdletBinding()]
   	Param(
       	[Parameter(Mandatory,ValueFromPipeline)]
        [string]$Line,
       
   	    [Parameter(Mandatory)]
       	[string]$CSSEvenClass,
       
        [Parameter(Mandatory)]
   	    [string]$CSSOddClass
   	)
	Begin {
		$ClassName = $CSSEvenClass
	}
	Process {
		If ($Line.Contains("<tr><td>"))
		{	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
			If ($ClassName -eq $CSSEvenClass)
			{	$ClassName = $CSSOddClass
			}
			Else
			{	$ClassName = $CSSEvenClass
			}
		}
		Return $Line
	}
}



  $smtpServer = "lassmtpint01.active.local" 
  $mailfrom = "soi_admins@activenetwork.com"
  $mailto = "cookies.zhang@activenetwork.com"
 

  
  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($smtpServer) 
  $msg.From = $mailfrom
  $msg.To.Add($mailto)
  #$msg.Bcc.Add("Even.Li@activenetwork.com")
  $msg.Subject = "Notification For VM Creation"
  AttachImage
#  if($OutputCreatedVMs -ne $null){
#    $msg.isbodyhtml = $true
#    $msg.Body = $OutputCreatedVMs|ConvertTo-Html -Head $Header -PreContent $Pre   | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd
#    $OutputCreatedVMs|ConvertTo-Html -Head $Header -PreContent $Pre  | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd |out-file D:\kun.htm
#    
# }
#
# else{
#      $MailText = @"
#There is no virtual mathine creation record exists yesterday.
#
#"@
#      $msg.Body = $MailText
# 
# }
#  
#
#
#

  $msg.isbodyhtml = $true
  $msg.Body = $OutputCreatedVMs|ConvertTo-Html -Head $Header -PreContent $Pre -PostContent $Post   | Set-AlternatingRows -CSSEvenClass even -CSSOddClass od
  $smtp.Send($msg)


  $attachment.Dispose();
  $msg.Dispose();