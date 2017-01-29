$Title = "Unassociated Service Profiles"
$Header =  "Unassociated Service Profiles"
$Comments = "Unassociated Profiles are not being utilized. Consider removing them."
$Display = "List"
$Author = "Joshua Barton"
$PluginVersion = 0.1
$PluginCategory = "UCS"


# Start of Settings 
# End of Settings 

# PSObject to hold unassociated profiles
$UnassocProfs = New-Object -TypeName PSObject

# Interate through profiles that are not associated. Add them to the PSObject
Foreach ($SvcProf in $SvcProfs) {
	If ($SvcProf.AssocState -ne "associated") {
		$UnassocProfs | Add-Member NoteProperty "$($SvcProf.Name)" $SvcProf.AssocState
	}
}

# Output PSObject back to vCheck
$UnassocProfs

