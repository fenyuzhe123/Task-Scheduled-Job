# Start of Settings
# End of Settings

# Changelog
## 1.0 : Initial Release


# Check Power CLI version. Build must be at least 1012425 (5.1 Release 2) to contain Get-VDPortGroup cmdlet
$VersionOK = $false
if (((Get-PowerCLIVersion) -match "VMware vSphere PowerCLI (.*) build ([0-9]+)")) {
   if ([int]($Matches[2]) -ge 1012425) {
      $VersionOK = $true
      # Add required Snap-In
      if (!(Get-PSSnapin -name VMware.VimAutomation.Vds -ErrorAction SilentlyContinue)) {
         Add-PSSnapin VMware.VimAutomation.Vds
      }
   }
}

if ($VersionOK) {
   [array] $results = $null
   $VDPGs=Get-VDPortgroup|where {$_.IsUplink -eq $False}
   Foreach ($VDPG in $VDPGs){
      $Output = "" | Select-Object Name,Id,vDSwitch,DataCenter,UplinkCount
	  $Output.Name = $VDPG.Name
	  $Output.Id = $VDPG.Id
	  $Output.vDSwitch = $VDPG.VDSwitch.Name
	  $Output.DataCenter = $VDPG.VDSwitch.DataCenter
	  $Output.UplinkCount = ($VDPG|Get-VDUplinkTeamingPolicy).ActiveUplinkPort.Length
	  if ($Output.UplinkCount -lt 2){
	      $results += $Output
	  }
   }
   if ($results.Length) { $results | Sort-Object Name,DataCenter}
}
else {
   Write-Warning "PowerCLi version installed is lower than 5.1 Release 2"
   New-Object PSObject -Property @{"Message"="PowerCLi version installed is lower than 5.1 Release 2, please update to use this plugin"}
}

$Title = "VDPortGroup Single Uplink"
$Header = "PortGroup Without Uplink Redundancy"
$Comments = "List all the VDS PortGroup running with single uplink."
$Display = "Table"
$Author = "Dylan Hai"
$PluginVersion = 1.0
$PluginCategory = "vSphere"
