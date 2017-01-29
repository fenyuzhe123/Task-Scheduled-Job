# v1.0
###################################################
#
# Description: Query and set active.platform.productid for VMs
#
# Created by: Cyril Perdereau, Dylan Hai
# Created on: 2015-01-19
#
# Modified: 2015-01-19
#
###################################################
#
# Required Module:
#- VMware.VimAutomation.Core (tested with 5.1.0.0)
#
###################################################

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)][string]$UpdatePid,
    [Parameter(Mandatory=$True)][string]$User,
    [Parameter(Mandatory=$True)][string]$vCenter
)

$DEBUG_F = $True
try{$UpdatePid.gettype()} catch [System.Exception]{$UpdatePid=$False}
$global:CustomFieldName = "active.platform.productid"


Try {$pathlog = Split-Path ($MyInvocation.MyCommand.Path); $scriptname = $MyInvocation.MyCommand.name }
Catch {$pathlog = $env:temp; $scriptname = 'Atom_Pricing_SetProductId.ps1'}

$timestp = Get-Date -Format "yyyy-MM-dd HH.mm.ss"
$timestpfile = Get-Date -Format "yyyy-MM-dd"
$destFolderLog = ".\logs"
New-Item $destFolderLog -ItemType directory -ea silentlycontinue
$global:debuglog = Join-path $destFolderLog "$timestp $scriptname.log"

####################
# Functions
####################

Function Logthis ($string,$color="White")
{
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss -> "
  $er = $timestamp + $string
  Write-Host $Er -fore $color
  $er | Out-File $debuglog -append
}


Function Load-Snapins {

	$snapins = @("VMware.VimAutomation.Core")

	Foreach ($snapin in $snapins) {

		if ( (Get-PSSnapin -Name $snapin -ErrorAction SilentlyContinue) -eq $null )
		{
		    LogThis "Loading Snapin: $snapin"
		    Add-PsSnapin $snapin
		}
	}
}

Function Get-VMFolderFastA($parent)
{
	if ($VMFolderHash[$parent].ParentId) {
		$path += @($VMFolderHash[$parent].Name)
		Get-VMFolderFastA $VMFolderHash[$parent].ParentId  #Recursion
        #Logthis "$path"
	} else {
		[array]::Reverse($path)
		return  $path
	}
}


Function Get-VMfolderOptimizer {
	###############
	# INIT for fast Get-VMFolderFast
	#
	# This is a pretty damn cool optimization to find the VM path faster than Get-VMFolder function
	# Time with Get-VMFolder: 45 minutes
	# Time with Get-VMFolderFast: 26 seconds
	#
	###############
	$FO = Get-Folder | Select ParentId,Name,Id
	$DC = Get-Datacenter | Select @{Name='ParentID';exp={$_.ParentFolderId}},Name,ID

	$global:VMFolderHash = @{}
	$FO  | % {$VMFolderHash[$_.ID] = $_ }
	$DC | % {$VMFolderHash[$_.ID] = $_ }

	Remove-Variable FO
	Remove-Variable DC

Return $VMFolderHash
}

# Set VM Pid from folders
Function Set-VMPidFromFolder ($vm) {
	$CurrentProductId=($vm.CustomValue | where{$_.Key -eq [int]$myCustomField.Key}).Value
	If ($vm.parent) {
	    if ($UpdatePid) {
		   $FolderLocation = Get-VMFolderFastA $vm.parent.ToString()
            #Logthis "$FolderLocation"
		   $Product = $FolderLocation[4]
           logthis "Found $Product"
		   if ($Product -match ".*\.p(?<content>.*)$"){
		      if (($ProductId = $matches['content']) -ne $CurrentProductId){
		      $vm.setCustomValue($CustomFieldName,$ProductId)
		      logthis ($vm.name+": Set to "+$ProductId+", original is "+$CurrentProductId)
			  }
		   } else{
		       $ProductId = "0"
			   $vm.setCustomValue($CustomFieldName,$ProductId)
			   logthis ($vm.name+","+$ProductId+",bad location")
		   }
		
		} else{
		    $FolderLocation = Get-VMFolderFastA $vm.parent.ToString()
		    $Product = $FolderLocation[4]
		    if ($Product -match ".*\.p(?<content>.*)$"){
		       $ProductId = $matches['content']
		       logthis ($vm.name+","+$ProductId+","+$CurrentProductId)
		    } else{
		       logthis ($vm.name+" is in bad location.")
		    }
		}
	} else {
	    if ($UpdatePid){
		   $ProductId = "0"
		   $vm.setCustomValue($CustomFieldName,$ProductId)
		} else{
		    logthis ("No folder found for "+$vm.name)
		}
	} #end if


}


###############################
# MAIN
###############################



Load-Snapins


#######################################
# Credential to Access Virtual Center
#######################################

$CredsFile = ".\keys\secure.key"
$pass = Get-Content $CredsFile | ConvertTo-SecureString
$Cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $User,$pass



########################################################################################################################################################################
###  START LOOP HERE SHOULD START LOOP HERE SHOULD START LOOP HERE SHOULD START LOOP HERE SHOULD START LOOP HERE SHOULD START LOOP HERE SHOULD START LOOP HERE

Try {Disconnect-VIServer * -Force -Confirm:$false} #Disconnect from all VCs
Catch {}

# Connect to a VC
$xx = Connect-VIServer -Server $vCenter -Credential $Cred

if (!$xx) { LogThis "[ERROR] Not connected to $vCenter with $use - EXIT SCRIPT" Red;  } else { LogThis "[SUCCESS] Connected to $vCenter" Green }

#Create custome attribute if it doesn't exist
if ($UpdatePid){
	$Annotations=Get-CustomAttribute -TargetType "VirtualMachine"|select -ExpandProperty Name
    If ($Annotations -notcontains $CustomFieldName){
        New-CustomAttribute -Name $CustomFieldName -TargetType "VirtualMachine"
       }
}
# Get the VMs
$filter=@{"Config.Template"=[string]$false} #Filter the Templates out
$vms = Get-View -ViewType VirtualMachine -Filter $filter
$vms

if ($vms -is [array]) { LogThis "Virtual Machines found: $($vms.count) in $vCenter" } else { LogThis "[ERROR] No VM found in $vCenter" Red; EXIT 1 }

#Find duplicates in VM names - No duplicate VM name should exist in VC
LogThis "Search for duplicate VMs"
$VMSHashDuplicates = @{}
$vms | % { $VMSHashDuplicates[[string]$_.name] += 1}
$duplicateVMsReport = $VMSHashDuplicates.getenumerator() | ? {$_.value -ge 2 } | ft -a | Out-String
$dupli = @($VMSHashDuplicates.getenumerator() | ? {$_.value -ge 2 } | select -expand name)

If ( $dupli.count -ge 1 ) {
	LogThis "[ERROR] Duplicate VMs found in Virtual Center " Yellow;
	LogThis $duplicateVMsReport
} #End if

# Exclude the duplicate VMs for treatement
$vmtotreat = $vms | ? { $dupli -notcontains $_.name} | Sort-Object name # Exclude the duplicate VMs for processing

Get-VMfolderOptimizer
$SI = Get-View ServiceInstance
$CFM = Get-View $SI.Content.CustomFieldsManager
$global:myCustomField = $CFM.Field | Where {$_.Name -eq $CustomFieldName}
Logthis $myCustomField.key

######START VM LOOP
foreach ($vm in $vmtotreat) {
   Set-VMPidFromFolder($vm)
}#END VM LOOP


Sleep 5
Try {Disconnect-VIServer * -Force -Confirm:$false} #Disconnect from all VCs
Catch {}

