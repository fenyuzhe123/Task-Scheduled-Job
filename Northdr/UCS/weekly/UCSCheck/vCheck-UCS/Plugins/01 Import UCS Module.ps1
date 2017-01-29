$Title = "Connection Settings for UCS"
$Author = "Joshua Barton"
$PluginVersion = 0.1
$Header =  "Connection Settings"
$Comments = "Connection Plugin for connecting to UCS"
$Display = "List"
$PluginCategory = "UCS"

# Start of Settings 
# End of Settings 

# Find the UCS Domain from the global settings file
$UcsDomain = $Server

# Default Path to UCS PowerTool
$PowerToolPath = "C:\Program Files (x86)\Cisco\Cisco UCS PowerTool\Modules\CiscoUcsPS\CiscoUcsPS.psd1"

# Check to see if PowerTool module is loaded. 
If (!(Get-Module -name CiscoUcsPS -ErrorAction SilentlyContinue)) {
	# Test to see if path to PowerTool module exists. If so, import it. Otherwise throw a terminating error.
	If (Test-Path $PowerToolPath -ErrorAction Stop) { 
		Write-CustomOut "Loading Cisco UCS Powertool"
		Import-Module $PowerToolPath
	} Else {
		Write-CustomOut "Cannot locate UCS Powertool Module. Please verify that it has been installed."
		Throw
	}
}
$user = "admin"
$password = 'Squar3R00t!' | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $password)
Try {
	$OpenConnection = Get-UcsStatus
	If (($OpenConnection.Name -eq $Domain) -OR ($OpenConnection.VirtualIpv4Address -eq $Domain)) {
		Write-Host "Re-using connection to UCS Domain"
		$UcsConnection = $OpenConnection
	}
} Catch {
	# Hack. -ErrorAction SilentlyContinue doesn't function for this cmdlet if there are no default connections
	If ($_.FullyQualifiedErrorId -eq "System.Exception,Cisco.Ucs.Cmdlets.GetUcsStatus") {
		Write-CustomOut "No open connections... Connecting to UCS Domain: $Domain"
	} Else {
		# Unexpected Error
		Write-CustomOut $_.Exception.Message
	}
} Finally {
	Try {
		$UcsConnection = Connect-Ucs $UcsDomain -Credential $cred -ErrorAction Stop
	} Catch {
		Write-CustomOut "Unable to connect to UCS Domain: $UcsDomain"
		Throw "Please verify address and credentials."
	}
}

Write-CustomOut "Collecting Domain Status Details"
$DomStatus = Get-UcsStatus
Write-CustomOut "Collecting Service Profiles"
$SvcProfs = Get-UcsServiceProfile -Type instance | Sort Name
Write-CustomOut "Collecting Service Profile Templates"
$SvcProfTmpls = Get-UcsServiceProfile | Where-object {$_.UuidSuffix -eq "0000-000000000000"} | Sort Name
Write-CustomOut "Collecting Blade Objects"
$Blades = Get-UcsBlade | Sort Name
Write-CustomOut "Collecting Fabric Interconnects"
$FabricInterconnects = Get-UcsNetworkElement | Sort Name
Write-CustomOut "Collecting Port Licenses on Fabric A"
$APortLicenses = Get-UcsLicense | Where {$_.Scope -eq "A"}
Write-CustomOut "Collecting Port Licenses on Fabric B"
$BPortLicenses = Get-UcsLicense | Where {$_.Scope -eq "B"}
Write-CustomOut "Collecting Port Info on Fabric Interconnects"
$EthPorts = Get-UcsFabricPort | Sort Rn
Write-CustomOut "Collecting Ethernet Rx Stats"
$EthPortChs = Get-UcsUplinkPortChannel
Write-CustomOut "Collecting Chassis Objects"
$Chassis = Get-UcsChassis | Sort Rn
Write-CustomOut "Collecting Fault Objects"
$Faults = Get-UcsFault | Sort Severity -Descending
Write-CustomOut "Collection Statistic Collection Policies"
$StatCollPolicy = Get-UcsCollectionPolicy

