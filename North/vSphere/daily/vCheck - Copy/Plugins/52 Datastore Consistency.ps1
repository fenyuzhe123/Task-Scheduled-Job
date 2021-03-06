# Start of Settings
# Do not report on any datastores who are defined here
$DSDoNotInclude ="LOCAL*|datastore*|*oot"
# End of Settings
 
ForEach ($Cluster in (Get-Cluster | Sort Name)) {
                $VMHosts = Get-Cluster $Cluster.Name | Get-VMHost
                $Datastores = $VMHosts | Get-Datastore
                $problemDatastores = $VMHosts | ForEach {Compare-Object $Datastores ($_ | Get-Datastore)} | ForEach {$_.InputObject} | Sort Name | Select @{N="Datastore";E={$_.Name}},@{N="Cluster";E={$Cluster.Name}} -Unique
}
 
@($problemDatastores  | Where { $_.Datastore -notmatch $DSDoNotInclude })

$Title = "Datastore Consistency"
$Header =  "Datastores not connected to every host in cluster"
$Comments = "Virtual Machines residing on these datastores will not be able to run on all hosts in the cluster"
$Display = "Table"
$Author = "Robert Sexstone"
$PluginVersion = 1.1
$PluginCategory = "vSphere"
