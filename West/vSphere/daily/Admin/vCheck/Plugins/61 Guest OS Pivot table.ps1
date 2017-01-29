# Start of Settings 
# End of Settings 

# Using enterpriseadmins.org modified code
$VMOSVer = @{ }
$FullVM | %{
	if ($_.Guest.GuestFullName) { 
		$VMOSV = $_.Guest.GuestFullName 
	} elseif ($_.Config.AlternateGuestName) { 
		$VMOSV = $_.Config.AlternateGuestName 
	} else {
		$VMOSV = "Unknown" 
	}
	$VMOSVer.$VMOSV++
}

$myCol = @()
foreach ( $gosname in $VMOSVer.Keys | sort) {
	$MyDetails = "" | select OS, Count
	$MyDetails.OS = $gosname
	$MyDetails.Count = $VMOSVer.$gosname
	$myCol += $MyDetails
}

$myCol | sort Count -desc

$Title = "Guest OS Pivot table"
$Header =  "Guest OS Pivot table"
$Comments = "List of Guest OS sum"
$Display = "Table"
$Author = "Frederic Martin"
$PluginVersion = 1.1
$PluginCategory = "vSphere"
