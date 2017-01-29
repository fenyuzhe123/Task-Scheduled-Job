$Title = "General Information"
$Header =  "General Information"
$Comments = "General details on the infrastructure"
$Display = "List"
$Author = "Joshua Barton"
$PluginVersion = 0.1
$PluginCategory = "UCS"

# Start of Settings 
# End of Settings 

# Determine Primary and Secondary FIs
If ($DomStatus.FiALeadership -eq "primary") {
	$FabPrimary = "A"
	$FabSecondary = "B"
} Else {
	$FabPrimary = "B"
	$FabSecondary = "A"
}

# Get Fault Retention Policy, split out for legibility.
$SplitRetention = ((Get-UcsFaultPolicy).RetentionInterval).Split(":")

If ($SplitRetention[0] -ne "00") {
	$TimeSpan = "Days"
	$RetLimit = $SplitRetention[0]
} Else {
	$TimeSpan = "Hours"
	$RetLimit = $SplitRetention[1]
}

# Generate Info object with details
$Info = New-Object -TypeName PSObject
	$Info | Add-Member NoteProperty "UCS Domain Name:" $DomStatus.Name
	$Info | Add-Member NoteProperty "Primary Interconnect:" $FabPrimary
	$Info | Add-Member NoteProperty "Secondary Interconnect:" $FabSecondary
	$Info | Add-Member NoteProperty "HA State:" $DomStatus.HaReadiness
	$Info | Add-Member NoteProperty "FI Switch Mode:" (Get-UcsLanCloud).Mode
	$Info | Add-Member NoteProperty "Number of Chassis:" (@($Chassis).Count)
	$Info | Add-Member NoteProperty "Number of Blades:" (@($Blades).Count)
	$Info | Add-Member NoteProperty "Number of Templates:" (@($SvcProfTmpls).Count)
	$Info | Add-Member NoteProperty "Number of Profiles:" (@($SvcProfs).Count)
	$Info | Add-Member NoteProperty "In-Active Blades:" (@($Blades | Where {$_.OperPower -ne "on"}).Count)
	$Info | Add-Member NoteProperty "Faults:" (@($Faults).Count)
	$Info | Add-Member NoteProperty "Fault Retention Policy:" ($RetLimit + " " + $TimeSpan)

$Info