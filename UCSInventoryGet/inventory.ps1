Import-Module CiscoUCSps
set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $true
# Define UCS connection details
$ucsdomain = ("10.107.121.13","uslas-c6296fi-01.active.tan","uslas-c6296fi-02.active.tan","uslas-c6296fi-03.active.tan","uslas-c6120fi-04.active.tan","usash-c6296fi-01.active.tan","cator-c6296fi-01.active.tan","cakel-c6248fi-01.active.tan")
#$ucsdomain = ("10.107.121.13","uslas-c6120fi-04.active.tan")
#$ucsusername = "ucs-TAN\mxu"
#$ucsPassword = "XXX"
#$ucsPassword = ConvertTo-SecureString -String $ucsPassword -AsPlainText -Force
#$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $ucsusername, $ucsPassword

$ucsusername = "ucs-TAN\svc.ucsbackup"
#$ucsPassword = cat D:\schedule_jobs\UCSInventoryGet\keys\secureupdated.key | convertto-securestring
$ucsPassword = cat D:\schedule_jobs\UCSInventoryGet\keys\secure.key | convertto-securestring
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $ucsusername, $ucsPassword

#System date
$Date = Get-Date -Format "yyyy-MM-dd-HH-mm"
$File_Nmae = "UCSInventory-" + $Date.ToString() + ".csv"

$Report = @()
foreach ($ucsSysName in $ucsdomain){
$ucsSysName
$ucsConnection = Connect-Ucs $ucsSysName -Credential $cred
$ucs_info = Get-UcsNetworkElement
$UCS_SN = $ucs_info |Select-Object serial
$allChassis = Get-UcsChassis
#$FI_ports= Get-UcsEtherSwitchIntFIo | Select-Object ChassisId,Discovery,Model,OperState,SwitchId,PeerSlotId,PeerPortId,SlotId,PortId,XcvrTyp
 $FI_ports= Get-UcsEtherSwitchIntFIo | Select-Object *
 foreach ($chassis in $allChassis)
        {
            Write-Progress -Activity "Analyzing Chassis $($chassis.Dn) of $($chassis.ucs)" `
                            -Status "Chassis $($allChassis.IndexOf($chassis)) of $($allChassis.Count)" `
                            -PercentComplete $(($allChassis.IndexOf($chassis) / $allChassis.Count)*100) `
                            -Id 1
            
            #--- Hash variable for storing current chassis data ---#
			$chassisHash = @{}
			$chassisHash.Dn = $chassis.Dn
			$chassisHash.Id = $chassis.Id
			$chassisHash.Model = $chassis.Model
			$chassisHash.Status = $chassis.OperState
			$chassisHash.Operability = $chassis.Operability
			$chassisHash.Power = $chassis.Power
			$chassisHash.Thermal = $chassis.Thermal
			$chassisHash.Serial = $chassis.Serial
			$chassisHash.Blades = $chassis| Get-UcsBlade
            $chassisHash.Adaptor = $chassisHash.Blades | Get-UcsAdaptorUnit
            $chassisHash.IOM = $chassis | get-ucsiom


            
            #Initial slot 

            $blades = $chassisHash.Blades.GetEnumerator() | select-object *
            
            $slotCount =0 

            while ($slotCount -lt $blades.Count) {
            #$info = "" | select Ucs,chassis_ID,chassis_SN,SlotId,usrLbl,Serial,Model,mfgtime,Adaptor,IOM,CPU,NumOfCpus,NumOfCores,AvailableMemory,Dn,Association,Name
            $info = "" | select Ucs,ucs_SN,chassis_ID,chassis_SN,SlotId,usrLbl,Serial,Model,mfgtime,Adaptor,Adaptor_SN,IOM,IOM_SN,CPU,NumOfCpus,NumOfCores,AvailableMemory,Dn,Association,name,CaptureTime

			$adaptor = get-ucsblade -dn $blades[$slotCount].dn |  Get-UcsAdaptorUnit
            $CPU = (get-ucsblade -dn $blades[$slotCount].dn|Get-UcsComputeBoard | Get-UcsProcessorUnit | Select-Object Model)[0].model
            #$adaptor_IOM = $adaptor | Get-UcsAdaptorExtEthIf | Select-Object PeerSlotId,PeerPortId
            #$adaptor_mac = $adaptor | Get-UcsAdaptorHostethIf |Select-Object Mac
            #$adaptor_wwn = $adaptor | Get-UcsAdaptorHostFcIf | Select-Object wwn 
            $info.ucs = $blades[$slotCount].ucs
			$info.ucs_SN = $UCS_SN[0].Serial + ',' + $UCS_SN[1].Serial
            $info.chassis_ID = $chassisHash.Id
            $info.chassis_SN = $chassisHash.Serial
            $info.SlotId = $blades[$slotCount].SlotId
            $info.usrLbl = $blades[$slotCount].usrLbl
            $info.Serial = $blades[$slotCount].Serial
            $info.Model = $blades[$slotCount].Model
            $info.Adaptor = ($adaptor[0] | select Model).model
			$info.Adaptor_SN = $adaptor[0].Serial
            $info.IOM = ($chassisHash.IOM).GetValue(0).Model
			$info.IOM_SN = ($chassisHash.IOM.GetValue(0).serial +',' +$chassisHash.IOM.GetValue(1).serial)
            #$info.MAC = $adaptor_mac
            #$info.wwn = $adaptor_wwn
            $info.cpu = $CPU
            $info.mfgtime = $blades[$slotCount].mfgtime
            $info.NumOfCpus =$blades[$slotCount].NumOfCpus
            $info.NumOfCores = $blades[$slotCount].NumofCores
            $info.AvailableMemory = $blades[$slotCount].AvailableMemory
            $info.Dn = $blades[$slotCount].Dn
			$info.Association = $blades[$slotCount].Association
			$info.Name = $blades[$slotCount].Name
			$info.CaptureTime = get-date -Format "yyyy-MM-dd HH:mm:ss"
	
			
			
			
            #$info.ConnPath = $blades[$slotCount].ConnPath
            $slotCount +=1
            $info
            $Report += $info
            }
            

		}
Disconnect-Ucs
}


$Report | Export-Csv -Path D:\schedule_jobs\UCSInventoryGet\output\"$File_Nmae" -NoTypeInformation
$Report | Export-Csv -Path D:\schedule_jobs\UCSInventoryGet\output\import.csv -NoTypeInformation
$File = "D:\schedule_jobs\UCSInventoryGet\output\"+"$File_Nmae"

#$Report

#import csv to mysql



# import csv file to mysql db.



[void][system.Reflection.Assembly]::LoadFrom("C:\\Program Files (x86)\\MySQL\\MySQL Connector Net 6.9.9\\Assemblies\\v4.0\\MySql.Data.dll")
#$csv = "D:/schedule_jobs/UCSInventoryGet/output/"+"$File_Name"
$Server="10.107.122.220"
$Database="UCS" #数据库名
$user="root" #账户
$Password="@ctive123" #密码
$connectionString = "server=$Server;uid=$user;pwd=$Password;database=$Database;charset=$charset"
$connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)
$connection.Open()
$insertsql = (Get-Content D:\schedule_jobs\UCSInventoryGet\sql.txt) -join "`r`n"
#$insertsql[0]  = $insertsql[0] + '''' + $csv + ''''
$insertcommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$insertcommand.Connection=$connection
$insertcommand.CommandText=$insertsql
$insertcommand.ExecuteNonQuery()
$connection.Close()

#Mail information 


$EmailFrom = "soi_admins@activenetwork.com"
$EmailTo = "soi_admins@activenetwork.com","Jon.Laughrey@activenetwork.com"
#$EmailTo = "John.yang@activenetwork.com"
$EmailSubject = ' UCS Inventory ' +(get-date -Format yyyy/MM/dd)
$EmailSmtp = "lassmtpint01.active.local"
#Send Mail to mail group
if ($File)
	{
echo "Prepare for sending mail "
Send-MailMessage -To $EmailTo -From $EmailFrom -SmtpServer $EmailSmtp -Subject  $EmailSubject  -Body " UCSInventory $Date  " -Attachments $File
echo "mail has been send out, please wait"
	}
else{
echo "Attchment can not be found or mail porcess fail"
}



    