# Start of Settings 
# Define the maximum amount of vCPUs your VMs are allowed

# End of Settings

$OverCPU = @($VM | Where {$_.NumCPU -gt 8} | Select Name, PowerState, NumCPU)
$OverCPU

$Title = "VMs with over 8 vCPUs"
$Header = "VMs with over 8 vCPUs: $(@($OverCPU).count)"
$Comments = "The following VMs have over 8 CPU(s) and may impact performance due to CPU scheduling"
$Display = "Table"
$Author = "Alan Renouf"
$PluginVersion = 1.1
$PluginCategory = "vSphere"
