$Title = "List of Recent Faults"
$Header =  "Number of Recent Faults: " + (@($Faults).Count)
$Comments = "Showing cleared events: $ClearedEvnts"
$Display = "Table"
$Author = "Joshua Barton"
$PluginVersion = 0.1
$PluginCategory = "UCS"

# Start of Settings
# Do you want to see cleared events?
$ClearedEvnts = $False 
# End of Settings

$UcsFaultTable = @()

# Determine whether to show cleared events
If ($ClearedEvnts -eq $False) {
	$FaultList = $Faults | Where { $_.Severity -ne "cleared" }
} Else {
	$FaultList = $Faults
}

Foreach ($Fault in $FaultList) {
	# Create object to hold current fault details
	$Details = "" | Select-Object Object, Severity, Description, Date
	
	# Skip if no faults, otherwise begin populating temporary Details object
	If ($Faults.Count -gt 0) {
		
		# Trim object down to only necessary information
		If ($Fault.Dn -like "*chassis*") {
			$LocSplit = ($Fault.Dn).Split("/")
			$Details.Object = $LocSplit[1] + "/" + $LocSplit[2]
		} Else {
			$LocSplit = ($Fault.Dn).Split("/")
			$Details.Object = $LocSplit[1]
		}
		
		$Details.Severity = $Fault.Severity
		$Details.Description = $Fault.Descr
		$Details.Date = $Fault.Created
	}
	
	# Offload Details object into UcsFaultTable
	$UcsFaultTable += $Details
}

$UcsFaultTable
