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
$OutputRemovedVMs = @($VIEvent | where {$_.Gettype().Name -eq "VmRemovedEvent"-and $_.username -ne "User"}| Select CreatedTime, UserName, fullFormattedMessage)




$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #FF2400;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>
VM Create Yesterday
</title>
"@



Function Set-AlternatingRows {
	
	
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


Function AttachImage(){
$path = "D:\schedule_jobs\Creation\image"
$files= Get-ChildItem $path
 
Foreach($file in $files)
   {
$attachment = New-Object System.Net.Mail.Attachment –ArgumentList "$Path\$file"  
$attachment.ContentDisposition.Inline = $True
$attachment.ContentDisposition.DispositionType = "Inline"
$attachment.ContentType.MediaType = "image/png"
$attachment.ContentId = $file.ToString()
$msg.Attachments.Add($attachment)
  
   }
}

$Pre = "<img src='cid:top.png'><P>Removed VM:</p>"
$Post = "<br><br><img src='cid:bottom.png'>"

  $smtpServer = "lassmtpint01.active.local" 
  $mailfrom = "soi_admins@activenetwork.com"
  $mailto = "soi_admins@activenetwork.com,EPS_ServiceDelivery@activenetwork.com"
 

  
  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($smtpServer) 
  $msg.From = $mailfrom
  $msg.To.Add($mailto)
  $msg.Bcc.Add("Even.Li@activenetwork.com")
  $msg.Subject = "Notification For VM Deletion"
  AttachImage
  $msg.isbodyhtml = $true
  $msg.Body = $OutputRemovedVMs|ConvertTo-Html -Head $Header -PreContent $Pre -PostContent $post  | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd
    
  if($OutputRemovedVMs.Count -ne 0){
    
    $smtp.Send($msg)
  }
 
  $attachment.Dispose();
  $msg.Dispose();
  
  