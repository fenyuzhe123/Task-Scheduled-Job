#===================================================================================#
#	Switch Parameters to automate the following									 	#
#		1) UseCached - Login to cached UCS domains									#
#		2) RunReport - Go directly to generating a health check report				#
#		3) Silent - Execute the script and exit with no user interaction			#
#===================================================================================#
Param(
	[Switch] $UseCached,
	[Switch] $RunReport,
	[Switch] $Silent,
	[Switch] $Email
)
#===================================================================================#
#	Global Variable Definition														#
#		UCS				=	Hash variable for storing UCS handles					#
#		UCS_Creds		=	Hash variable for storing UCS domain credentials		#
#		CCO_Creds		=	Credential variable for pulling software from cisco.com	#
#		CCO_Image_List	=	Stores the latest UCS firmware bundles from CCO			#
#		PS_Version		=	User's major powershell version							#
#		runspaces		=	runspace pool for simultaneous code execution			#
#		Silent_Path		=	path to save report when running in silent execution	#
#		Silent_FileName	=	filename of report when running in silent execution		#
#===================================================================================#
set-location D:\schedule_jobs\Northdr\UCS\weekly\UCSCheck
$UCS = @{}
$UCS_Creds = @{}
$CCO_Creds = $null
$CCO_Image_List = $null
$PSVersion = $version = (Get-Host).Version.Major
$runspaces = $null
$Silent_Path = './'
$Silent_FileName = 'SOI_UCS_Report_' + (Get-Date -format MM_dd_yyyy) + '.html'

#===================================================================================#
# 	Email Variables																	#
#	Modify these values to email the report											#
#===================================================================================#
$Email_Report = 0
$smtpServer = "lassmtpint01.active.local" 
$mailfrom = "soi_admins@activenetwork.com"
$mailto = "soi_admins@activenetwork.com"

#--- HTML Markup ---#
#===================================================================================#
# 	Variable Definition:															#
#	section_1 - minified HTML and CSS markup used for the healthcheck report.		#
#===================================================================================#
$section_1 = @'
<!DOCTYPE html><html><head><title>Cisco UCS HealthCheck</title><meta name="viewport" content="width=device-width, initial-scale=1.0"><link href="http://netdna.bootstrapcdn.com/bootstrap/3.0.2/css/bootstrap.min.css" rel="stylesheet"><link rel="stylesheet" type="text/css" href="http://raw.github.com/DataTables/Plugins/master/integration/bootstrap/3/dataTables.bootstrap.css"><!--[if lt IE 9]><script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script><script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script><![endif]--><style type="text/css">body{min-width:900px;}.logo-image{height:20px;border:4px solid;border-color:#F0EDED;-moz-border-radius: 12px;-khtml-border-radius: 12px;-webkit-border-radius: 12px;border-radius:12px;width:40px;margin-left:4px !important;margin-top:5px;margin-right:10px;}.navbar-inverse{background-color: #1b1b1b;background-image: -moz-linear-gradient(top, #222222, #504E4E);background-image: -webkit-gradient(linear, 0 0, 0 100%, from(#222222), to(#504E4E));background-image: -webkit-linear-gradient(top, #222222, #504E4E);background-image: -o-linear-gradient(top, #222222, #504E4E);background-image: linear-gradient(to bottom, #222222, #504E4E);background-repeat: repeat-x;border-color: #252525;filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#ff222222', endColorstr='#ff111111', GradientType=0);-webkit-box-shadow: 0 1px 10px rgba(0, 0, 0, 0.1);-moz-box-shadow: 0 1px 10px rgba(0, 0, 0, 0.1);box-shadow: 0 1px 10px rgba(0, 0, 0, 0.1);}.navbar{border-radius:2px}.navbar-header .glyphicon-plus{margin-right:8px;font-size:20px;color:#F0EDED;margin-top:-27px;margin-left:-23px !important;}.navbar-header a{font-size:24px;color:#F0EDED !important;}.Domain-Heading .caret{margin-left:10px;}.domain-heading{margin-right:10px;display:inline;margin-left:8px;}#SelectedDomain{padding-top:2px;padding-bottom:2px;}.nav-tabs a{font-size:15px;}#System-Fault-Icons{cursor:pointer;}.System .Fault-Summary{max-width:550px;margin-bottom:16px;}.System .Fault-Summary .glyphicon{font-size:20px;text-align:right;}.System .Fault-Summary h4{font-size:22px;}.System .Fault-Summary td{text-align:center;}.System .fault-critical{color:#C47474;}.System .fault-major{color:#FCD37E;}.System .fault-minor{color:#F1F131;}.System .fault-warning{color:#6FD3D3;}.System .pad{margin-left:8px;}.System .Fault-Summary .fault-counts{line-height:0;}.System .panel-heading{background-color:#428bca;border-color:#357ebd;color:white;font-size:16px;font-weight:bold;padding:6px 15px;}.System th,td{padding:7px;}.System .Table-Column td{width:30%;}#Blade-Details .Table-Column td{width:40%;}.small-th-table td{width:70%}.small-th-table th{width:30%}.SystemTable2 th{min-width:240px;}.SystemTable2{margin-top:-20px;}.SystemDomainDiv{margin-top:20px;margin-bottom:6px;margin-left:-10px;}.SystemDomainDiv h4{font-size:16px;font-weight:bold;}#Chassis-Power th, #Chassis-Power td, #Server-Power th, #Server-Power td, #Server-Temp th, #Server-Temp td{font-size:12px;padding:3px;}#Chassis-Power thead, #Server-Power thead, #Server-Temp thead{background-color:rgb(230, 227, 227);}.small-table td, .small-table th{font-size:12px !important;padding:3px;}.small-table thead{background-color:rgb(230, 227, 227);}@media (min-width:992px){.SystemTable2{max-width:600px;margin-top:0px !important;}.SystemTable th{min-width:0px !important;}.Table-Column{max-width:550px;}}.SystemTable th{min-width:260px !important;}.inline{display:inline;}.heading-icon{margin-right:8px;}.Inventory th,.Inventory td{font-size:12px;padding:3px;}.Inventory thead{background-color:rgb(230, 227, 227);}.Inventory .panel-heading{background-color:#428bca;border-color:#357ebd;color:white;padding:10px 15px;}.Inventory #FabricInterconnect tbody>tr{cursor:pointer;}.Inventory #Chassis tbody>tr{cursor:pointer;}.Inventory #IOMs tbody>tr{cursor:pointer;}#Blades .pointer tbody>tr>td:not(:nth-child(6)){cursor:pointer;}.Active-Template .pointer tbody>tr>td:not(:nth-child(4)){cursor:pointer;}.details-general{max-width: 600px;}.panel-title{margin-right:10px;display:inline;font-size:15px;font-weight:bold;}.Inventory .panel-body{padding:10px;}@media (min-width:1200px){.visible-medium{display:table-cell !important;}}@media (min-width:1504px){.visible-large{display:table-cell !important;}}.visible-large,.visible-medium{display:none;}.container{width:95% !important;}.Policies .panel-title{margin-right:10px;display:inline;font-size:15px;font-weight:bold;}.Policies ul{list-style-type:none;padding:0px;margin:0px;}.Policies th,td{padding:7px;}.Policies td{width:30%;}.Profiles .panel-group{margin-top:20px;}.Profiles .panel-title{margin-right:10px;display:inline;font-size:15px;font-weight:bold;}.Profiles thead{background-color:rgb(230, 227, 227);}.Profiles th,.Profiles td{font-size:12px;padding:3px !important;}.profile-type{display: inline;font-size: 15px;font-weight: bold;margin-right: 8px;padding: 0px;}.Profiles .Template-Heading{float:right;}.Profiles .Template-Heading .glyphicon{font-size:16px !important;}.Profiles .Template-Heading .glyphicon-new-window{cursor:pointer}table .info{background-color:#D8F0F0;}.Faults .panel-heading{font-size: 16px;font-weight: bold;}.Faults thead{background-color:rgb(230, 227, 227);}.Faults th,.Faults td{font-size:13px;padding:4px !important;}.fault-description{max-width:900px;}.critical{background-color:#C47474;font-weight:bold;}.major{background-color:#FCD37E}.Expand-All,.Collapse-All{font-size:12px;padding:5px;}.Expand-Collapse{margin-top:10px;margin-bottom:-10px;}.fi-modal-status td{width:20%;}.blade-general td{width:40%;}#FI-Details-Modal .modal-dialog{min-width:900px;}#FI-Details-Modal .progress{margin:0px;}#FI-Details-Modal .progress span{position: absolute;display: block;width: 100%;color: black;margin-left: 60px;}#FI-Detail-Pane .panel-body{padding:8px;}#FI-Details-Modal .modal-dialog{/*width:40%;-webkit-transition: width 0.35s ease;-moz-transition: width 0.35s ease;-o-transition: width 0.35s ease;transition: width 0.35s ease;*/}#FI-Storage-Collapse th, #FI-Storage-Collapse td{width:60%}#FI-Storage-Collapse th:nth-child(n+1), #FI-Storage-Collapse td:nth-child(n+1){width:30%}.wide-modal{width:60% !important;}.table-sort-pointer thead>tr{cursor:pointer;}#Blade-Details-Vifs .panel-heading{padding:6px 11px;}#Blade-Details-Vifs .panel-body{padding:5px;}#Template-Details-General tr,#Template-Details-General th{font-size:13px;}#Template-General-Maintenance-Collapse tbody>tr, #Template-General-Maintenance-Collapse tbody>th{font-size:13px;}#Template-Details-Storage legend,#Template-Details-Network legend, #Template-Details-Policies legend, #Template-Details-Boot legend{border-bottom:none;margin:0;padding:0px 5px;width:auto;font-weight:bold;font-size:14px;}#Template-Details-Storage .validate-section th,#Template-Details-Network .validate-section th, #Template-Details-Policies .validate-section th, #Template-Details-Boot .validate-section th{border-top:none;font-weight:normal;font-size:12px;}#Template-Details-Storage .validate-section td,#Template-Details-Network .validate-section td, #Template-Details-Policies .validate-section td, #Template-Details-Boot .validate-section td{border-top:none;font-weight:bold;font-size:12px;}#Template-Details-Storage fieldset,#Template-Details-Network fieldset, #Template-Details-Policies fieldset, #Template-Details-Boot fieldset{border:solid #dedede 1px !important;padding:10px !important;margin-bottom:10px;}#Template-Details-Storage table,#Template-Details-Network table, #Template-Details-Policies table{margin-bottom:auto;}.small-heading{padding:6px 11px;}.small-panel .panel-heading{padding:6px 11px;}.small-panel .panel-body{padding:10px;}.glyphicon-search{margin-right:4px;cursor:pointer;}.danger td{font-weight:bold;font-style:italic;}td.danger{font-weight:bold;font-style:italic;}.col-md-4{min-width:400px;}#Blade-Configured ul:not(:first-child){border-top:none !important;border-bottom:1px solid #ddd;list-style-type:none;margin:0;padding:0;}#Template-Blade-Configured ul:not(:first-child){border-top:none !important;border-bottom:1px solid #ddd;list-style-type:none;margin:0;padding:0;}.boot-entry td{border:none !important;}.boot-entry{width:auto;margin-top:8px;margin-bottom:0px}#LAN .panel, #SAN .panel, #Pools .panel{margin-top:20px;}.tabrow{list-style: none;padding: 0;padding-left: 10px;line-height: 24px;height: 26px;overflow: hidden;font-size: 12px;font-family: verdana;position: relative;}.tabrow li{border: 1px solid #AAA;background: #D1D1D1;background: -o-linear-gradient(top, #ECECEC 50%, #D1D1D1 100%);background: -ms-linear-gradient(top, #ECECEC 50%, #D1D1D1 100%);background: -moz-linear-gradient(top, #ECECEC 50%, #D1D1D1 100%);background: -webkit-linear-gradient(top, #ECECEC 50%, #D1D1D1 100%);background: linear-gradient(top, #ECECEC 50%, #D1D1D1 100%);display: inline-block;position: relative;z-index: 0;border-top-left-radius: 6px;border-top-right-radius: 6px;box-shadow: 0 3px 3px rgba(0, 0, 0, 0.4), inset 0 1px 0 #FFF;text-shadow: 0 1px #FFF;margin: 0 -5px;padding: 0 20px;}.tabrow a{color: #555;text-decoration: none;}.tabrow li.selected{background: #FFF;color: #333;z-index: 2;border-bottom-color: #FFF;}.tabrow:before{position: absolute;content: " ";width: 100%;bottom: 0;left: 0;border-bottom: 1px solid #AAA;z-index: 1;}.tabrow li:before,.tabrow li:after{border: 1px solid #AAA;position: absolute;bottom: -1px;width: 5px;height: 5px;content: " ";}.tabrow li:before{left: -6px;border-bottom-right-radius: 6px;border-width: 0 1px 1px 0;box-shadow: 2px 2px 0 #D1D1D1;}.tabrow li:after{right: -6px;border-bottom-left-radius: 6px;border-width: 0 0 1px 1px;box-shadow: -2px 2px 0 #D1D1D1;}.tabrow li.selected:before{box-shadow: 2px 2px 0 #FFF;}.tabrow li.selected:after{box-shadow: -2px 2px 0 #FFF;}.tree{min-height:20px;padding:19px;margin-bottom:20px;background-color:#fbfbfb;border:1px solid #999;-webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px;-webkit-box-shadow:inset 0 1px 1px rgba(0, 0, 0, 0.05);-moz-box-shadow:inset 0 1px 1px rgba(0, 0, 0, 0.05);box-shadow:inset 0 1px 1px rgba(0, 0, 0, 0.05)}.tree li{list-style-type:none;margin:0;padding:10px 5px 0 5px;position:relative}.tree li::before, .tree li::after{content:'';left:-20px;position:absolute;right:auto}.tree li::before{border-left:1px solid #999;bottom:50px;height:100%;top:0;width:1px}.tree li::after{border-top:1px solid #999;height:20px;top:25px;width:25px}.tree .border{-moz-border-radius:5px;-webkit-border-radius:5px;border:1px solid #999;border-radius:5px;padding:3px 8px;text-decoration:none;width:175px;margin-bottom:10px;cursor:pointer;}.tree .glyphicon{margin-right:6px;}.tree li.parent_li>span{cursor:pointer}.tree>ul>li::before, .tree>ul>li::after{border:0}.tree li:last-child::before{height:30px}.tree li.parent_li>span:hover, .tree li.parent_li>span:hover+ul li span{background:#eee;border:1px solid #94a0b4;color:#000}.Expand-Collapse button:first-of-type{margin-right:6px;}</style></head><body><div class="navbar navbar-inverse" role="navigation"><div class="container"><div class="navbar-header"><div class="navbar-brand logo-image"><span class="navbar-brand glyphicon glyphicon-plus glyphicon-white"></span></div><a class="navbar-brand" href="#"> UCS Health Check Report</a></div><div style="float:right;"><span class="navbar-brand">DATE_REPLACE</span></div></div></div><div class="container"><div class="panel panel-primary"><div class="panel-heading Domain-Heading" id="Domain-Heading"><h4 class="domain-heading">UCS Domain</h4><div class="btn-group" style="margin-top:-3px;"><button type="button" id="SelectedDomain" class="btn btn-default dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button><ul class="dropdown-menu" role="menu" id="DomainSelect"></ul></div></div><div class="panel-body"><ul class="nav nav-tabs" id="Report-Nav"><li class="active"><a href="#System" data-toggle="tab">System</a></li><li><a href="#Inventory" data-toggle="tab">Inventory</a></li><li><a href="#Policies" data-toggle="tab">Policies</a></li><li><a href="#Pools" data-toggle="tab">Pools</a></li><li><a href="#Profiles" data-toggle="tab">Service Profiles</a></li><li><a href="#LAN" data-toggle="tab">LAN</a></li><li><a href="#SAN" data-toggle="tab">SAN</a></li><li><a href="#Faults" data-toggle="tab">Fault Summary</a></li></ul><div class="tab-content main-content"><div class="tab-pane active System" id="System"><div class="panel panel-default" style="margin-top:20px;"><div class="panel-heading" id="ActiveDomain">Status</div><div class="panel-body"><div class="row Fault-Summary"><div class="col-md-4"><h4>Fault Summary</h4></div><div class="col-md-4"><table><tr id="System-Fault-Icons"><td><span class="glyphicon glyphicon-remove-circle fault-critical"></span></td><td><span class="glyphicon glyphicon-warning-sign fault-major pad"></span></td><td><span class="glyphicon glyphicon-warning-sign fault-minor pad"></span></td><td><span class="glyphicon glyphicon-warning-sign fault-warning pad"></span></td></tr><tr class="fault-counts"><td class="fault-critical-count">8</td><td class="fault-major-count">20</td><td class="fault-minor-count">30</td><td class="fault-warning-count">100</td></tr></table></div></div><div class="row validate-section"><div class="col-md-6 Table-Column"><table class="table SystemTable1"><tr><th>Virtual IP:</th><td id="system-vip"><a href="#" target="_blank"></a></td></tr><tr><th id="system-fi-a-label"></th><td id="system-fi-a-value"><a href="#" target="_blank"></a></td></tr><tr><th id="system-fi-b-label"></th><td id="system-fi-b-value"><a href="#" target="_blank"></a></td></tr><tr><th>UCSM Version:</th><td id="system-ucsm"></td></tr></table></div><div class="col-md-6 Table-Column"><table class="table SystemTable2"><tr><th>HA Ready:</th><td id="system-ha-ready"></td></tr><tr><th>Backup Policy:</th><td id="system-backup"></td></tr><tr><th>Config Export Policy:</th><td id="system-export"></td></tr><tr><th>Call Home State:</th><td id="system-callhome"></td></tr></table></div></div></div></div><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel-group" id="Chassis-Power" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Chassis-Power" href="#Chassis-Power-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Chassis Power Statistics</a></h4></div><div id="Chassis-Power-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed"><thead><tr><th>Dn</th><th>Input Pwr</th><th>Input Pwr Avg</th><th>Input Pwr Max</th><th>Output Pwr</th><th>Output Pwr Avg</th><th>Output Pwr Max</th><th>Suspect</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Server-Power" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Server-Power" href="#Server-Power-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Server Power Statistics</a></h4></div><div id="Server-Power-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed"><thead><tr><th>Dn</th><th>Consumed Pwr</th><th>Consumed Pwr Avg</th><th>Consumed Pwr Max</th><th>Input Current</th><th>Input Current Avg</th><th>Input Voltage</th><th>Input Voltage Avg</th><th>Suspect</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Server-Temp" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Server-Temp" href="#Server-Temp-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Server Temperature Statistics</a></h4></div><div id="Server-Temp-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed"><thead><tr><th>Dn</th><th>Sensor-1</th><th>Sensor-1 Avg</th><th>Sensor-1 Max</th><th>Sensor-2</th><th>Sensor-2</th><th>Sensor-2</th><th>Suspect</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane Inventory" id="Inventory"><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel-group" id="FabricInterconnect" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#FabricInterconnect" href="#collapse1"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Fabric Interconnects</a></h4><div style="float:right;"><span class="glyphicon glyphicon-search"></span><span class="glyphicon glyphicon-eye-open"></span></div></div><div id="collapse1" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered table-condensed table-hover"><thead><tr><th>Fabric ID</th><th>Cluster Role</th><th>Model</th><th>Serial</th><th>System</th><th>Kernel</th><th>IP</th><th>Ports Used</th><th>Ports Licensed</th><th>Operability</th><th>Thermal</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Chassis" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Chassis" href="#Chassis-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Chassis</a></h4><div style="float:right;"><span class="glyphicon glyphicon-search"></span><span class="glyphicon glyphicon-eye-open"></span></div></div><div id="Chassis-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered table-condensed table-hover small-table"><thead><tr><th>ID</th><th>Model</th><th>Serial</th><th>Status</th><th>Operability</th><th>Power</th><th>Power Redundancy</th><th>Thermal</th><th>PSUs</th><th>Slots Used</th><th>Slots Available</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="IOMs" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#IOMs" href="#collapse2"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>IOMs</a></h4><div style="float:right;"><span class="glyphicon glyphicon-search"></span><span class="glyphicon glyphicon-eye-open"></span></div></div><div id="collapse2" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered table-condensed table-hover"><thead><tr><th>Chassis</th><th>Fabric ID</th><th>Model</th><th>Serial</th><th>Channel</th><th>Running Firmware</th><th>Backup Firmware</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Blades" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Blades" href="#collapse3"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Blades</a></h4><div style="float:right;"><span class="glyphicon glyphicon-search"></span><span class="glyphicon glyphicon-eye-open"></span></div></div><div id="collapse3" class="panel-collapse collapse in"><div class="panel-body table-responsive pointer"><table class="table table-bordered table-condensed table-hover"><thead><tr><th class="hidden">Dn</th><th>Chassis</th><th>Slot</th><th>Model</th><th>Serial</th><th>Service Profile</th><th>CPU</th><th class="visible-medium">Cores</th><th class="visible-medium">Threads</th><th>Memory (GB)</th><th class="visible-large">Speed</th><th class="visible-medium">BIOS</th><th>CIMC</th><th class="visible-large">Adapter-1</th><th class="visible-large">Adapter-1 FW</th><th class="visible-large">Adapter-2</th><th class="visible-large">Adapter-2 FW</th><th>Status</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Racks" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Racks" href="#collapse4"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Rack Servers</a></h4><div style="float:right;"><span class="glyphicon glyphicon-search"></span><span class="glyphicon glyphicon-eye-open"></span></div></div><div id="collapse4" class="panel-collapse collapse in"><div class="panel-body pointer"><table class="table table-bordered table-condensed"><thead><tr><th>Rack ID</th><th>Model</th><th>Serial</th><th>Service Profile</th><th>CPU</th><th>Cores</th><th>Threads</th><th>Memory (GB)</th><th>Speed</th><th>BIOS</th><th>CIMC</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="RackAdapters" style="margin-top:20px;"><div class="panel panel-default"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#RackAdapters" href="#collapse5"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Rack Adapters</a></h4></div><div id="collapse5" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered table-condensed"><thead><tr><th>Rack ID</th><th>Slot</th><th>Model</th><th>Serial</th><th>Running FW</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane Policies" id="Policies"><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel-group" id="SystemPolicies" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#SystemPolicies" href="#SystemPoliciesCollapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>System Policies</a></h4></div><div id="SystemPoliciesCollapse" class="panel-collapse collapse in"><div class="panel-body"><div class="row validate-section"><div class="col-md-6 Table-Column"><table class="table SystemTable"><tr><th>DNS Servers:</th><td><ul id="policy-dns"></ul></a></td></tr><tr><th>Chassis Discovery Action:</th><td id="policy-action"></td></tr><tr><th>Chassis Discovery Grouping:</th><td id="policy-grouping"></td></tr><tr><th>Timezone:</th><td id="policy-timezone"></td></tr></table></div><div class="col-md-6 Table-Column"><table class="table SystemTable2"><tr><th>NTP Servers:</th><td><ul id="policy-ntp"></ul></td></tr><tr><th>Chassis Power Redundancy:</th><td id="policy-power"></td></tr><tr><th>Default Maintenance Policy:</th><td id="policy-maint"></td></tr></table></div></div></div></div></div></div><div class="panel-group" id="Maintenance-Policy" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Maintenance-Policy" href="#Maintenance-Policy-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>Maintenance Policies</a></h4></div><div id="Maintenance-Policy-Collapse" class="panel-collapse collapse"><div class="panel-body"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>Dn</th><th>Reboot Policy</th><th>Description</th><th>Schedule</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Host-FW" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Host-FW" href="#Host-FW-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>Host Firmware Packages</a></h4></div><div id="Host-FW-Collapse" class="panel-collapse collapse"><div class="panel-body"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>Blade Bundle Version</th><th>Rack Bundle Version</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="LDAP" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#LDAP" href="#LDAP-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>LDAP</a></h4></div><div id="LDAP-Collapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Providers</h4><table class="Providers table table-bordered table-condensed small-table"><thead><tr><th>Hostname</th><th>Root DN</th><th>Base DN</th><th>Attribute</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Group Maps</h4><table class="Mappings table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>Roles</th><th>Locales</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane Pools" id="Pools"><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel-group" id="MgmtPool" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#MgmtPool" href="#MgmtPoolCollapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>Mgmt IP Pool</a></h4></div><div id="MgmtPoolCollapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Pools</h4><table class="Pools table table-bordered table-condensed small-table"><thead><tr><th>From</th><th>To</th><th>Size</th><th>Assigned</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Allocations</h4><table class="Assignments table table-bordered table-condensed small-table"><thead><tr><th>Dn</th><th>IP</th><th>Subnet</th><th>Default Gateway</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="UUID" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#UUID" href="#UUID-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>UUID Pools</a></h4></div><div id="UUID-Collapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Pools</h4><table class="Pools table table-bordered table-condensed small-table"><thead><tr><th>Dn</th><th>Name</th><th>Assignment Order</th><th>Prefix</th><th>Size</th><th>Assigned</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Allocation</h4><table class="Assignments table table-bordered table-condensed small-table"><thead><tr><th>Assigned To Dn</th><th>Id</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel-group" id="Server_Pools" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Server_Pools" href="#Server_Pools-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>Server Pools</a></h4></div><div id="Server_Pools-Collapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Pools</h4><table class="Pools table table-bordered table-condensed small-table"><thead><tr><th>Dn</th><th>Name</th><th>Size</th><th>Assigned</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Allocation</h4><table class="Assignments table table-bordered table-condensed small-table"><thead><tr><th>Assigned To Dn</th><th>Name</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" href="#Pools-Mac-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>MAC Pools</a></h4></div><div id="Pools-Mac-Collapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Pools</h4><table class="Pools table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>From</th><th>To</th><th>Size</th><th>Assigned</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Allocations</h4><table class="Assignments table table-bordered table-condensed small-table"><thead><tr><th>ID</th><th>Assigned</th><th>Assigned To</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" href="#Pools-Ip-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>IP Pools</a></h4></div><div id="Pools-Ip-Collapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Pools</h4><table class="Pools table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>From</th><th>To</th><th>Size</th><th>Assigned</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Allocations</h4><table class="Assignments table table-bordered table-condensed small-table"><thead><tr><th>ID</th><th>Assigned</th><th>Assigned To</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" href="#Pools-Wwn-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span>WWN Pools</a></h4></div><div id="Pools-Wwn-Collapse" class="panel-collapse collapse"><div class="panel-body"><h4 style="font-size:16px;font-weight:bold;">Pools</h4><table class="Pools table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>From</th><th>To</th><th>Size</th><th>Assigned</th></tr></thead><tbody></tbody></table><h4 style="font-size:16px;font-weight:bold;">Allocations</h4><table class="Assignments table table-bordered table-condensed small-table"><thead><tr><th>ID</th><th>Assigned</th><th>Assigned To</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="tab-pane Profiles" id="Profiles"><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel-group hidden" id="Profile-Template"><div class="panel panel-default"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Template-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span></a></h4><div class="Template-Heading"><h4 class="profile-type">Type: N/A</h4><span class="glyphicon glyphicon-search"></span><span class="glyphicon glyphicon-eye-open" style="margin-right:8px;"></span><span class="glyphicon glyphicon-new-window expand-template"></span></div></div><div id="Template-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered table-condensed table-hover pointer"><thead><tr><th class="hidden">Dn</th><th>Service Profile</th><th>User Label</th><th>Assigned Server</th><th>Association State</th><th>Maint Policy</th><th>FW Policy</th><th>BIOS Policy</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane LAN" id="LAN"><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" href="#Lan-Qos-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>System QoS</a></h4></div><div id="Lan-Qos-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead><tr><th>Priority</th><th>Enabled</th><th>CoS</th><th>Packet Drop</th><th>Weight</th><th>Weight(%)</th><th>MTU</th><th>Multicast Optimized</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" href="#Lan-Vlan-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>VLANs</a></h4></div><div id="Lan-Vlan-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead><tr><th>Name</th><th>ID</th><th>Fabric ID</th><th>Type</th><th>Transport</th><th>Native</th><th>VLAN Sharing</th><th>Primary VLAN</th><th>Multicast Policy</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Lan-Uplinks-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>LAN Uplinks</a></h4></div><div id="Lan-Uplinks-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead style="font-size:12px;"><tr><th>Fabric</th><th>Port</th><th>MAC</th><th>If Type</th><th>Speed</th><th>Xcvr</th><th>Avg Mbps Rx</th><th>Avg Mbps Tx</th><th>Status</th><th>State</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Lan-ServerPorts-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Server Links</a></h4></div><div id="Lan-ServerPorts-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead style="font-size:12px;"><tr><th>Fabric</th><th>Port</th><th>MAC</th><th>If Type</th><th>Speed</th><th>Xcvr</th><th>Avg Mbps Rx</th><th>Avg Mbps Tx</th><th>Status</th><th>State</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Lan-Control-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Network Control Policies</a></h4></div><div id="Lan-Control-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead style="font-size:12px;"><tr><th>Name</th><th>DN</th><th>Description</th><th>Owner</th><th>CDP</th><th>MAC Register Mode</th><th>Action on Uplink Fail</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Lan-QosPolicy-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>QoS Policies</a></h4></div><div id="Lan-QosPolicy-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead style="font-size:12px;"><tr><th>Name</th><th>Owner</th><th>Priority</th><th>Burst</th><th>Rate</th><th>Host Control</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="tab-pane LAN" id="SAN"><div class="Expand-Collapse"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" href="#San-Vsan-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>VSANs</a></h4></div><div id="San-Vsan-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead><tr><th>ID</th><th>Name</th><th>Fabric ID</th><th>FCoE VLAN</th><th>If Role</th><th>Transport</th><th>Zoning State</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#San-UplinkPorts-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>SAN Uplink Ports</a></h4></div><div id="San-UplinkPorts-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead style="font-size:12px;"><tr><th>Fabric</th><th>Port</th><th>MAC</th><th>If Type</th><th>Speed</th><th>Xcvr</th><th>Avg Mbps Rx</th><th>Avg Mbps Tx</th><th>Status</th><th>State</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#San-StoragePorts-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Storage Ports</a></h4></div><div id="San-StoragePorts-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered small-table table-condensed table-hover pointer"><thead style="font-size:12px;"><tr><th>Fabric</th><th>Port</th><th>MAC</th><th>If Type</th><th>Speed</th><th>Xcvr</th><th>Avg Mbps Rx</th><th>Avg Mbps Tx</th><th>Status</th><th>State</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="tab-pane Faults" id="Faults"><div class="panel panel-primary" style="margin-top:20px;"><div class="panel-heading">Fault Summary</div><div class="panel-body"><table class="table table-bordered table-condensed"><thead><tr><th>Severity</th><th>Description</th><th>Affected Object</th><th>Date Created</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div style="display:none;padding:0px 20px 20px 20px;" id="FI-Details-Modal" class="details-div"><div><button type="button" class="btn btn-default btn-sm details-close" style="margin-top:-20px;float:right;"><span class="glyphicon glyphicon-remove"></span> Exit Details</button><legend></legend><ul class="nav nav-pills"><li class="active"><a href="#FI-General" data-toggle="pill">General</a></li><li><a href="#FI-Ports" data-toggle="pill">Fabric Ports</a></li></ul><div class="tab-content"><div class="tab-pane active" id="FI-General"><div class="row" style="margin-top:10px;"><div class="col-md-4 details-general"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Overall Status</th><td id="fi-status"></td></tr><tr><th>Thermal</th><td id="fi-thermal"></td></tr><tr><th>Model</th><td id="fi-model"></td></tr><tr><th>Ethernet Mode</th><td id="fi-ethernet-mode"></td></tr><tr><th>FC Mode</th><td id="fi-fc-mode"></td></tr><tr><th>IP Address</th><td id="fi-ip"></td></tr><tr><th>Leadership</th><td id="fi-leadership"></td></tr></table></div></div><div class="panel-group small-panel" id="FI-Detail-Pane"><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#FI-Detail-Pane" href="#FI-Storage-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Local Storage Information</a></h4></div><div id="FI-Storage-Collapse" class="panel-collapse collapse in"><div class="panel-body"><div class="row"><div class="col-md-4"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Partition</th><th>Size (MB)</th><th>Used</th></tr></thead><tbody><tr id="fi-storage-template" class="hidden"><td></td><td></td><td><div class="progress"><div class="progress-bar" role="progressbar" aria-valuemin="0" aria-valuemax="100"></div><span></span></div></td></tr></tbody></table></div></div></div></div></div><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#FI-Detail-Pane" href="#FI-VLAN-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>VLAN Port Count</a></h4></div><div id="FI-VLAN-Collapse" class="panel-collapse collapse in"><div class="panel-body"><div class="row" style="margin-top:10px;"><div class="col-md-4"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>VLAN Port Limit</th><td id="fi-vlan-limit"></td></tr><tr><th>Access VLAN Port Count</th><td id="fi-access-vlan-count"></td></tr><tr><th>Border VLAN Port Count</th><td id="fi-border-vlan-count"></td></tr><tr><th>Allocation Status</th><td id="fi-vlan-alloc"></td></tr></table></div></div></div></div></div><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#FI-Detail-Pane" href="#FI-Zone-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>FC Zone Count</a></h4></div><div id="FI-Zone-Collapse" class="panel-collapse collapse in"><div class="panel-body"><div class="row" style="margin-top:10px;"><div class="col-md-4"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>FC Zone Limit</th><td id="fi-zone-limit"></td></tr><tr><th>FC Zone Count</th><td id="fi-zone-count"></td></tr><tr><th>Allocation Status</th><td id="fi-fc-alloc"></td></tr></table></div></div></div></div></div></div></div><div class="tab-pane" id="FI-Ports" style="margin-top:20px;"><div class="panel panel-primary small-panel"><div class="panel-heading"><h4 class="panel-title">Port Configuration</h4></div><div class="panel-body"><div class="row" style="margin-top:10px;"><div class="col-md-12"><table class="table table-bordered table-condensed small-table table-sort-pointer"><thead><tr><th>Dn</th><th>If Role</th><th>Lic State</th><th>Lic GP</th><th>Mode</th><th>Oper State</th><th>Oper Speed</th><th>Xcvr Type</th><th>PeerDn</th><th>Peer Port Id</th><th>Peer Slot Id</th></tr></thead><tbody></tbody></table></div></div></div></div></div></div></div></div><div style="display:none;padding:0px 20px 20px 20px;" id="Chassis-Details" class="details-div"><div><button type="button" class="btn btn-default btn-sm details-close" style="margin-top:-20px;float:right;"><span class="glyphicon glyphicon-remove"></span> Exit Details</button><legend></legend><ul class="nav nav-pills"><li class="active"><a href="#Chassis-General" data-toggle="pill">General</a></li></ul><div class="tab-content"><div class="tab-pane active" id="Chassis-General"><div class="row" style="margin-top:10px;"><div class="col-md-4 details-general"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Overall Status</th><td id="chassis-status"></td></tr><tr><th>Model</th><td id="chassis-model"></td></tr><tr><th>Avg Power</th><td id="chassis-power"></td></tr><tr><th>Power Redundancy</th><td id="chassis-power-redundancy"></td></tr><tr><th>Serial</th><td id="chassis-serial"></td></tr><tr><th>Slots Used</th><td id="chassis-total-slots"></td></tr><tr><th>Slots Available</th><td id="chassis-free-slots"></td></tr></table></div></div><div class="panel-group small-panel" id="Chassis-General-Pane"><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Chassis-General-Pane" href="#Chassis-Iom-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>IOMs</a></h4></div><div id="Chassis-Iom-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Fabric</th><th>Model</th><th>Serial</th><th>Fw</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Chassis-General-Pane" href="#Chassis-Slots-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Blades</a></h4></div><div id="Chassis-Slots-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Slot</th><th>Model</th><th>Width</th><th>Serial</th><th>Service Profile</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Chassis-General-Pane" href="#Chassis-Psu-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>PSUs</a></h4></div><div id="Chassis-Psu-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Slot</th><th>Type</th><th>Model</th><th>Serial</th></tr></thead><tbody></tbody></table></div></div></div></div></div></div></div></div><div style="display:none;padding:0px 20px 20px 20px;" id="IOM-Details" class="details-div"><div><button type="button" class="btn btn-default btn-sm details-close" style="margin-top:-20px;float:right;"><span class="glyphicon glyphicon-remove"></span> Exit Details</button><legend></legend><ul class="nav nav-pills"><li class="active"><a href="#IOM-Fabric-Ports" data-toggle="pill">Fabric Ports</a></li><li><a href="#IOM-Backplane-Ports" data-toggle="pill">Backplane Ports</a></li></ul><div class="tab-content"><div class="tab-pane active" id="IOM-Fabric-Ports" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title">Fabric Ports</h4></div><div class="panel-body"><div class="row" style="margin-top:10px;"><div class="col-md-12"><table class="table table-bordered table-condensed small-table table-sort-pointer"><thead><tr><th>Name</th><th>Oper State</th><th>Port Channel</th><th>Peer Slot ID</th><th>Peer Port ID</th><th>FabricId</th><th>Acknowledged</th><th>Peer</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane" id="IOM-Backplane-Ports" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title">Backplane Ports</h4></div><div class="panel-body"><div class="row" style="margin-top:10px;"><div class="col-md-12"><table class="table table-bordered table-condensed small-table table-sort-pointer"><thead><tr><th>Name</th><th>Oper State</th><th>Port Channel</th><th>FabricId</th><th>Peer</th></tr></thead><tbody></tbody></table></div></div></div></div></div></div></div></div><div style="display:none;padding:0px 20px 20px 20px;" id="Blade-Details" class="details-div"><div><button type="button" class="btn btn-default btn-sm details-close" style="margin-top:-20px;float:right;"><span class="glyphicon glyphicon-remove"></span> Exit Details</button><legend></legend><ul class="nav nav-pills"><li class="active"><a href="#Blade-Details-General" data-toggle="pill">General</a></li><li><a href="#Blade-Details-Memory" data-toggle="pill">Memory</a></li><li><a href="#Blade-Details-Boot" data-toggle="pill">Boot Order</a></li><li><a href="#Blade-Details-Storage" data-toggle="pill">Storage</a></li><li><a href="#Blade-Details-Vifs" data-toggle="pill">VIF Paths</a></li></ul><div class="tab-content"><div class="tab-pane active" id="Blade-Details-General" style="margin-top:20px;"><div class="row" style="margin-top:10px;"><div class="col-md-4"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Overall Status</th><td id="blade-status"></td></tr><th>Model</th><td id="blade-model"></td></tr><tr><th>Name</th><td id="blade-name"></td></tr><tr><th>User Label</th><td id="blade-usrlbl"></td></tr><tr><th>Assigned Profile</th><td id="blade-service-profile"></td></tr><tr><th>UUID</th><td id="blade-uuid"></td></tr><tr><th>Serial</th><td id="blade-serial"></td></tr><tr><th>CPU</th><td id="blade-cpu"></td></tr><tr><th>Cores</th><td id="blade-cores"></td></tr><tr><th>Threads</th><td id="blade-threads"></td></tr><tr><th>Effective Memory</th><td id="blade-memory"></td></tr><tr><th>Description</th><td id="blade-description"></td></tr></table></div></div><div class="panel-group small-panel" id="Blade-General-Pane"><div class="panel panel-primary"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" data-parent="#Blade-General-Pane" href="#Blade-Details-Adapter-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Adapters</a></h4></div><div id="Blade-Details-Adapter-Collapse" class="panel-collapse collapse in"><div class="panel-body table-responsive"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>Model</th><th>Fw</th><th>Serial</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane" id="Blade-Details-Memory" style="margin-top:20px;"><div class="panel panel-primary small-panel"><div class="panel-heading"><h4 class="panel-title">Memory</h4></div><div class="panel-body"><div class="row" style="margin-top:10px;"><div class="col-md-12"><table class="table table-bordered table-condensed small-table table-sort-pointer"><thead><tr><th>Name</th><th>Location</th><th>Capacity (GB)</th><th>Clock (Mhz)</th></tr></thead><tbody></tbody></table></div></div></div></div></div><div class="tab-pane" id="Blade-Details-Boot" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title">Boot Order Details</h4></div><div class="panel-body"><ul class="tabrow boot-nav" id="Blade-Boot-Nav"><li class="selected"><a href="#Blade-Configured" data-toggle="tab">Configured Boot Order</a></li><li><a href="#Blade-Actual" data-toggle="tab">Actual Boot Order</a></li></ul><div id="Blade-Configured" class="boot-nav-toggle"><div class="row" style="margin-top:10px;"><div class="col-md-12"><table class="table table-bordered table-condensed small-table table-sort-pointer" style="margin-bottom:0px"><thead><tr><th style="width:30%;">Name</th><th style="width:5%;">Order</th><th style="width:20%;">vNIC/vHBA/iSCSI vNIC</th><th style="width:20%;">Type</th><th style="width:5%;">Lun ID</th><th style="width:30%;">WWN</th></tr></thead><tbody></tbody></table><ul style="list-style-type:none;padding:0;"><li><table class="table table-condensed"style="width:100%;"><thead style="font-size:12px;"><tr><th style="padding:5px;"><span class="glyphicon glyphicon-plus"></span>Name-2</th><th style="padding:5px;">MAC Address-2</th><th style="padding:5px;">Desired Order-2</th><th style="padding:5px;">Actual Order-2</th><th style="padding:5px;">Fabric ID-2</th><th style="padding:5px;">Desired Placement-2</th><th style="padding:5px;">Actual Placement-2</th></tr></thead><tbody></tbody></table></li></ul></div></div></div><div id="Blade-Actual" class="boot-nav-toggle"><div class="tree well"><ul style="padding:0px;"></ul></div></div></div></div></div><div class="tab-pane" id="Blade-Details-Storage" style="margin-top:20px;"><div class="panel-group hidden controller-group small-panel" id="Blade-Storage-Template" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="" href=""><span class="glyphicon glyphicon-minus glyphicon-white heading-icon controller-heading"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden controller-title controller-heading"></span></a></h4></div><div class="panel-collapse collapse in controller-collapse"><div class="panel-body"><div class="row validate-section"><div class="col-md-3 Table-Column"><table class="table table-condensed SystemTable1 small-table small-th-table table-striped"><tr><th>ID:</th><td class="blade-controller-id"></td></tr><tr><th>Vendor:</th><td class="blade-controller-vendor"></td></tr><tr><th>Revision:</th><td class="blade-controller-revision"></td></tr><tr><th>Raid Support:</th><td class="blade-controller-raid"></td></tr><tr><th>PCIe Address:</th><td class="blade-controller-pciAddr"></td></tr><tr><th>Number of Disks:</th><td class="blade-controller-numDisks"></td></tr><tr><th>Rebuild Rate:</th><td class="blade-controller-rebRate"></td></tr></table></div><div class="col-md-3 Table-Column"><table class="table table-condensed SystemTable2 small-table small-th-table table-striped"><tr><th>Pid:</th><td class="blade-controller-pid"></td></tr><tr><th>Serial:</th><td class="blade-controller-serial"></td></tr><tr><th>Controller Status:</th><td class="blade-controller-status"></td></tr></table></div></div></div></div><div class="panel-group hidden small-panel" id="Blade-Disk-Template" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title"><a data-toggle="collapse" data-parent="" href=""><span class="glyphicon glyphicon-minus glyphicon-white heading-icon hidden"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon"></span></a></h4></div><div class="panel-collapse collapse"><div class="panel-body"><div class="row validate-section"><div class="col-md-6 Table-Column"><table class="table table-condensed SystemTable1 small-table"><tr><th>ID:</th><td class="blade-disk-id"></td></tr><tr><th>Vendor:</th><td class="blade-disk-vendor"></td></tr><tr><th>Serial:</th><td class="blade-disk-serial"></td></tr><tr><th>Pid:</th><td class="blade-disk-pid"></td></tr><tr><th>Vid:</th><td class="blade-disk-vid"></td></tr><tr><th>Drive State:</th><td class="blade-disk-driveState"></td></tr><tr><th>Size (GB):</th><td class="blade-disk-size"></td></tr><tr><th>Number of Blocks:</th><td class="blade-disk-numBlocks"></td></tr><tr><th>Block Size:</th><td class="blade-disk-blockSize"></td></tr></table></div><div class="col-md-6 Table-Column"><table class="table table-condensed SystemTable2 small-table"><tr><th>Technology:</th><td class="blade-disk-technology"></td></tr><tr><th>Power State:</th><td class="blade-disk-powerState"></td></tr><tr><th>Link Speed:</th><td class="blade-disk-linkSpeed"></td></tr><tr><th>Track to Seek (R/W):</th><td class="blade-disk-tts"></td></tr><tr><th>Operability:</th><td class="blade-disk-operability"></td></tr><tr><th>Presence:</th><td class="blade-disk-presence"></td></tr><tr><th>Running Version:</th><td class="blade-disk-runningVersion"></td></tr></table></div></div></div></div></div></div></div></div></div><div class="tab-pane" id="Blade-Details-Vifs" style="margin-top:20px;"><div class="Expand-Collapse" style="margin-bottom:10px;"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div id="Blade-Vifs-Template" class="panel panel-primary hidden small-panel"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" href=""><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span></a></h4></div><div class="panel-collapse collapse in"><div class="panel-body table-responsive"><h5>Physical Path</h5><table class="table table-bordered table-condensed small-table physical"><thead><tr><th>Adapter Port</th><th>FEX Host Port</th><th>FEX Network Port</th><th>FI Server Port</th></tr></thead><tbody></tbody></table><h5>Virtual Circuits</h5><table class="table table-bordered table-condensed small-table vifs"><thead><tr><th>Name</th><th>vNIC</th><th>FI Uplink</th><th>Link State</th></tr></thead><tbody></tbody></table></div></div></div></div></div></div></div><div style="display:none;padding:0px 20px 20px 20px;" id="Template-Details" class="details-div"><div><button type="button" class="btn btn-default btn-sm details-close" style="margin-top:-20px;float:right;"><span class="glyphicon glyphicon-remove"></span> Exit Details</button><legend></legend><ul class="nav nav-pills"><li class="active"><a href="#Template-Details-General" data-toggle="pill">General</a></li><li><a href="#Template-Details-Storage" data-toggle="pill">Storage</a></li><li><a href="#Template-Details-Network" data-toggle="pill">Network</a></li><li><a href="#Template-Details-iSCSI" data-toggle="pill">iSCSI</a></li><li><a href="#Template-Details-Boot" data-toggle="pill">Boot Order</a></li><li><a href="#Template-Details-Policies" data-toggle="pill">Policies</a></li><li><a href="#Template-Details-Vifs" data-toggle="pill" class="instance">VIFs</a></li><li><a href="#Template-Details-Performance" data-toggle="pill" class="instance">Performance</a></li></ul><div class="tab-content"><div class="tab-pane active" id="Template-Details-General" style="margin-top:20px;"><div class="row validate-section"><div class="col-md-4 Table-Column"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Name:</th><td class="template-general-name"></td></tr><tr><th class="instance">Overall Status:</th><td class="template-general-status instance"></td></tr><tr><th class="instance">Assoc State:</th><td class="template-general-assocState instance"></td></tr><tr><th class="instance">User Label:</th><td class="template-general-userLabel instance"></td></tr><tr><th>Description:</th><td class="template-general-description"></td></tr><tr><th class="instance">Owner:</th><td class="template-general-owner instance"></td></tr><tr><th class="instance">UUID:</th><td class="template-general-uuid instance"></td></tr><tr><th>UUID Pool:</th><td class="template-general-uuidPool"></td></tr><tr><th class="instance">Associated Server:</th><td class="template-general-server instance"></td></tr><tr><th class="instance">Service Profile Template:</th><td class="template-general-template instance"></td></tr><tr><th>Power State:</th><td class="template-general-power"></td></tr><tr><th class="template">Type:</th><td class="template-general-type template"></td></tr><tr><th class="template">Access Policy:</th><td class="template-general-access template"></td></tr></table></div></div><div id="Template-General-ServerPool" class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Template-General-ServerPool-Collapse" class="template"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Associated Server Pool</a><a data-toggle="collapse" href="#Template-General-ServerPool-Collapse" class="instance"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Assigned Server or Server Pool</a></h4></div><div id="Template-General-ServerPool-Collapse" class="panel-collapse collapse in"><div class="panel-body"><div class="row validate-section template-assignment-pool template"><div class="col-md-4 Table-Column"><h5>Nothing Selected</h5><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Server Pool:</th><td class="template-srvpool-name"></td></tr><tr><th>Server Pool Qualification:</th><td class="template-srvpool-qualification"></td></tr><tr><th>Restrict Migration:</th><td class="template-srvpool-restrictMigration"></td></tr></table></div></div><div class="row validate-section instance template-assignment-server"><div class="col-md-4 Table-Column"><h5>Nothing Selected</h5><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Server Server:</th><td class="template-server-name"></td></tr><tr><th>Restrict Migration:</th><td class="template-srvpool-restrictMigration"></td></tr></table></div></div></div></div></div><div id="Template-General-Maintenance" class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Template-General-Maintenance-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>Maintenance Policy</a></h4></div><div id="Template-General-Maintenance-Collapse" class="panel-collapse collapse in"><div class="panel-body"><div class="row validate-section"><div class="col-md-4 Table-Column"><table class="table table-condensed blade-general small-table small-th-table table-striped"><tr><th>Name:</th><td class="template-maint-name"></td></tr><tr><th>Maintenance Policy Instance:</th><td class="template-maint-instance"></td></tr><tr><th>Description:</th><td class="template-maint-description"></td></tr><tr><th>Reboot Policy:</th><td class="template-maint-rebootPolicy"></td></tr></table></div></div></div></div></div></div><div class="tab-pane" id="Template-Details-Storage" style="margin-top:20px;"><div class="row validate-section"><div class="col-md-6 Table-Column"><fieldset><legend>World Wide Node Name</legend><table class="table table-condensed SystemTable1"><tr><th>World Wide Node Name:</th><td class="template-storage-nwwn"></td></tr><tr><th>WWNN Pool:</th><td class="template-storage-nwwnPool"></td></tr></table></fieldset></div><div class="col-md-6 Table-Column"><fieldset><legend>SAN Connectivity Policy</legend><table class="table table-condensed SystemTable1"><tr><th>SAN Connectivity Policy:</th><td class="template-storage-connPolicy"></td></tr><tr><th>Policy Instance:</th><td class="template-storage-connInstance"></td></tr></table></fieldset></div></div><div class="row validate-section"><div class="col-md-6 Table-Column"><fieldset><legend>Local Disk Configuration Policy</legend><table class="table table-condensed SystemTable1"><tr><th>Mode:</th><td class="template-storage-ldMode"></td></tr><tr><th>Protect Configuration:</th><td class="template-storage-ldProtect"></td></tr><tr><th>FlexFlash State:</th><td class="template-storage-ldFfState"></td></tr><tr><th>FlexFlash RAID Reporting State:</th><td class="template-storage-ldFfReporting"></td></tr></table></fieldset></div></div><div id="Template-Details-vHBAs" class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Template-Details-vHBAs-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>vHBAs</a></h4></div><div id="Template-Details-vHBAs-Collapse" class="panel-collapse collapse in"><div class="panel-body"><table class="table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>WWPN</th><th>Desired Order</th><th>Fabric ID</th><th>Actual Order</th><th>Desired Placement</th><th>Actual Placement</th><th>VSAN</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="tab-pane" id="Template-Details-Network" style="margin-top:20px;"><div class="row validate-section"><div class="col-md-6 Table-Column"><fieldset><legend>Network Policies</legend><table class="table table-condensed table-striped SystemTable1"><tr><th>Dynamic vNIC Connection Policy:</th><td class="template-network-dynamic"></td></tr><tr><th>LAN Connectivity Policy:</th><td class="template-network-connectivity"></td></tr></table></fieldset></div></div><div id="Template-Details-vNICs" class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title"><a data-toggle="collapse" href="#Template-Details-vNICs-Collapse"><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span>vNICs</a></h4></div><div id="Template-Details-vNICs-Collapse" class="panel-collapse collapse in"><div class="panel-body"><div class="Toggle-Collapse" style="margin-bottom:10px;"><button type="button" class="btn btn-xs toggle-expand-all"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-xs toggle-collapse-all"><span class="glyphicon glyphicon-minus"></span></button></div><table class="table table-bordered table-condensed small-table"><thead><tr><th>Name</th><th>MAC Address</th><th>Desired Order</th><th>Actual Order</th><th>Fabric ID</th><th>Desired Placement</th><th>Actual Placement</th><th class="visible-large">Adaptor Profile</th><th class="visible-large">Control Policy</th></tr></thead><tbody></tbody></table><ul style="list-style-type:none;padding:0;"><li><table class="table table-condensed"style="width:100%;"><thead style="font-size:12px;"><tr><th style="border: 1px solid #ddd;padding:5px;"><span class="glyphicon glyphicon-plus"></span>Name-2</th><th style="border: 1px solid #ddd;padding:5px;">MAC Address-2</th><th style="border: 1px solid #ddd;padding:5px;">Desired Order-2</th><th style="border: 1px solid #ddd;padding:5px;">Actual Order-2</th><th style="border: 1px solid #ddd;padding:5px;">Fabric ID-2</th><th style="border: 1px solid #ddd;padding:5px;">Desired Placement-2</th><th style="border: 1px solid #ddd;padding:5px;">Actual Placement-2</th></tr></thead><tbody></tbody></table></li></ul></div></div></div></div><div class="tab-pane" id="Template-Details-iSCSI" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title">iSCSI vNICs</h4></div><div id="Template-Details-iSCSI-Collapse"><div class="panel-body"><table class="table table-condensed small-table table-bordered"style="width:100%;"><thead style="font-size:12px;"><tr><th>Name</th><th>Overlay</th><th>IQN</th><th>VLAN</th><th>Adapter Policy</th><th>MAC Address</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="tab-pane" id="Template-Details-Vifs" style="margin-top:20px;"><div class="Expand-Collapse" style="margin-bottom:10px;"><button type="button" class="btn btn-primary Expand-All"><span class="glyphicon glyphicon-plus"></span></button><button type="button" class="btn btn-primary Collapse-All"><span class="glyphicon glyphicon-minus"></span></button></div><div id="Profile-Vifs-Template" class="panel panel-primary hidden small-panel"><div class="panel-heading"><h4 class="panel-title"><a data-toggle="collapse" href=""><span class="glyphicon glyphicon-minus glyphicon-white heading-icon"></span><span class="glyphicon glyphicon-th-list glyphicon-white heading-icon hidden"></span></a></h4></div><div class="panel-collapse collapse in"><div class="panel-body table-responsive"><h5>Physical Path</h5><table class="table table-bordered table-condensed small-table physical"><thead><tr><th>Adapter Port</th><th>FEX Host Port</th><th>FEX Network Port</th><th>FI Server Port</th></tr></thead><tbody></tbody></table><h5>Virtual Circuits</h5><table class="table table-bordered table-condensed small-table vifs"><thead><tr><th>Name</th><th>vNIC</th><th>FI Uplink</th><th>Link State</th></tr></thead><tbody></tbody></table></div></div></div></div><div class="tab-pane" id="Template-Details-Boot" style="margin-top:20px;"><div class="row validate-section"><div class="col-md-6 Table-Column"><fieldset><legend>Boot Policy</legend><table class="table table-condensed table-striped SystemTable1"><tr><th>Name:</th><td class="template-boot-name"></td></tr><tr><th>Boot Policy Instance:</th><td class="template-boot-instance"></td></tr><tr><th>Description:</th><td class="template-boot-description"></td></tr><tr><th>Reboot on Boot Order Change:</th><td class="template-boot-reboot"></td></tr><tr><th>Enforce Interface Name:</th><td class="template-boot-interface"></td></tr><tr><th>Boot Mode:</th><td class="template-boot-mode"></td></tr></table></fieldset></div></div><div class="panel panel-primary"><div class="panel-heading btn-primary"><h4 class="panel-title">Boot Order Details</h4></div><div class="panel-body"><ul class="tabrow boot-nav" id="Blade-Boot-Nav"><li class="selected"><a href="#Template-Blade-Configured" data-toggle="tab">Configured Boot Order</a></li><li class="instance"><a href="#Template-Blade-Actual" data-toggle="tab">Actual Boot Order</a></li></ul><div id="Template-Blade-Configured" class="boot-nav-toggle"><div class="row" style="margin-top:10px;"><div class="col-md-12"><table class="table table-bordered table-condensed small-table table-sort-pointer" style="margin-bottom:0px"><thead><tr><th style="width:30%;">Name</th><th style="width:5%;">Order</th><th style="width:20%;">vNIC/vHBA/iSCSI vNIC</th><th style="width:20%;">Type</th><th style="width:5%;">Lun ID</th><th style="width:30%;">WWN</th></tr></thead><tbody></tbody></table><ul style="list-style-type:none;padding:0;"><li><table class="table table-condensed"style="width:100%;"><thead style="font-size:12px;"><tr><th style="padding:5px;"><span class="glyphicon glyphicon-plus"></span>Name-2</th><th style="padding:5px;">MAC Address-2</th><th style="padding:5px;">Desired Order-2</th><th style="padding:5px;">Actual Order-2</th><th style="padding:5px;">Fabric ID-2</th><th style="padding:5px;">Desired Placement-2</th><th style="padding:5px;">Actual Placement-2</th></tr></thead><tbody></tbody></table></li></ul></div></div></div><div id="Template-Blade-Actual" class="boot-nav-toggle instance"><div class="tree well"><ul style="padding:0px;"></ul></div></div></div></div></div><div class="tab-pane" id="Template-Details-Policies" style="margin-top:20px;"><div class="row validate-section"><div class="col-md-4 Table-Column"><fieldset><legend>Policies</legend><table class="table table-condensed table-striped SystemTable1"><tr><th>BIOS Policy:</th><td class="template-policy-bios"></td></tr><tr><th>Firmware Policy:</th><td class="template-policy-firmware"></td></tr><tr><th>IPMI Access Policy:</th><td class="template-policy-ipmi"></td></tr><tr><th>Power Control Policy:</th><td class="template-policy-power"></td></tr><tr><th>Scrub Policy:</th><td class="template-policy-scrub"></td></tr><tr><th>Sol Policy:</th><td class="template-policy-sol"></td></tr><tr><th>Stats Policy:</th><td class="template-policy-stats"></td></tr></table></fieldset></div></div></div><div class="tab-pane" id="Template-Details-Performance" style="margin-top:20px;"><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title">vNICs</h4></div><div id="Template-Details-Vnic-Performance"><div class="panel-body"><table class="table table-condensed small-table table-bordered"style="width:100%;"><thead style="font-size:12px;"><tr><th>Name</th><th>Total Bytes Rx</th><th>Total Bytes Tx</th><th>Total Packets Rx</th><th>Total Packets Tx</th><th>Avg Mbps Rx</th><th>Avg Mbps Tx</th></tr></thead><tbody></tbody></table></div></div></div><div class="panel panel-primary"><div class="panel-heading small-heading"><h4 class="panel-title">vHBAs</h4></div><div id="Template-Details-Vhba-Performance"><div class="panel-body"><table class="table table-condensed small-table table-bordered"style="width:100%;"><thead style="font-size:12px;"><tr><th>Name</th><th>Total Bytes Rx</th><th>Total Bytes Tx</th><th>Total Packets Rx</th><th>Total Packets Tx</th><th>Avg Mbps Rx</th><th>Avg Mbps Tx</th></tr></thead><tbody></tbody></table></div></div></div></div></div></div></div></div></div><script src="https://code.jquery.com/jquery.js"></script><script src="http://netdna.bootstrapcdn.com/bootstrap/3.0.2/js/bootstrap.min.js"></script><script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min.js"></script><script type="text/plain" charset="utf8" src="http://raw.github.com/DataTables/Plugins/master/integration/bootstrap/3/dataTables.bootstrap.js"></script></body></html>
<!-- Begin JavaScript -->
<script type="text/javascript">
$(document).ready(function() {
'@
#===================================================================================#
#	Variable Definition:															#
#	section_2 = minified javascript markup for building html content				#
#===================================================================================#
$section_2 = @'
function InitializeDomainList(){var e=Object.keys(Domains);$("#SelectedDomain .caret").before(e[0]+" ");e.forEach(function(e){$("#DomainSelect").append('<li><a href="#">'+e+"</a></li>")});$("#DomainSelect li").first().addClass("hidden")}function SetReportData(e){SetSystemData(e);SetInventoryData(e);SetPolicyData(e);SetPoolData(e);SetProfileData(e);SetLanData(e);SetSanData(e);SetFaultData(e)}function SetSystemData(e){$(".fault-critical-count").text($.grep(Domains[e].Faults,function(e){return e.Severity=="critical"}).length);$(".fault-major-count").text($.grep(Domains[e].Faults,function(e){return e.Severity=="major"}).length);$(".fault-minor-count").text($.grep(Domains[e].Faults,function(e){return e.Severity=="minor"}).length);$(".fault-warning-count").text($.grep(Domains[e].Faults,function(e){return e.Severity=="warning"}).length);$("#system-vip a").prop("href","http://"+Domains[e].System.VIP);$("#system-vip a").text(Domains[e].System.VIP);$("#system-fi-a-label").text("FI-A ("+Domains[e].System.FI_A_Role+"):");$("#system-fi-a-value a").prop("href","http://"+Domains[e].System.FI_A_IP);$("#system-fi-a-value a").text(Domains[e].System.FI_A_IP);$("#system-fi-b-label").text("FI-B ("+Domains[e].System.FI_B_Role+"):");$("#system-fi-b-value a").prop("href","http://"+Domains[e].System.FI_B_IP);$("#system-fi-b-value a").text(Domains[e].System.FI_B_IP);$("#system-ucsm").text(Domains[e].System.UCSM);$("#system-ha-ready").text(Domains[e].System.HA_Ready);$("#system-backup").text(Domains[e].System.Backup_Policy);$("#system-export").text(Domains[e].System.Config_Policy);$("#system-callhome").text(Domains[e].System.CallHome);$("#Chassis-Power tbody tr").remove();Domains[e].System.Chassis_Power.forEach(function(e){$("#Chassis-Power tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+e.InputPower+"</td>"+"<td>"+e.InputPowerAvg+"</td>"+"<td>"+e.InputPowerMax+"</td>"+"<td>"+e.OutputPower+"</td>"+"<td>"+e.OutputPowerAvg+"</td>"+"<td>"+e.OutputPowerMax+"</td>"+"<td>"+e.Suspect+"</td>"+"</tr>")});$("#Server-Power tbody tr").remove();Domains[e].System.Server_Power.forEach(function(e){$("#Server-Power tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+Number(e.ConsumedPower).toFixed(2)+"</td>"+"<td>"+Number(e.ConsumedPowerAvg).toFixed(2)+"</td>"+"<td>"+Number(e.ConsumedPowerMax).toFixed(2)+"</td>"+"<td>"+Number(e.InputCurrent).toFixed(2)+"</td>"+"<td>"+Number(e.InputCurrentAvg).toFixed(2)+"</td>"+"<td>"+Number(e.InputVoltage).toFixed(2)+"</td>"+"<td>"+Number(e.InputVoltageAvg).toFixed(2)+"</td>"+"<td>"+e.Suspect+"</td>"+"</tr>")});$("#Server-Temp tbody tr").remove();Domains[e].System.Server_Temp.forEach(function(e){if($.isNumeric(e.FmTempSenIo)){$("#Server-Temp tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+Number(e.FmTempSenIo).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenIoAvg).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenIoMax).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRear).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearAvg).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearMax).toFixed(2)+"</td>"+"<td>"+e.Suspect+"</td>"+"</tr>")}else{$("#Server-Temp tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+Number(e.FmTempSenRearL).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearLAvg).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearLMax).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearR).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearRAvg).toFixed(2)+"</td>"+"<td>"+Number(e.FmTempSenRearRMax).toFixed(2)+"</td>"+"<td>"+e.Suspect+"</td>"+"</tr>")}})}function SetInventoryData(e){try{$("#FabricInterconnect tbody tr").remove();Domains[e].Inventory.FIs.forEach(function(e){$("#FabricInterconnect tbody").append("<tr>"+"<td>"+e.Fabric_Id+"</td>"+"<td>"+e.Role+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"<td>"+e.System+"</td>"+"<td>"+e.Kernel+"</td>"+"<td>"+e.IP+"</td>"+"<td>"+e.Ports_Used+"</td>"+"<td>"+e.Ports_Licensed+"</td>"+"<td>"+e.Operability+"</td>"+"<td>"+e.Thermal+"</td>"+"</tr>")});$("#Chassis tbody tr").remove();Domains[e].Inventory.Chassis.forEach(function(e){$("#Chassis tbody").append("<tr>"+"<td>"+e.Id+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"<td>"+e.Status+"</td>"+"<td>"+e.Operability+"</td>"+"<td>"+e.Power+"</td>"+"<td>"+e.Power_Redundancy+"</td>"+"<td>"+e.Thermal+"</td>"+"<td>"+$.grep(e.Psus,function(e){return e.Serial!=""}).length+"</td>"+"<td>"+e.SlotsUsed+"</td>"+"<td>"+e.SlotsAvailable+"</td>"+"</tr>")});$("#IOMs tbody tr").remove();Domains[e].Inventory.IOMs.forEach(function(e){$("#IOMs tbody").append("<tr>"+"<td>"+e.Chassis+"</td>"+"<td>"+e.Fabric_Id+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"<td>"+e.Channel+"</td>"+"<td>"+e.Running_FW+"</td>"+"<td>"+e.Backup_FW+"</td>"+"</tr>")});$("#Blades tbody tr").remove();Domains[e].Inventory.Blades.forEach(function(e){if(typeof e.Adapters[0]!="undefined"){var t=e.Adapters[0].Model;var n=e.Adapters[0].Fw}else{var t="Not Present";var n="N/A/"}if(typeof e.Adapters[1]!="undefined"){var r=e.Adapters[1].Model;var i=e.Adapters[1].Fw}else{var r="Not Present";var i="N/A/"}if(e.Service_Profile=="Unassociated"){var s=e.Service_Profile}else{var s='<a class="profile-select" href="#">'+e.Service_Profile+"</a>"}$("#Blades tbody").append("<tr>"+'<td class="dn hidden">'+e.Dn+"</td>"+"<td>"+e.Chassis+"</td>"+"<td>"+e.Slot+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"<td>"+s+"</td>"+"<td>"+e.CPU_Model+"</td>"+'<td class="visible-medium">'+e.CPU_Cores+"</td>"+'<td class="visible-medium">'+e.CPU_Threads+"</td>"+"<td>"+e.Memory+"</td>"+'<td class="visible-large">'+e.Memory_Speed+"</td>"+'<td class="visible-medium">'+e.BIOS+"</td>"+"<td>"+e.CIMC+"</td>"+'<td class="visible-large">'+t+"</td>"+'<td class="visible-large">'+n+"</td>"+'<td class="visible-large">'+r+"</td>"+'<td class="visible-large">'+i+"</td>"+"<td>"+e.Status+"</td>"+"</tr>")});$("#Racks tbody tr").remove();Domains[e].Inventory.Rackmounts.forEach(function(e){$("#Racks tbody").append("<tr>"+'<td class="dn hidden">'+e.Dn+"</td>"+"<td>"+e.Rack_Id+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"<td>"+e.Service_Profile+"</td>"+"<td>"+e.CPU+"</td>"+"<td>"+e.CPU_Cores+"</td>"+"<td>"+e.CPU_Threads+"</td>"+"<td>"+e.Memory+"</td>"+"<td>"+e.Memory_Speed+"</td>"+"<td>"+e.BIOS+"</td>"+"<td>"+e.CIMC+"</td>"+"</tr>")});$("#RackAdapters tbody tr").remove();Domains[e].Inventory.Rackmount_Adapters.forEach(function(e){$("#RackAdapters tbody").append("<tr>"+"<td>"+e.Rack_Id+"</td>"+"<td>"+e.Slot+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"<td>"+e.Running_FW+"</td>"+"</tr>")})}catch(t){console.log("Found Error:"+t)}}function SetPolicyData(e){try{$("#policy-dns li").remove();Domains[e].Policies.SystemPolicies.DNS.forEach(function(e){$("#policy-dns").append("<li>"+e+"<li>")});$("#policy-ntp li").remove();Domains[e].Policies.SystemPolicies.NTP.forEach(function(e){$("#policy-ntp").append("<li>"+e+"<li>")});$("#policy-action").text(Domains[e].Policies.SystemPolicies.Action);$("#policy-grouping").text(Domains[e].Policies.SystemPolicies.Grouping);$("#policy-power").text(Domains[e].Policies.SystemPolicies.Power);$("#policy-maint").text(Domains[e].Policies.SystemPolicies.Maint);$("#policy-timezone").text(Domains[e].Policies.SystemPolicies.Timezone);$("#Maintenance-Policy tbody tr").remove();Domains[e].Policies.Maintenance.forEach(function(e){$("#Maintenance-Policy tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Dn+"</td>"+"<td>"+e.UptimeDisr+"</td>"+"<td>"+e.Descr+"</td>"+"<td>"+e.SchedName+"</td>"+"</tr>")});$("#Host-FW tbody tr").remove();Domains[e].Policies.FW_Packages.forEach(function(e){$("#Host-FW tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.BladeBundleVersion+"</td>"+"<td>"+e.RackBundleVersion+"</td>"+"</tr>")});$("#LDAP .Providers tbody tr").remove();Domains[e].Policies.LDAP_Providers.forEach(function(e){$("#LDAP .Providers tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Rootdn+"</td>"+"<td>"+e.Basedn+"</td>"+"<td>"+e.Attribute+"</td>"+"</tr>")});$("#LDAP .Mappings tbody tr").remove();Domains[e].Policies.LDAP_Mappings.forEach(function(e){$("#LDAP .Mappings tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Roles+"</td>"+"<td>"+e.Locales+"</td>"+"</tr>")})}catch(t){console.log("Found Error:"+t)}}function SetPoolData(e){$("#MgmtPool .Pools tbody tr").remove();$("#MgmtPool .Pools tbody").append("<tr>"+"<td>"+Domains[e].Policies.Mgmt_IP_Pool.From+"</td>"+"<td>"+Domains[e].Policies.Mgmt_IP_Pool.To+"</td>"+"<td>"+Domains[e].Policies.Mgmt_IP_Pool.Size+"</td>"+"<td>"+Domains[e].Policies.Mgmt_IP_Pool.Assigned+"</td>"+"</tr>");$("#MgmtPool .Assignments tbody tr").remove();Domains[e].Policies.Mgmt_IP_Allocation.forEach(function(e){$("#MgmtPool .Assignments tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+e.IP+"</td>"+"<td>"+e.Subnet+"</td>"+"<td>"+e.GW+"</td>"+"</tr>")});$("#UUID .Pools tbody tr").remove();Domains[e].Policies.UUID_Pools.forEach(function(e){$("#UUID .Pools tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+e.Name+"</td>"+"<td>"+e.AssignmentOrder+"</td>"+"<td>"+e.Prefix+"</td>"+"<td>"+e.Size+"</td>"+"<td>"+e.Assigned+"</td>"+"</tr>")});$("#UUID .Assignments tbody tr").remove();Domains[e].Policies.UUID_Assignments.forEach(function(e){$("#UUID .Assignments tbody").append("<tr>"+"<td>"+e.AssignedToDn+"</td>"+"<td>"+e.Id+"</td>"+"</tr>")});$("#Server_Pools .Pools tbody tr").remove();Domains[e].Policies.Server_Pools.forEach(function(e){$("#Server_Pools .Pools tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+e.Name+"</td>"+"<td>"+e.Size+"</td>"+"<td>"+e.Assigned+"</td>"+"</tr>")});$("#Server_Pools .Assignments tbody tr").remove();Domains[e].Policies.Server_Pool_Assignments.forEach(function(e){$("#Server_Pools .Assignments tbody").append("<tr>"+"<td>"+e.AssignedToDn+"</td>"+"<td>"+e.Name+"</td>"+"</tr>")});$("#Pools-Mac-Collapse .Pools tbody tr").remove();Domains[e].Lan.Mac_Pools.forEach(function(e){$("#Pools-Mac-Collapse .Pools tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.From+"</td>"+"<td>"+e.To+"</td>"+"<td>"+e.Size+"</td>"+"<td>"+e.Assigned+"</td>"+"</tr>")});$("#Pools-Mac-Collapse .Assignments tbody tr").remove();Domains[e].Lan.Mac_Allocations.forEach(function(e){$("#Pools-Mac-Collapse .Assignments tbody").append("<tr>"+"<td>"+e.Id+"</td>"+"<td>"+e.Assigned+"</td>"+"<td>"+e.AssignedToDn+"</td>"+"</tr>")});$("#Pools-Ip-Collapse .Pools tbody tr").remove();Domains[e].Lan.Ip_Pools.forEach(function(e){$("#Pools-Ip-Collapse .Pools tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.From+"</td>"+"<td>"+e.To+"</td>"+"<td>"+e.Size+"</td>"+"<td>"+e.Assigned+"</td>"+"</tr>")});$("#Pools-Ip-Collapse .Assignments tbody tr").remove();Domains[e].Lan.Ip_Allocations.forEach(function(e){$("#Pools-Ip-Collapse .Assignments tbody").append("<tr>"+"<td>"+e.Id+"</td>"+"<td>"+e.Assigned+"</td>"+"<td>"+e.AssignedToDn+"</td>"+"</tr>")});$("#Pools-Wwn-Collapse .Pools tbody tr").remove();Domains[e].San.Wwn_Pools.forEach(function(e){$("#Pools-Wwn-Collapse .Pools tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.From+"</td>"+"<td>"+e.To+"</td>"+"<td>"+e.Size+"</td>"+"<td>"+e.Assigned+"</td>"+"</tr>")});$("#Pools-Wwn-Collapse .Assignments tbody tr").remove();Domains[e].San.Wwn_Allocations.forEach(function(e){$("#Pools-Wwn-Collapse .Assignments tbody").append("<tr>"+"<td>"+e.Id+"</td>"+"<td>"+e.Assigned+"</td>"+"<td>"+e.AssignedToDn+"</td>"+"</tr>")})}function SetProfileData(e){try{$(".Active-Template").empty();$.each(Domains[e].Profiles,function(e,t){if(e==""){e="Unbound"}if(t.Profiles.length>0){var n=$("#Profile-Template").clone().prop("id",e).removeClass("hidden");$(n).find(".panel-title a").prop("href","#"+e+"-Collapse").attr("data-parent","#"+e);$(n).find("#Template-Collapse").prop("id",e+"-Collapse");$(n).find(".heading-icon:last").after(e);$(n).find(".profile-type").text("Type: "+t.Type);if(e=="Unbound"){$(n).find(".expand-template").remove()}$(n).addClass("Active-Template");switch(t.Type){case"N/A":$(n).find(".panel").removeClass("panel-default").addClass("panel-danger");break;case"Updating":$(n).find(".panel").removeClass("panel-default").addClass("panel-primary");break;case"Initial":$(n).find(".panel").removeClass("panel-default").addClass("panel-warning");break}t.Profiles.forEach(function(e){$(n).find("tbody").append("<tr>"+'<td class="dn hidden">'+e.Dn+"</td>"+"<td>"+e.Service_Profile+"</td>"+"<td>"+e.UsrLbl+"</td>"+'<td><a class="server-select" href="#">'+e.Assigned_Server+"</a></td>"+"<td>"+e.Assoc_State+"</td>"+"<td>"+e.Maint_Policy+"</td>"+"<td>"+e.FW_Policy+"</td>"+"<td>"+e.BIOS_Policy+"</td>"+"</tr>")});$(n).find(".panel-collapse").on("hidden.bs.collapse",function(){$(this).parent().find(".panel-heading .glyphicon-minus").addClass("hidden");$(this).parent().find(".panel-heading .glyphicon-th-list").removeClass("hidden")});$(n).find(".panel-collapse").on("shown.bs.collapse",function(){$(this).parent().find(".panel-heading .glyphicon-th-list").addClass("hidden");$(this).parent().find(".panel-heading .glyphicon-minus").removeClass("hidden")});$("#Profiles").append(n)}})}catch(t){console.log("Found Error:"+t)}}function SetLanData(e){$("#Lan-Qos-Collapse tbody td").remove();Domains[e].Lan.Qos.Domain.forEach(function(e){if(e.AdminState=="enabled"){var t="checked"}else{var t=""}if(e.Drop=="drop"){var n="checked"}else{var n=""}if(e.MulticastOptimize=="yes"){var r="checked"}else{var r=""}$("#Lan-Qos-Collapse tbody").append("<tr>"+"<td>"+e.Priority+"</td>"+"<td>"+'<input type="checkbox"'+t+" disabled>"+"</td>"+"<td>"+e.Cos+"</td>"+"<td>"+'<input type="checkbox"'+n+" disabled>"+"</td>"+"<td>"+e.Weight+"</td>"+"<td>"+e.BwPercent+"</td>"+"<td>"+e.Mtu+"</td>"+"<td>"+'<input type="checkbox"'+r+" disabled>"+"</td>"+"</tr>")});$("#Lan-Vlan-Collapse tbody td").remove();Domains[e].Lan.Vlans.forEach(function(e){$("#Lan-Vlan-Collapse tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Id+"</td>"+"<td>"+e.SwitchId+"</td>"+"<td>"+e.Type+"</td>"+"<td>"+e.Transport+"</td>"+"<td>"+e.DefaultNet+"</td>"+"<td>"+e.Sharing+"</td>"+"<td>"+e.PubNwName+"</td>"+"<td>"+e.McastPolicyName+"</td>"+"</tr>")});$("#Lan-Uplinks-Collapse tbody td").remove();Domains[e].Lan.UplinkPorts.forEach(function(t){$("#Lan-Uplinks-Collapse tbody").append("<tr>"+"<td>"+t.Fabric_Id+"</td>"+"<td>"+t.SlotId+"/"+t.PortId+"</td>"+"<td>"+t.Mac+"</td>"+"<td>"+t.IfType+"</td>"+"<td>"+t.Speed+"</td>"+"<td>"+t.XcvrType+"</td>"+"<td>"+(t.Performance.Rx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+(t.Performance.Tx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+t.Status+"</td>"+"<td>"+t.State+"</td>"+"</tr>")});$("#Lan-ServerPorts-Collapse tbody td").remove();Domains[e].Lan.ServerPorts.forEach(function(t){$("#Lan-ServerPorts-Collapse tbody").append("<tr>"+"<td>"+t.Fabric_Id+"</td>"+"<td>"+t.SlotId+"/"+t.PortId+"</td>"+"<td>"+t.Mac+"</td>"+"<td>"+t.IfType+"</td>"+"<td>"+t.Speed+"</td>"+"<td>"+t.XcvrType+"</td>"+"<td>"+(t.Performance.Rx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+(t.Performance.Tx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+t.Status+"</td>"+"<td>"+t.State+"</td>"+"</tr>")});$("#Lan-Control-Collapse tbody td").remove();Domains[e].Lan.Control_Policies.forEach(function(e){$("#Lan-Control-Collapse tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Dn+"/"+e.PortId+"</td>"+"<td>"+e.Descr+"</td>"+"<td>"+e.PolicyOwner+"</td>"+"<td>"+e.Cdp+"</td>"+"<td>"+e.MacRegisterMode+"</td>"+"<td>"+e.UplinkFailAction+"</td>"+"</tr>")});$("#Lan-QosPolicy-Collapse tbody td").remove();Domains[e].Lan.Qos.Policies.forEach(function(e){$("#Lan-QosPolicy-Collapse tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Owner+"</td>"+"<td>"+e.Prio+"</td>"+"<td>"+e.Burst+"</td>"+"<td>"+e.Rate+"</td>"+"<td>"+e.HostControl+"</td>"+"</tr>")})}function SetSanData(e){$("#San-Vsan-Collapse tbody td").remove();Domains[e].San.Vsans.forEach(function(e){$("#San-Vsan-Collapse tbody").append("<tr>"+"<td>"+e.Id+"</td>"+"<td>"+e.Name+"</td>"+"<td>"+e.SwitchId+"</td>"+"<td>"+e.FcoeVlan+"</td>"+"<td>"+e.IfRole+"</td>"+"<td>"+e.Transport+"</td>"+"<td>"+e.ZoningState+"</td>"+"</tr>")});$("#San-UplinkPorts-Collapse tbody td").remove();Domains[e].San.UplinkPorts.forEach(function(t){$("#San-UplinkPorts-Collapse tbody").append("<tr>"+"<td>"+t.Fabric_Id+"</td>"+"<td>"+t.SlotId+"/"+t.PortId+"</td>"+"<td>"+t.Mac+"</td>"+"<td>"+t.IfType+"</td>"+"<td>"+t.Speed+"</td>"+"<td>"+t.XcvrType+"</td>"+"<td>"+(t.Performance.Rx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+(t.Performance.Tx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+t.Status+"</td>"+"<td>"+t.State+"</td>"+"</tr>")});$("#San-StoragePorts-Collapse tbody td").remove();Domains[e].San.StoragePorts.forEach(function(t){$("#San-StoragePorts-Collapse tbody").append("<tr>"+"<td>"+t.Fabric_Id+"</td>"+"<td>"+t.SlotId+"/"+t.PortId+"</td>"+"<td>"+t.Mac+"</td>"+"<td>"+t.IfType+"</td>"+"<td>"+t.Speed+"</td>"+"<td>"+t.XcvrType+"</td>"+"<td>"+(t.Performance.Rx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+(t.Performance.Tx.TotalBytesDeltaAvg*8/Domains[e].Collection.Port/1048576).toFixed(4)+"</td>"+"<td>"+t.Status+"</td>"+"<td>"+t.State+"</td>"+"</tr>")})}function SetFaultData(e){try{$("#Faults tbody tr").remove();Domains[e].Faults.forEach(function(e){$("#Faults tbody").append("<tr>"+"<td>"+e.Severity+"</td>"+'<td class="fault-description">'+e.Descr+"</td>"+"<td>"+e.Dn+"</td>"+"<td>"+e.Date+"</td>"+"</tr>")})}catch(t){console.log("Found Error:"+t)}}function SetActions(e){$("#FabricInterconnect tbody>tr").click(function(){$.when(SetFiModalData($(this).find("td:eq(0)").text())).then(function(){if(e){}$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#FI-Details-Modal").fadeIn(300)})})});$("#Chassis tbody>tr").click(function(){$.when(SetChassisDetailsData($(this).find("td:eq(0)").text())).then(function(){$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#Chassis-Details").fadeIn(300);ValidateChassisDetails()})})});$("#IOMs tbody>tr").click(function(){$.when(SetIomDetailsData($(this).find("td:eq(0)").text(),$(this).find("td:eq(1)").text())).then(function(){$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#IOM-Details").fadeIn(300)})})});$("#Blades td:not(:has(a))").click(function(){HandleBladeSelect($(this).closest("tr").find(".dn").text())});$("#Racks tbody>tr").click(function(){HandleRackSelect($(this).closest("tr").find(".dn").text())});$(".profile-select").click(function(){HandleProfileSelect($(this).text())});$(".server-select").click(function(){var e=$(this).text();if(e.search("blade")>0){HandleBladeSelect(e)}else{HandleRackSelect(e)}});$(".expand-template").click(function(){$.when(SetTemplateDetailsData($.trim($(this).closest(".panel-heading").find("a").text()))).then(function(){$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#Template-Details .nav-pills a:first").tab("show");$("#Template-Details").fadeIn(300)});$('a[href="#Template-Details-Network"]').on("shown.bs.tab",function(e){$("#Template-Details-vNICs-Collapse ul:first li:first th").each(function(){var e=$(this).index();var t=0;$("#Template-Details-vNICs-Collapse ul li:first th:nth-child("+(e+1)+")").each(function(){t=Math.max($(this).outerWidth(),t)});$("#Template-Details-vNICs-Collapse th:nth-child("+(e+1)+")").outerWidth(t)});$(window).resize(function(){if($("#Template-Details-vNICs-Collapse").is(":visible")){$("#Template-Details-vNICs-Collapse ul:first li:first th").each(function(){var e=$(this).index();var t=0;$("#Template-Details-vNICs-Collapse ul li:first th:nth-child("+(e+1)+")").each(function(){t=Math.max($(this).outerWidth(),t)});$("#Template-Details-vNICs-Collapse th:nth-child("+(e+1)+")").outerWidth(t)})}});$(".vnic-toggle").unbind("click").click(function(){$(this).closest("ul").find(".nic-toggle").toggle(300);$(this).toggleClass("glyphicon-plus");$(this).toggleClass("glyphicon-minus")});$(".Toggle-Collapse .toggle-expand-all").unbind("click").click(function(){$(this).closest(".panel-body").find(".nic-toggle:hidden").each(function(){$(this).toggle(300);$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-plus");$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-minus")})});$(".Toggle-Collapse .toggle-collapse-all").unbind("click").click(function(){$(this).closest(".panel-body").find(".nic-toggle:visible").each(function(){$(this).toggle(300);$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-plus");$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-minus")})})});$('a[href="#Template-Details-Boot"]').on("shown.bs.tab",function(e){$("#Template-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Template-Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())});$('a[href="#Template-Blade-Configured]').click(function(){$("#Template-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Template-Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$(window).resize(function(){$("#Template-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Template-Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$("#Template-Details-Boot .toggle-trigger").unbind("click").click(function(){$(this).closest("ul").find(".boot-toggle").toggle(300);$(this).toggleClass("glyphicon-plus");$(this).toggleClass("glyphicon-minus")})})})});$(".Active-Template td:not(:has(a))").click(function(){HandleProfileSelect($(this).closest("tr").find(".dn").text())});$(".details-close").click(function(){$.when($(this).closest(".details-div").fadeOut(300)).then(function(){$(".main-content, #Report-Nav").fadeIn(300)})});$(".glyphicon-search").click(function(){$(this).closest(".panel").find("table").dataTable({sDom:"frt",iDisplayLength:-1,oLanguage:{sSearch:"Filter:"},bRetrieve:true})});$(".boot-nav li").click(function(e){e.preventDefault();var t=$(this);$($(t).closest(".boot-nav").find(".selected a").attr("href")).fadeOut(50,function(){$(t).closest(".boot-nav").find(".selected").removeClass("selected");$(t).addClass("selected");$($(t).find("a").attr("href")).fadeIn(50)})});$(".tree li:has(ul)").addClass("parent_li").find(" > span").attr("title","Collapse this branch");$(".tree").unbind("click").on("click",".border",function(e){var t=$(this).closest(".parent_li").find("ul");if(t.is(":visible")){t.hide("fast")}else{t.show("fast")}$(this).find(".glyphicon:first").toggleClass("glyphicon-plus-sign").toggleClass("glyphicon-minus-sign");e.stopPropagation()})}function CallValidators(){$(".validate-section tr").removeClass();ValidateSystemData();ValidateInventoryData();ValidatePolicyData();ValidateFaultData()}function ValidateFaultData(){$("#Faults tbody td:first-child").each(function(){switch($(this).text()){case"critical":$(this).closest("tr").addClass("critical");break;case"major":$(this).closest("tr").addClass("major");break;case"minor":$(this).closest("tr").addClass("warning");break;case"warning":$(this).closest("tr").addClass("info");break;case"info":$(this).closest("tr").addClass("active");break;default:$(this).closest("tr").addClass("success")}})}function ValidateSystemData(){if($("#system-ha-ready").text()!="yes"){$("#system-ha-ready").closest("tr").addClass("danger")}if($("#system-backup").text()=="disable"){$("#system-backup").closest("tr").addClass("warning")}if($("#system-export").text()=="disable"){$("#system-export").closest("tr").addClass("warning")}if($("#system-callhome").text()=="off"){$("#system-callhome").closest("tr").addClass("danger")}}function ValidateInventoryData(){$("#FabricInterconnect tbody>tr").each(function(){if(Number($(this).find("td:eq(7)").text())>Number($(this).find("td:eq(8)").text())){$(this).find("td:eq(7)").addClass("danger")}else if(Number($(this).find("td:eq(7)").text())>Number($(this).find("td:eq(8)").text())-2){$(this).find("td:eq(7)").addClass("warning")}});$("#Chassis tbody>tr").each(function(){if(Number($(this).find("td:eq(10)").text())==0){$(this).find("td:eq(10)").addClass("warning")}if($(this).find("td:eq(6)").text()=="non-redundant"){$(this).find("td:eq(6)").addClass("danger")}});$("#IOMs tbody>tr").each(function(){if($(this).find("td:eq(4)").text()=="null"){$(this).find("td:eq(4)").text("none");$(this).find("td:eq(4)").addClass("warning")}})}function ValidatePolicyData(){if($("#policy-dns li:eq(0)").text()=="null"){$("#policy-dns").closest("tr").addClass("warning");$("#policy-dns li:eq(0)").text("none")}if($("#policy-ntp li:eq(0)").text()=="null"){$("#policy-ntp").closest("tr").addClass("warning");$("#policy-ntp li:eq(0)").text("none")}if($("#policy-power").text()=="non-redundant"){$("#policy-power").closest("tr").addClass("danger")}if($("#policy-grouping").text()!="port-channel"){$("#policy-grouping").closest("tr").addClass("danger")}if($("#policy-maint").text()=="immediate"){$("#policy-maint").closest("tr").addClass("danger")}}function SetFiModalData(e){var t=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.FIs,function(t){return t.Fabric_Id==e})[0];var n=$("#FI-Details-Modal");$(n).find("legend").text("FI-"+t.Fabric_Id+" Details");$(n).find("#fi-status").text(t.Operability);$(n).find("#fi-thermal").text(t.Thermal);$(n).find("#fi-model").text(t.Model);$(n).find("#fi-ethernet-mode").text(t.Ethernet_Mode);$(n).find("#fi-fc-mode").text(t.FC_Mode);$(n).find("#fi-ip").text(t.IP);$(n).find("#fi-leadership").text(t.Role);var r=1;$(n).find("#FI-Storage-Collapse tbody .RemoveTarget").remove();t.Storage.forEach(function(e){var t=$("#fi-storage-template").clone().prop("id","fi-storage-"+r).removeClass("hidden");$(t).find("td:eq(0)").text(e.Name);$(t).find("td:eq(1)").text(e.Size);$(t).find("td:eq(2) span").text(e.Used+"%");$(t).addClass("RemoveTarget");$(t).find(".progress-bar").css("width",e.Used+"%");$(n).find("#FI-Storage-Collapse tbody").append(t);r++});$(n).find("#fi-vlan-limit").text(t.VLAN.Limit);$(n).find("#fi-access-vlan-count").text(t.VLAN.AccessVlanPortCount);$(n).find("#fi-border-vlan-count").text(t.VLAN.BorderVlanPortCount);$(n).find("#fi-vlan-alloc").text(t.VLAN.AllocStatus);$(n).find("#fi-zone-limit").text(t.Zone.Limit);$(n).find("#fi-zone-count").text(t.Zone.ZoneCount);$(n).find("#fi-fc-alloc").text(t.Zone.AllocStatus);$("#FI-Ports tbody tr").remove();t.Ports.forEach(function(e){$("#FI-Ports tbody").append("<tr>"+"<td>"+e.Dn+"</td>"+"<td>"+e.IfRole+"</td>"+"<td>"+e.LicState+"</td>"+"<td>"+e.LicGP+"</td>"+"<td>"+e.Mode+"</td>"+"<td>"+e.OperState+"</td>"+"<td>"+e.OperSpeed+"</td>"+"<td>"+e.XcvrType+"</td>"+"<td>"+e.PeerDn+"</td>"+"<td>"+e.PeerPortId+"</td>"+"<td>"+e.PeerSlotId+"</td>"+"</tr>")})}function SetChassisDetailsData(e){var t=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Chassis,function(t){return t.Id==e})[0];var n=$("#Chassis-Details");$(n).find("legend").text("Chassis-"+t.Id+" Details");$(n).find("#chassis-status").text(t.Status);$(n).find("#chassis-model").text(t.Model);var r=$.grep(Domains[$("#DomainSelect .hidden").text()].System.Chassis_Power,function(e){return e.Dn==t.Dn.replace("sys/","")})[0].OutputPowerAvg;$(n).find("#chassis-power").text(Math.round(r)+" W");$(n).find("#chassis-power-redundancy").text(t.Power_Redundancy);$(n).find("#chassis-serial").text(t.Serial);$(n).find("#chassis-total-slots").text(t.SlotsUsed);$(n).find("#chassis-free-slots").text(t.SlotsAvailable);$("#Chassis-Iom-Collapse tbody tr").remove();var i=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.IOMs,function(e){return e.Chassis==t.Id});$.each(i,function(e,t){$("#Chassis-Iom-Collapse tbody").append("<tr>"+"<td>"+t.Fabric_Id+"</td>"+"<td>"+t.Model+"</td>"+"<td>"+t.Serial+"</td>"+"<td>"+t.Running_FW+"</td>"+"</tr>")});$("#Chassis-Slots-Collapse tbody tr").remove();t.Blades.forEach(function(e){var n=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Blades,function(n){return n.Chassis==t.Id&&n.Slot==e.SlotId})[0];$("#Chassis-Slots-Collapse tbody").append("<tr>"+"<td>"+e.SlotId+"</td>"+"<td>"+n.Model+"</td>"+"<td>"+e.Width+"</td>"+"<td>"+n.Serial+"</td>"+"<td>"+e.Service_Profile+"</td>"+"</tr>")});$("#Chassis-Psu-Collapse tbody tr").remove();t.Psus.forEach(function(e){if(e.Model==""){e.Model="Empty"}$("#Chassis-Psu-Collapse tbody").append("<tr>"+"<td>"+e.Id+"</td>"+"<td>"+e.Type+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Serial+"</td>"+"</tr>")})}function SetIomDetailsData(e,t){var n=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.IOMs,function(n){return n.Chassis==e&&n.Fabric_Id==t})[0];var r=$("#IOM-Details");if(n.Model.toLowerCase().indexOf("nexus")>=0){$(r).find("legend").text("FEX-"+e+" "+t+" Details")}else{$(r).find("legend").text("Chassis-"+e+" IOM "+t+" Details")}$("#IOM-Fabric-Ports tbody tr").remove();n.FabricPorts.forEach(function(e){$("#IOM-Fabric-Ports tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.OperState+"</td>"+"<td>"+e.PortChannel+"</td>"+"<td>"+e.PeerSlotId+"</td>"+"<td>"+e.PeerPortId+"</td>"+"<td>"+e.FabricId+"</td>"+"<td>"+e.Ack+"</td>"+"<td>"+e.Peer+"</td>"+"</tr>")});$("#IOM-Backplane-Ports tbody tr").remove();n.BackplanePorts.forEach(function(e){$("#IOM-Backplane-Ports tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.OperState+"</td>"+"<td>"+e.PortChannel+"</td>"+"<td>"+e.FabricId+"</td>"+"<td>"+e.Peer+"</td>"+"</tr>")})}function SetBladeDetailsData(e){var t=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Blades,function(t){return t.Dn==e})[0];var n=$("#Blade-Details");$(n).find("legend").text("Chassis-"+t.Chassis+"/Server-"+t.Slot+" Details");$(n).find("#blade-status").text(t.Status);$(n).find("#blade-model").text(t.Model);$(n).find("#blade-name").text(t.Name);$(n).find("#blade-usrlbl").text(t.UsrLbl);$(n).find("#blade-service-profile").text(t.Service_Profile);$(n).find("#blade-description").text(t.Model_Description);$(n).find("#blade-uuid").text(t.Uuid);$(n).find("#blade-serial").text(t.Serial);$(n).find("#blade-cpu").text(t.CPU_Model);$(n).find("#blade-cores").text(t.CPU_Cores);$(n).find("#blade-threads").text(t.CPU_Threads);$(n).find("#blade-memory").text(t.Memory+" (GB)");$("#Blade-Details-Adapter-Collapse tbody tr").remove();t.Adapters.forEach(function(e){$("#Blade-Details-Adapter-Collapse tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Fw+"</td>"+"<td>"+e.Serial+"</td>"+"</tr>")});$("#Blade-Details-Memory tbody tr").remove();t.Memory_Array.forEach(function(e){$("#Blade-Details-Memory tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Location+"</td>"+"<td>"+e.Capacity+"</td>"+"<td>"+e.Clock+"</td>"+"</tr>")});$("#Blade-Configured tbody tr").remove();$("#Blade-Configured ul").remove();t.Configured_Boot_Order.forEach(function(e){if(!$.isArray(e.Entries)){return}e.Entries.forEach(function(e){var t="";if(typeof e.Level2!="undefined"){t='<span class="glyphicon glyphicon-minus toggle-trigger" style="margin-right:10px;cursor:pointer;"></span>'}var n='<ul class="well"><li><table class="table table-condensed boot-entry"><body><tr>'+"<td>"+t+e.Level1.Type+"</td>"+"<td>"+e.Level1.Order+"</td>"+"</tr></tbody></table></li>";if(typeof e.Level2!="undefined"){e.Level2.forEach(function(t){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+'<td style="padding-left:30px">'+e.Level1.Type+" "+t.Type+"</td>"+"<td></td>"+"<td>"+t.VnicName+"</td>"+"<td>"+t.Type+"</td>"+"</tr></tbody></table></li>";if(typeof t.Level3!="undefined"){t.Level3.forEach(function(e){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+"<td></td><td></td><td></td>"+"<td>"+e.Type+"</td>"+"<td>"+e.Lun+"</td>"+"<td>"+e.Wwn+"</td>"+"</tr></tbody></table></li>"})}})}n+="</ul>";$("#Blade-Configured .table:first").parent().append(n)})});$("#Blade-Actual ul li").remove();t.Actual_Boot_Order.forEach(function(e){var t="";t='<li class="parent_li"><span class="border"><span class="glyphicon glyphicon-minus-sign"></span>'+e.Descr+"</span>";e.Entries.forEach(function(e){t+="<ul><li>"+e+"</li></ul>"});t+="</li>";$("#Blade-Actual ul:first").append(t)});$(".Controller-Details").empty();$.each(t.Storage,function(e,t){var n="controller-group-"+e;var r=$("#Blade-Storage-Template").clone().prop("id",n).removeClass("hidden");$(r).find(".panel-title a").prop("href","#"+n+"-Collapse").attr("data-parent","#"+n);$(r).find(".controller-collapse").prop("id",n+"-Collapse");$(r).find(".controller-title").after("Controller SAS "+t.Id);$(r).addClass("Controller-Details");$(r).find(".blade-controller-id").text(t.Id);$(r).find(".blade-controller-vendor").text(t.Vendor);$(r).find(".blade-controller-revision").text(t.Revision);$(r).find(".blade-controller-raid").text(t.RaidSupport);$(r).find(".blade-controller-pciAddr").text(t.PciAddr);$(r).find(".blade-controller-numDisks").text(t.Disk_Count);$(r).find(".blade-controller-rebRate").text(t.RebuildRate);$(r).find(".blade-controller-pid").text(t.Model);$(r).find(".blade-controller-serial").text(t.Serial);$(r).find(".blade-controller-status").text(t.ControllerStatus);$(".Disk-Details").empty();$.each(t.Disks,function(e,t){var n="controller-group-disk-"+e;var i=$("#Blade-Disk-Template").clone().prop("id",n).removeClass("hidden");$(i).find(".panel-title a").prop("href","#"+n+"-Collapse").attr("data-parent","#"+n);$(i).find(".panel-collapse").prop("id",n+"-Collapse");$(i).find(".heading-icon:last").after("Disk "+t.Id);$(i).addClass("Disk-Details");$(i).find(".blade-disk-id").text(t.Id);$(i).find(".blade-disk-vendor").text(t.Vendor);$(i).find(".blade-disk-serial").text(t.Serial);$(i).find(".blade-disk-pid").text(t.Pid);$(i).find(".blade-disk-vid").text(t.Vid);$(i).find(".blade-disk-driveState").text(t.Drive_State);$(i).find(".blade-disk-size").text(t.Size);$(i).find(".blade-disk-numBlocks").text(t.Blocks);$(i).find(".blade-disk-technology").text(t.Technology);$(i).find(".blade-disk-powerState").text(t.Power_State);$(i).find(".blade-disk-linkSpeed").text(t.Link_Speed);$(i).find(".blade-disk-blockSize").text(t.Block_Size);$(i).find(".blade-disk-tts").text(t.Track_To_Seek);$(i).find(".blade-disk-operability").text(t.Operability);$(i).find(".blade-disk-presence").text(t.Presence);$(i).find(".blade-disk-runningVersion").text(t.Running_Version);$(r).find(".controller-collapse .panel-body:first").append(i)});$(r).find(".panel-collapse").on("hidden.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").removeClass("hidden")});$(r).find(".panel-collapse").on("shown.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").removeClass("hidden")});$("#Blade-Details-Storage").append(r)});$(".Vif-Details").remove();$.each(t.VIFs,function(e,t){var n="blade-vif-"+e;var r=$("#Blade-Vifs-Template").clone().prop("id",n).removeClass("hidden");$(r).find(".panel-title a").prop("href","#"+n+"-Collapse");$(r).find(".panel-collapse").prop("id",n+"-Collapse");$(r).find(".heading-icon:last").after(t.Name);$(r).addClass("Vif-Details");$(r).find(".physical tbody").append("<tr>"+"<td>"+t.Adapter_Port+"</td>"+"<td>"+t.Fex_Host_Port+"</td>"+"<td>"+t.Fex_Network_Port+"</td>"+"<td>"+t.FI_Server_Port+"</td>"+"</tr>");t.Circuits.forEach(function(e){$(r).find(".vifs tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.vNic+"</td>"+"<td>"+e.FI_Uplink+"</td>"+"<td>"+e.Link_State+"</td>"+"</tr>")});$(r).find(".panel-collapse").on("hidden.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").removeClass("hidden")});$(r).find(".panel-collapse").on("shown.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").removeClass("hidden")});$("#Blade-Vifs-Template").parent().append(r)})}function ValidateChassisDetails(){$("#Chassis-Psu-Collapse tbody>tr").each(function(){if($(this).find("td:eq(2)").text()=="Empty"){$(this).find("td:eq(2)").parent().addClass("warning")}})}function SetRackDetailsData(e){var t=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Rackmounts,function(t){return t.Dn==e})[0];var n=$("#Blade-Details");$(n).find("legend").text("Rack Server "+t.Rack_Id+" Details");$(n).find("#blade-status").text(t.Status);$(n).find("#blade-model").text(t.Model);$(n).find("#blade-name").text(t.Name);$(n).find("#blade-usrlbl").text(t.UsrLbl);$(n).find("#blade-service-profile").text(t.Service_Profile);$(n).find("#blade-description").text(t.Model_Description);$(n).find("#blade-uuid").text(t.Uuid);$(n).find("#blade-serial").text(t.Serial);$(n).find("#blade-cpu").text(t.CPU);$(n).find("#blade-cores").text(t.CPU_Cores);$(n).find("#blade-threads").text(t.CPU_Threads);$(n).find("#blade-memory").text(t.Memory+" (GB)");var r=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Rackmount_Adapters,function(e){return e.Rack_Id==t.Rack_Id});$("#Blade-Details-Adapter-Collapse tbody tr").remove();r.forEach(function(e){$("#Blade-Details-Adapter-Collapse tbody").append("<tr>"+"<td>Slot-"+e.Slot+"</td>"+"<td>"+e.Model+"</td>"+"<td>"+e.Running_FW+"</td>"+"<td>"+e.Serial+"</td>"+"</tr>")});$("#Blade-Details-Memory tbody tr").remove();t.Memory_Array.forEach(function(e){$("#Blade-Details-Memory tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Location+"</td>"+"<td>"+e.Capacity+"</td>"+"<td>"+e.Clock+"</td>"+"</tr>")});$("#Blade-Configured tbody tr").remove();$("#Blade-Configured ul").remove();t.Configured_Boot_Order.forEach(function(e){if(!$.isArray(e.Entries)){return}e.Entries.forEach(function(e){var t="";if(typeof e.Level2!="undefined"){t='<span class="glyphicon glyphicon-minus toggle-trigger" style="margin-right:10px;cursor:pointer;"></span>'}var n='<ul class="well"><li><table class="table table-condensed boot-entry"><body><tr>'+"<td>"+t+e.Level1.Type+"</td>"+"<td>"+e.Level1.Order+"</td>"+"</tr></tbody></table></li>";if(typeof e.Level2!="undefined"){e.Level2.forEach(function(t){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+'<td style="padding-left:30px">'+e.Level1.Type+" "+t.Type+"</td>"+"<td></td>"+"<td>"+t.VnicName+"</td>"+"<td>"+t.Type+"</td>"+"</tr></tbody></table></li>";if(typeof t.Level3!="undefined"){t.Level3.forEach(function(e){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+"<td></td><td></td><td></td>"+"<td>"+e.Type+"</td>"+"<td>"+e.Lun+"</td>"+"<td>"+e.Wwn+"</td>"+"</tr></tbody></table></li>"})}})}n+="</ul>";$("#Blade-Configured .table:first").parent().append(n)})});$("#Blade-Actual ul li").remove();t.Actual_Boot_Order.forEach(function(e){var t="";t='<li class="parent_li"><span class="border"><span class="glyphicon glyphicon-minus-sign"></span>'+e.Descr+"</span>";e.Entries.forEach(function(e){t+="<ul><li>"+e+"</li></ul>"});t+="</li>";$("#Blade-Actual ul:first").append(t)});$(".Controller-Details").empty();$.each(t.Storage,function(e,t){var n="controller-group-"+e;var r=$("#Blade-Storage-Template").clone().prop("id",n).removeClass("hidden");$(r).find(".panel-title a").prop("href","#"+n+"-Collapse").attr("data-parent","#"+n);$(r).find(".controller-collapse").prop("id",n+"-Collapse");$(r).find(".controller-title").after("Controller SAS "+t.Id);$(r).addClass("Controller-Details");$(r).find(".blade-controller-id").text(t.Id);$(r).find(".blade-controller-vendor").text(t.Vendor);$(r).find(".blade-controller-revision").text(t.Revision);$(r).find(".blade-controller-raid").text(t.RaidSupport);$(r).find(".blade-controller-pciAddr").text(t.PciAddr);$(r).find(".blade-controller-numDisks").text(t.Disk_Count);$(r).find(".blade-controller-rebRate").text(t.RebuildRate);$(r).find(".blade-controller-pid").text(t.Model);$(r).find(".blade-controller-serial").text(t.Serial);$(r).find(".blade-controller-status").text(t.ControllerStatus);$(".Disk-Details").empty();$.each(t.Disks,function(e,t){var n="controller-group-disk-"+e;var i=$("#Blade-Disk-Template").clone().prop("id",n).removeClass("hidden");$(i).find(".panel-title a").prop("href","#"+n+"-Collapse").attr("data-parent","#"+n);$(i).find(".panel-collapse").prop("id",n+"-Collapse");$(i).find(".heading-icon:last").after("Disk "+t.Id);$(i).addClass("Disk-Details");$(i).find(".blade-disk-id").text(t.Id);$(i).find(".blade-disk-vendor").text(t.Vendor);$(i).find(".blade-disk-serial").text(t.Serial);$(i).find(".blade-disk-pid").text(t.Pid);$(i).find(".blade-disk-vid").text(t.Vid);$(i).find(".blade-disk-driveState").text(t.Drive_State);$(i).find(".blade-disk-size").text(t.Size);$(i).find(".blade-disk-numBlocks").text(t.Blocks);$(i).find(".blade-disk-technology").text(t.Technology);$(i).find(".blade-disk-powerState").text(t.Power_State);$(i).find(".blade-disk-linkSpeed").text(t.Link_Speed);$(i).find(".blade-disk-blockSize").text(t.Block_Size);$(i).find(".blade-disk-tts").text(t.Track_To_Seek);$(i).find(".blade-disk-operability").text(t.Operability);$(i).find(".blade-disk-presence").text(t.Presence);$(i).find(".blade-disk-runningVersion").text(t.Running_Version);$(r).find(".controller-collapse .panel-body:first").append(i)});$(r).find(".panel-collapse").on("hidden.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").removeClass("hidden")});$(r).find(".panel-collapse").on("shown.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").removeClass("hidden")});$("#Blade-Details-Storage").append(r)});$(".Vif-Details").remove();$.each(t.VIFs,function(e,t){var n="blade-vif-"+e;var r=$("#Blade-Vifs-Template").clone().prop("id",n).removeClass("hidden");$(r).find(".panel-title a").prop("href","#"+n+"-Collapse");$(r).find(".panel-collapse").prop("id",n+"-Collapse");$(r).find(".heading-icon:last").after(t.Name);$(r).addClass("Vif-Details");$(r).find(".physical tbody").append("<tr>"+"<td>"+t.Adapter_Port+"</td>"+"<td>"+t.Fex_Host_Port+"</td>"+"<td>"+t.Fex_Network_Port+"</td>"+"<td>"+t.FI_Server_Port+"</td>"+"</tr>");t.Circuits.forEach(function(e){$(r).find(".vifs tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.vNic+"</td>"+"<td>"+e.FI_Uplink+"</td>"+"<td>"+e.Link_State+"</td>"+"</tr>")});$(r).find(".panel-collapse").on("hidden.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").removeClass("hidden")});$(r).find(".panel-collapse").on("shown.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").removeClass("hidden")});$("#Blade-Vifs-Template").parent().append(r)})}function SetTemplateDetailsData(e){var t=Domains[$("#DomainSelect .hidden").text()].Profiles[e];var n=$("#Template-Details");$(n).find(".template").show();$(n).find(".instance").hide();$(n).find("legend:first").text("Service Profile Template: "+e);$(n).find(".template-general-name").text(t.General.Name);$(n).find(".template-general-description").text(t.General.Description);$(n).find(".template-general-uuidPool").text(t.General.UUIDPool);$(n).find(".template-general-power").text(t.General.PowerState);$(n).find(".template-general-type").text(t.General.Type);$(n).find(".template-general-access").text(t.General.MgmtAccessPolicy);var r=t.General.Server_Pool;if(r!=null){$("#Template-General-ServerPool-Collapse table").show();$("#Template-General-ServerPool-Collapse h5").hide();$(n).find(".template-srvpool-name").text(r.Name);$(n).find(".template-srvpool-qualification").text(r.Qualifier);$(n).find(".template-srvpool-restrictMigration").text(r.RestrictMigration)}else{$("#Template-General-ServerPool-Collapse table").hide();$("#Template-General-ServerPool-Collapse h5").show()}$(n).find(".template-maint-name").text(t.General.Maintenance_Policy.Name);$(n).find(".template-maint-instance").text(t.General.Maintenance_Policy.Dn);$(n).find(".template-maint-description").text(t.General.Maintenance_Policy.Descr);$(n).find(".template-maint-rebootPolicy").text(t.General.Maintenance_Policy.UptimeDisr);$(n).find(".template-storage-nwwn").text(t.Storage.Nwwn);$(n).find(".template-storage-nwwnPool").text(t.Storage.Nwwn_Pool);$(n).find(".template-storage-connPolicy").text(t.Storage.Connectivity_Policy);$(n).find(".template-storage-connInstance").text(t.Storage.Connectivity_Instance);$(n).find(".template-storage-ldMode").text(t.Storage.Local_Disk_Config.Mode);$(n).find(".template-storage-ldProtect").text(t.Storage.Local_Disk_Config.ProtectConfig);$(n).find(".template-storage-ldFfState").text(t.Storage.Local_Disk_Config.XtraProperty.FlexFlashState);$(n).find(".template-storage-ldFfReporting").text(t.Storage.Local_Disk_Config.XtraProperty.FlexFlashRAIDReportingState);$("#Template-Details-vHBAs tbody tr").remove();t.Storage.Hbas.forEach(function(e){$("#Template-Details-vHBAs tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Pwwn+"</td>"+"<td>"+e.Desired_Order+"</td>"+"<td>"+e.FabricId+"</td>"+"<td>"+e.Actual_Order+"</td>"+"<td>"+e.Desired_Placement+"</td>"+"<td>"+e.Actual_Placement+"</td>"+"<td>"+e.Vsan+"</td>"+"</tr>")});$("#Template-Details-vNICs ul").remove();t.Network.Nics.forEach(function(e){var t="";e.Vlans.forEach(function(e){t+="<tr>"+"<td>"+e.OperVnetName+"</td>"+"<td>"+e.Vnet+"</td>"+"<td>"+e.DefaultNet+"</td>"+"</tr>"});if(e.Adaptor_Profile==""){e.Adaptor_Profile="none"}if(e.Control_Policy==""){e.Control_Policy="none"}$("#Template-Details-vNICs-Collapse .table:first").parent().append('<ul style="list-style-type:none;padding:0;border-bottom: 2px solid #ddd;">'+'<li><table class="table table-condensed" style="width:100%;"><thead style="font-size:12px;">'+"<tr>"+'<th style="border-bottom:none;"><span class="glyphicon glyphicon-plus vnic-toggle" style="margin-right:2px;cursor:pointer;"></span>'+e.Name+"</th>"+'<th style="border-bottom:none;font-weight:normal;">'+e.Mac_Address+"</th>"+'<th style="min-width:50px;border-bottom:none;font-weight:normal;">'+e.Desired_Order+"</th>"+'<th style="border-bottom:none;font-weight:normal;">'+e.Actual_Order+"</th>"+'<th style="border-bottom:none;font-weight:normal;">'+e.Fabric_Id+"</th>"+'<th style="border-bottom:none;font-weight:normal;">'+e.Desired_Placement+"</th>"+'<th style="border-bottom:none;font-weight:normal;">'+e.Actual_Placement+"</th>"+'<th class="visible-large" style="border-bottom:none;font-weight:normal;">'+e.Adaptor_Profile+"</th>"+'<th class="visible-large" style="border-bottom:none;font-weight:normal;">'+e.Control_Policy+"</th>"+"</tr>"+"</thead></table></li>"+'<li class="nic-toggle" style="display:none;"><div class="row"><div class="col-md-4" style="margin-bottom:4px;margin-left:8px;"><table class="table table-condensed table-striped" style="font-size:11px; font-weight:normal;"><thead><tr>'+'<th style="border-bottom:none;font-weight:bold;">VLAN</th><th style="border-bottom:none;font-weight:bold;">VLAN ID</th><th style="border-bottom:none;font-weight:bold;">Native VLAN</th></tr></thead>'+"<tbody>"+t+"</tbody></div></div></li></ul>")});$("#Template-Details-iSCSI tbody tr").remove();t.iSCSI.forEach(function(e){$("#Template-Details-iSCSI tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Overlay+"</td>"+"<td>"+e.Iqn+"</td>"+"<td>"+e.Adapter_Policy+"</td>"+"<td>"+e.Mac+"</td>"+"<td>"+e.Vlan+"</td>"+"</tr>")});$("#Template-Blade-Configured tbody tr").remove();$("#Template-Blade-Configured ul").remove();var i=$.grep(Domains[$("#DomainSelect .hidden").text()].Policies.Boot_Policies,function(e){return e.Dn==t.General.Boot_Policy})[0];if(i!=null){$(n).find(".template-boot-name").text(i.Name);$(n).find(".template-boot-instance").text(i.Dn);$(n).find(".template-boot-description").text(i.Description);$(n).find(".template-boot-reboot").text(i.RebootOnUpdate);$(n).find(".template-boot-interface").text(i.EnforceVnicName);$(n).find(".template-boot-mode").text(i.BootMode);if(!$.isArray(i.Entries)){return}i.Entries.forEach(function(e){var t="";if(typeof e.Level2!="undefined"){t='<span class="glyphicon glyphicon-minus toggle-trigger" style="margin-right:10px;cursor:pointer;"></span>'}var n='<ul class="well"><li><table class="table table-condensed boot-entry"><body><tr>'+"<td>"+t+e.Level1.Type+"</td>"+"<td>"+e.Level1.Order+"</td>"+"</tr></tbody></table></li>";if(typeof e.Level2!="undefined"){e.Level2.forEach(function(t){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+'<td style="padding-left:30px">'+e.Level1.Type+" "+t.Type+"</td>"+"<td></td>"+"<td>"+t.VnicName+"</td>"+"<td>"+t.Type+"</td>"+"</tr></tbody></table></li>";if(typeof t.Level3!="undefined"){t.Level3.forEach(function(e){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+"<td></td><td></td><td></td>"+"<td>"+e.Type+"</td>"+"<td>"+e.Lun+"</td>"+"<td>"+e.Wwn+"</td>"+"</tr></tbody></table></li>"})}})}n+="</ul>";$("#Template-Blade-Configured .table:first").parent().append(n)})}else{$("#Template-Details-Boot fieldset table td").text("")}$(n).find(".template-policy-bios").text(t.Policies.Bios);$(n).find(".template-policy-firmware").text(t.Policies.Fw);$(n).find(".template-policy-ipmi").text(t.Policies.Ipmi);$(n).find(".template-policy-power").text(t.Policies.Power);$(n).find(".template-policy-scrub").text(t.Policies.Scrub);$(n).find(".template-policy-sol").text(t.Policies.Sol);$(n).find(".template-policy-stats").text(t.Policies.Stats)}function SetProfileDetailsData(e){var t="";$.each(Domains[$("#DomainSelect .hidden").text()].Profiles,function(n,r){t=$.grep(r.Profiles,function(t){return t.Dn==e})[0]||t});var n=$("#Template-Details");$(n).find(".template").hide();$(n).find(".instance").show();$(n).find("legend:first").text("Service Profile: "+t.Service_Profile);$(n).find(".template-general-name").text(t.General.Name);$(n).find(".template-general-status").text(t.General.Overall_Status);$(n).find(".template-general-assocState").text(t.Assoc_State);$(n).find(".template-general-userLabel").text(t.General.UserLabel);$(n).find(".template-general-description").text(t.General.Description);$(n).find(".template-general-owner").text(t.General.Owner);$(n).find(".template-general-uuid").text(t.General.Uuid);$(n).find(".template-general-uuidPool").text(t.General.UuidPool);$(n).find(".template-general-server").text(t.General.Associated_Server);$(n).find(".template-general-template").text(t.General.Template_Name);$(n).find(".template-general-power").text(t.General.Power_State);var r=t.General.Assignment;if(r.Server_Pool!=null){$("#Template-General-ServerPool-Collapse .template-assignment-pool").show();$("#Template-General-ServerPool-Collapse .template-assignment-pool table").show();$("#Template-General-ServerPool-Collapse .template-assignment-server").hide();$("#Template-General-ServerPool-Collapse .template-assignment-pool h5").hide();$(n).find(".template-srvpool-name").text(r.Server_Pool);$(n).find(".template-srvpool-qualification").text(r.Qualifier);$(n).find(".template-srvpool-restrictMigration").text(r.Restrict_Migration)}else if(r.Server!=null){$("#Template-General-ServerPool-Collapse .template-assignment-pool").hide();$("#Template-General-ServerPool-Collapse .template-assignment-server").show();$("#Template-General-ServerPool-Collapse .template-assignment-server table").show();$("#Template-General-ServerPool-Collapse .template-assignment-server h5").hide();$(n).find(".template-assignment-server .template-server-name").text(r.Server);$(n).find(".template-assignment-server .template-srvpool-restrictMigration").text(r.Restrict_Migration)}else{$("#Template-General-ServerPool-Collapse .template-assignment-server").show();$("#Template-General-ServerPool-Collapse .template-assignment-server table").hide();$("#Template-General-ServerPool-Collapse .template-assignment-server h5").show()}var i=$.grep(Domains[$("#DomainSelect .hidden").text()].Policies.Maintenance,function(e){return e.Dn==t.Maint_PolicyInstance})[0];$(n).find(".template-maint-name").text(t.Maint_Policy);$(n).find(".template-maint-instance").text(t.Maint_PolicyInstance);$(n).find(".template-maint-description").text(i.Descr);$(n).find(".template-maint-rebootPolicy").text(i.UptimeDisr);$(n).find(".template-storage-nwwn").text(t.Storage.Nwwn);$(n).find(".template-storage-nwwnPool").text(t.Storage.Nwwn_Pool);$(n).find(".template-storage-connPolicy").text(t.Storage.Connectivity_Policy);$(n).find(".template-storage-connInstance").text(t.Storage.Connectivity_Instance);$(n).find(".template-storage-ldMode").text(t.Storage.Local_Disk_Config.Mode);$(n).find(".template-storage-ldProtect").text(t.Storage.Local_Disk_Config.ProtectConfig);$(n).find(".template-storage-ldFfState").text(t.Storage.Local_Disk_Config.XtraProperty.FlexFlashState);$(n).find(".template-storage-ldFfReporting").text(t.Storage.Local_Disk_Config.XtraProperty.FlexFlashRAIDReportingState);$("#Template-Details-vHBAs tbody tr").remove();t.Storage.Hbas.forEach(function(e){$("#Template-Details-vHBAs tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Pwwn+"</td>"+"<td>"+e.Desired_Order+"</td>"+"<td>"+e.FabricId+"</td>"+"<td>"+e.Actual_Order+"</td>"+"<td>"+e.Desired_Placement+"</td>"+"<td>"+e.Actual_Placement+"</td>"+"<td>"+e.Vsan+"</td>"+"</tr>")});$(n).find(".template-network-dynamic").text(t.Network.DynamicVnic_Policy);$(n).find(".template-network-connectivity").text(t.Network.Connectivity_Policy);$("#Template-Details-vNICs ul").remove();t.Network.Nics.forEach(function(e){var t="";e.Vlans.forEach(function(e){t+="<tr>"+"<td>"+e.OperVnetName+"</td>"+"<td>"+e.Vnet+"</td>"+"<td>"+e.DefaultNet+"</td>"+"</tr>"});if(e.Adaptor_Profile==""){e.Adaptor_Profile="none"}if(e.Control_Policy==""){e.Control_Policy="none"}$("#Template-Details-vNICs-Collapse .table:first").parent().append('<ul style="list-style-type:none;padding:0;border-bottom: 2px solid #ddd;">'+'<li><table class="table table-condensed" style="width:100%;"><thead style="font-size:12px;">'+"<tr>"+'<th style="border-bottom:none;"><span class="glyphicon glyphicon-plus vnic-toggle" style="margin-right:2px;cursor:pointer;"></span>'+e.Name+"</th>"+'<th style="border-bottom:none;font-weight:normal;">'+e.Mac_Address+"</th>"+'<th style="min-width:50px;border-bottom:none;font-weight:normal;">'+e.Desired_Order+"</th>"+'<th style="min-width:50px;border-bottom:none;font-weight:normal;">'+e.Actual_Order+"</th>"+'<th style="min-width:50px;border-bottom:none;font-weight:normal;">'+e.Fabric_Id+"</th>"+'<th style="min-width:50px;border-bottom:none;font-weight:normal;">'+e.Desired_Placement+"</th>"+'<th style="min-width:50px;border-bottom:none;font-weight:normal;">'+e.Actual_Placement+"</th>"+'<th class="visible-large" style="border-bottom:none;font-weight:normal;">'+e.Adaptor_Profile+"</th>"+'<th class="visible-large" style="border-bottom:none;font-weight:normal;">'+e.Control_Policy+"</th>"+"</tr>"+"</thead></table></li>"+'<li class="nic-toggle" style="display:none;"><div class="row"><div class="col-md-4" style="margin-bottom:4px;margin-left:8px;"><table class="table table-condensed table-striped" style="font-size:11px; font-weight:normal;"><thead><tr>'+'<th style="border-bottom:none;font-weight:bold;">VLAN</th><th style="border-bottom:none;font-weight:bold;">VLAN ID</th><th style="border-bottom:none;font-weight:bold;">Native VLAN</th></tr></thead>'+"<tbody>"+t+"</tbody></div></div></li></ul>")});$("#Template-Details-iSCSI tbody tr").remove();t.iSCSI.forEach(function(e){$("#Template-Details-iSCSI tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.Overlay+"</td>"+"<td>"+e.Iqn+"</td>"+"<td>"+e.Adapter_Policy+"</td>"+"<td>"+e.Mac+"</td>"+"<td>"+e.Vlan+"</td>"+"</tr>")});if(t.Assoc_State=="associated"){$('#Template-Details .nav li a[href="#Template-Details-Vifs"]').show();$("#Template-Details-Vifs .Vif-Details").remove();var s=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Blades,function(e){return e.Dn==t.General.Associated_Server})[0];$.each(s.VIFs,function(e,t){var n="profile-vif-"+e;var r=$("#Profile-Vifs-Template").clone().prop("id",n).removeClass("hidden");$(r).find(".panel-title a").prop("href","#"+n+"-Collapse");$(r).find(".panel-collapse").prop("id",n+"-Collapse");$(r).find(".heading-icon:last").after(t.Name);$(r).addClass("Vif-Details");$(r).find(".physical tbody").append("<tr>"+"<td>"+t.Adapter_Port+"</td>"+"<td>"+t.Fex_Host_Port+"</td>"+"<td>"+t.Fex_Network_Port+"</td>"+"<td>"+t.FI_Server_Port+"</td>"+"</tr>");t.Circuits.forEach(function(e){$(r).find(".vifs tbody").append("<tr>"+"<td>"+e.Name+"</td>"+"<td>"+e.vNic+"</td>"+"<td>"+e.FI_Uplink+"</td>"+"<td>"+e.Link_State+"</td>"+"</tr>")});$(r).find(".panel-collapse").on("hidden.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").removeClass("hidden")});$(r).find(".panel-collapse").on("shown.bs.collapse",function(e,t){$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-th-list:first").addClass("hidden");$("#"+e.target.id).parent().find(".panel-heading:first .glyphicon-minus:first").removeClass("hidden")});$("#Profile-Vifs-Template").parent().append(r)});$("#Template-Details-Performance tbody tr").remove();$.each(t.Performance.vNics,function(e,n){$("#Template-Details-Vnic-Performance tbody").append("<tr>"+"<td>"+e+"</td>"+"<td>"+n.BytesRx+"</td>"+"<td>"+n.BytesTx+"</td>"+"<td>"+n.PacketsRx+"</td>"+"<td>"+n.PacketsRx+"</td>"+"<td>"+(n.BytesRxDeltaAvg*8/t.Performance.Interval/1048576).toFixed(4)+"</td>"+"<td>"+(n.BytesTxDeltaAvg*8/t.Performance.Interval/1048576).toFixed(4)+"</td>"+"</tr>")});$.each(t.Performance.vHbas,function(e,n){$("#Template-Details-Vhba-Performance tbody").append("<tr>"+"<td>"+e+"</td>"+"<td>"+n.BytesRx+"</td>"+"<td>"+n.BytesTx+"</td>"+"<td>"+n.PacketsRx+"</td>"+"<td>"+n.PacketsRx+"</td>"+"<td>"+(n.BytesRxDeltaAvg*8/t.Performance.Interval/1048576).toFixed(4)+"</td>"+"<td>"+(n.BytesTxDeltaAvg*8/t.Performance.Interval/1048576).toFixed(4)+"</td>"+"</tr>")})}else{$('#Template-Details .nav li a[href="#Template-Details-Vifs"]').hide()}$('#Template-Details .nav li a[href="#Template-Details-Boot"]').show();$("#Template-Blade-Configured tbody tr").remove();$("#Template-Blade-Configured ul").remove();var o=$.grep(Domains[$("#DomainSelect .hidden").text()].Policies.Boot_Policies,function(e){return e.Dn==t.Boot_Policy})[0];if(o!=null){$(n).find(".template-boot-name").text(o.Name);$(n).find(".template-boot-instance").text(o.Dn);$(n).find(".template-boot-description").text(o.Description);$(n).find(".template-boot-reboot").text(o.RebootOnUpdate);$(n).find(".template-boot-interface").text(o.EnforceVnicName);$(n).find(".template-boot-mode").text(o.BootMode);if($.isArray(o.Entries)){o.Entries.forEach(function(e){var t="";if(typeof e.Level2!="undefined"){t='<span class="glyphicon glyphicon-minus toggle-trigger" style="margin-right:10px;cursor:pointer;"></span>'}var n='<ul class="well"><li><table class="table table-condensed boot-entry"><body><tr>'+"<td>"+t+e.Level1.Type+"</td>"+"<td>"+e.Level1.Order+"</td>"+"</tr></tbody></table></li>";if(typeof e.Level2!="undefined"){e.Level2.forEach(function(t){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+'<td style="padding-left:30px">'+e.Level1.Type+" "+t.Type+"</td>"+"<td></td>"+"<td>"+t.VnicName+"</td>"+"<td>"+t.Type+"</td>"+"</tr></tbody></table></li>";if(typeof t.Level3!="undefined"){t.Level3.forEach(function(e){n+='<li class="boot-toggle"><table class="table table-condensed boot-entry"><body><tr>'+"<td></td><td></td><td></td>"+"<td>"+e.Type+"</td>"+"<td>"+e.Lun+"</td>"+"<td>"+e.Wwn+"</td>"+"</tr></tbody></table></li>"})}})}n+="</ul>";$("#Template-Blade-Configured .table:first").parent().append(n)})}}else{$("#Template-Details-Boot fieldset table td").text("")}if(t.Assoc_State=="associated"){$("#Template-Blade-Actual ul li").remove();var u=$.grep(Domains[$("#DomainSelect .hidden").text()].Inventory.Blades,function(e){return e.Dn==t.General.Associated_Server})[0];u.Actual_Boot_Order.forEach(function(e){var t="";t='<li class="parent_li"><span class="border"><span class="glyphicon glyphicon-minus-sign"></span>'+e.Descr+"</span>";e.Entries.forEach(function(e){t+="<ul><li>"+e+"</li></ul>"});t+="</li>";$("#Template-Blade-Actual ul:first").append(t)})}else{console.log("Inside Else");$('#Template-Details li a[href="#Template-Blade-Actual"]').closest("li").hide()}$(n).find(".template-policy-bios").text(t.Policies.Bios);$(n).find(".template-policy-firmware").text(t.Policies.Fw);$(n).find(".template-policy-ipmi").text(t.Policies.Ipmi);$(n).find(".template-policy-power").text(t.Policies.Power);$(n).find(".template-policy-scrub").text(t.Policies.Scrub);$(n).find(".template-policy-sol").text(t.Policies.Sol);$(n).find(".template-policy-stats").text(t.Policies.Stats)}function HandleProfileSelect(e){$.when(SetProfileDetailsData(e)).then(function(){$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#Template-Details .nav-pills a:first").tab("show");$("#Template-Blade-Boot-Nav li").removeClass("selected");$("#Template-Details-Boot .boot-nav-toggle").hide();$('#Template-Details-Boot .boot-nav a[href="#Template-Blade-Configured"]').closest("li").addClass("selected");$("#Template-Blade-Configured").show();$("#Template-Details").fadeIn(300)});$('a[href="#Template-Details-Network"]').on("shown.bs.tab",function(e){$("#Template-Details-vNICs-Collapse ul:first li:first th").each(function(){var e=$(this).index();var t=0;$("#Template-Details-vNICs-Collapse ul li:first th:nth-child("+(e+1)+")").each(function(){t=Math.max($(this).outerWidth(),t)});$("#Template-Details-vNICs-Collapse th:nth-child("+(e+1)+")").outerWidth(t)});$(window).resize(function(){if($("#Template-Details-vNICs-Collapse").is(":visible")){$("#Template-Details-vNICs-Collapse ul:first li:first th").each(function(){var e=$(this).index();var t=0;$("#Template-Details-vNICs-Collapse ul li:first th:nth-child("+(e+1)+")").each(function(){t=Math.max($(this).outerWidth(),t)});$("#Template-Details-vNICs-Collapse th:nth-child("+(e+1)+")").outerWidth(t)})}});$(".vnic-toggle").unbind("click").click(function(){$(this).closest("ul").find(".nic-toggle").toggle(300);$(this).toggleClass("glyphicon-plus");$(this).toggleClass("glyphicon-minus")});$(".Toggle-Collapse .toggle-expand-all").unbind("click").click(function(){$(this).closest(".panel-body").find(".nic-toggle:hidden").each(function(){$(this).toggle(300);$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-plus");$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-minus")})});$(".Toggle-Collapse .toggle-collapse-all").unbind("click").click(function(){$(this).closest(".panel-body").find(".nic-toggle:visible").each(function(){$(this).toggle(300);$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-plus");$(this).closest("ul").find(".vnic-toggle").toggleClass("glyphicon-minus")})})});$('a[href="#Template-Details-Boot"]').on("shown.bs.tab",function(e){$("#Template-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Template-Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())});$('a[href="#Template-Blade-Configured]').click(function(){$("#Template-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Template-Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$(window).resize(function(){$("#Template-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Template-Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$("#Template-Details-Boot .toggle-trigger").unbind("click").click(function(){$(this).closest("ul").find(".boot-toggle").toggle(300);$(this).toggleClass("glyphicon-plus");$(this).toggleClass("glyphicon-minus")})})})}function HandleBladeSelect(e){$.when(SetBladeDetailsData(e)).then(function(){$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#Blade-Details .nav-pills a:first").tab("show");$("#Blade-Details").fadeIn(300);$("#Blade-Boot-Nav li").removeClass("selected");$(".boot-nav-toggle").hide();$('#Blade-Boot-Nav a[href="#Blade-Configured"]').closest("li").addClass("selected");$("#Blade-Configured").show()});$('a[href="#Blade-Details-Boot"]').on("shown.bs.tab",function(e){$("#Blade-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())});$('a[href="#Blade-Configured]').click(function(){$("#Blade-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$(window).resize(function(){$("#Blade-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$(".toggle-trigger").unbind("click").click(function(){$(this).closest("ul").find(".boot-toggle").toggle(300);$(this).toggleClass("glyphicon-plus");$(this).toggleClass("glyphicon-minus")})})})}function HandleRackSelect(e){$.when(SetRackDetailsData(e)).then(function(){$.when($(".main-content, #Report-Nav").fadeOut(300)).then(function(){$("#Domain-Heading").scrollTop();$("#Blade-Details .nav-pills a:first").tab("show");$("#Blade-Details").fadeIn(300);$("#Blade-Boot-Nav li").removeClass("selected");$(".boot-nav-toggle").hide();$('#Blade-Boot-Nav a[href="#Blade-Configured"]').closest("li").addClass("selected");$("#Blade-Configured").show()});$('a[href="#Blade-Details-Boot"]').on("shown.bs.tab",function(e){$("#Blade-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())});$('a[href="#Blade-Configured]').click(function(){$("#Blade-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$(window).resize(function(){$("#Blade-Details-Boot .boot-entry td").each(function(){var e=$(this).index();$(this).outerWidth($(this).closest("#Blade-Configured").find("thead th:nth-child("+(e+1)+")").outerWidth())})});$(".toggle-trigger").unbind("click").click(function(){$(this).closest("ul").find(".boot-toggle").toggle(300);$(this).toggleClass("glyphicon-plus");$(this).toggleClass("glyphicon-minus")})})})}InitializeDomainList();$(".panel-collapse").collapse({toggle:false});$.when(SetReportData($("#DomainSelect .hidden").text())).then(function(){CallValidators();SetActions(true);$(".glyphicon-eye-open").each(function(){$(this).tooltip({trigger:"hover",placement:"top",title:"Click on a row below for a more detailed view"})});$(".glyphicon-search").each(function(){$(this).tooltip({trigger:"hover",placement:"top",title:"Click here to search items"})});$(".expand-template").each(function(){$(this).tooltip({trigger:"hover",placement:"top",title:"Click here to view template details"})})});$("#DomainSelect a").click(function(){var e=$(this);$("#SelectedDomain").html($(this).text()+'<span class="caret"></span>');$("#DomainSelect .hidden").removeClass("hidden");$(this).addClass("hidden");$(".details-div").hide();$.when($(".main-content, #Report-Nav").fadeOut(100)).then(function(){$.when(SetReportData(e.text())).then(function(){CallValidators();SetActions();$(".glyphicon-eye-open").each(function(){$(this).tooltip({trigger:"hover",placement:"top",title:"Click on a row below for a more detailed view"})});$(".glyphicon-search").each(function(){$(this).tooltip({trigger:"hover",placement:"top",title:"Click here to search items"})});$(".expand-template").each(function(){$(this).tooltip({trigger:"hover",placement:"top",title:"Click here to view template details"})});$(".main-content, #Report-Nav").fadeIn(100)})})});$(".collapse").on("hidden.bs.collapse",function(){$(this).parent().find(".panel-heading .glyphicon-minus").addClass("hidden");$(this).parent().find(".panel-heading .glyphicon-th-list").removeClass("hidden")});$(".collapse").on("shown.bs.collapse",function(){$(this).parent().find(".panel-heading .glyphicon-th-list").addClass("hidden");$(this).parent().find(".panel-heading .glyphicon-minus").removeClass("hidden")});$(".Collapse-All").click(function(){$(this).closest(".tab-pane").find(".panel-collapse").collapse("hide")});$(".Expand-All").click(function(){$(this).closest(".tab-pane").find(".panel-collapse").collapse("show")});$("#System-Fault-Icons").click(function(){$('#Report-Nav a[href="#Faults"]').tab("show")})
});
</script>
'@

#===================================================================================#
#	Function Definition:															#
#																					#
#	HandleExists - Checks if the passed hash variable contains an active UCS handle	#
#	Returns - true if handle exists or false if not									#
#===================================================================================#
function HandleExists ($Domain)
{
	$error.clear()
	try { Get-UcsStatus -Ucs $Domain.Handle | Out-Null}
	catch
	{
		return $false
	}
	if (!$error) { return $true }
}

#===================================================================================#
#	Function Definition:															#
#																					#
#	HaveHandle - Checks if any UCS handle exists in the global UCS hash variable	#
#	Returns - true if handle exists or false if not									#
#===================================================================================#
function HaveHandle ()
{
	foreach ($Domain in $UCS.get_keys())
	{
		if(HandleExists($UCS[$Domain])) {return 1}
	}
	return $false
}

#===================================================================================#
#	Function Definition:															#
#																					#
#	Connect_Ucs - Connects to a ucs domain either by interactive user prompts or	#
#	using cached credentials if the UseCached switch parameter is passed			#
#																					#
#===================================================================================#
function Connect_Ucs()
{
	#--- If UseCached parameter is passed then grab all UCS credentials from cache file and attempt to login ---#
	if($UseCached)
	{
		Clear-Host
		#--- Grab each line from the cache file, remove all white space, and pass to a foreach loop ---#
		Get-Content "$((Get-Location).Path)\ucs_cache.ucs" | ? {$_.trim() -ne ""} | % {
		
			#--- Split credential data - each line consists of UCS VIP, username, hashed password ---#
			$credData = $_.Split(",")
			
			#--- Ensure we have all three components if the credential data ---#
			if($credData.Count -eq 3)
			{
				#--- Clear system $error variable before trying a UCS connection ---#
				$error.clear()
				try
				{
					#--- Attempts to create a UCS handle and stores the handle into the global UCS hash variable if connection is successful ---#
					$domain = @{}
					$domain.VIP = $credData[0]
					#--- Creates a credential variable from the username and hashed password pulled from the cache entry ---#
					$domain.Creds = New-Object System.Management.Automation.PsCredential($credData[1], ($credData[2] | ConvertTo-SecureString))
					$domain.Handle = Connect-Ucs $domain.VIP -Credential $domain.Creds -NotDefault -ErrorAction SilentlyContinue
					#--- Checks that handle actually exists ---#
					Get-UcsStatus -Ucs $domain.Handle | Out-Null
					
				}
				#--- Catch any failed domain connections ---#
				catch [Exception]
				{
					#--- Allow user to continue/exit script execution if a connection fails ---#
					$ans = Read-Host "Error connecting to UCS Domain at $($domain.VIP)  Press C to continue or any other key to exit"
					Switch -regex ($ans.ToUpper())
					{
						"^[C]" {
							continue
						}
						default { exit }
					}
				}
				#--- Display a message to the user that the attempted UCS domain connection was successful and add handle to global UCS variable ---#
				if (!$error)
				{
					Write-Host "Successfully Connected to UCS Domain: $($domain.Handle.Ucs)"
					$domain.Name = $domain.Handle.Ucs
					$script:UCS.Add($domain.Handle.Ucs, $domain)
					$script:UCS_Creds[$domain.Handle.Ucs] = @{}
					$script:UCS_Creds[$domain.Handle.Ucs].VIP = $domain.VIP
					$script:UCS_Creds[$domain.Handle.Ucs].Creds = $domain.Creds
				}
			}
		}
		sleep(1)
	}
	#--- Connect to a single UCS domain through an interactive prompt ---#
	else
	{
		while ($true)
		{
			Clear-Host 
			#--- Prompts user for UCS IP/DNS and user creential ---#
			Write-Host "Please enter the UCS Domain information"
			$domain = @{}
			$domain.VIP = Read-Host "VIP or DNS"
			Write-Host "Prompting for username and password..."
			$domain.Creds = Get-Credential
			
			#--- Clear error variable to check for failed connections ---#
			$error.clear()
			try
			{
				#--- Attempt UCS connection from entered data ---#
				$domain.Handle = Connect-Ucs $domain.VIP -Credential $domain.Creds -NotDefault -ErrorAction SilentlyContinue
				#--- Checks that handle actually exists ---#
				Get-UcsStatus -Ucs $domain.Handle | Out-Null
				
			}
			#--- Catch failed connection attempts and allow user to re-enter credentials ---#
			catch [Exception]
			{
				#--- Press M to return to menu or any other key to re-enter credentials ---#
				$ans = Read-Host "Error connecting to UCS Domain.  Press enter to retry or M to return to Main Menu"
				Switch -regex ($ans.ToUpper())
				{
					"^[M]" {
						return
					}
					default { continue }
				}
			}
			if (!$error)
			{
				#--- Notify the user that the connection was successful and add handle to global UCS variable ---#
				Write-Host "`nSuccessfully Connected to UCS Domain: $($domain.Handle.Ucs)"
				Write-Host "Redirecting to Main Menu..."
				$domain.Name = $domain.Handle.Ucs
				$script:UCS.Add($domain.Handle.Ucs, $domain)
				$script:UCS_Creds[$domain.Handle.Ucs] = @{}
				$script:UCS_Creds[$domain.Handle.Ucs].VIP = $domain.VIP
				$script:UCS_Creds[$domain.Handle.Ucs].Creds = $domain.Creds
				sleep(2)
				break
			}
		}
	}
}

#===================================================================================#
#	Function Definition:															#
#																					#
#	Connection_Mgmt - Text driven menu interface for allowing users	to connect,		#
#	disconnect, and cache UCS domain information									#
#																					#
#===================================================================================#
function Connection_Mgmt()
{

	$conn_menu = "
     Connection Management
			
1. Connect to a UCS Domain			
2. List Active Sessions
3. Cache current connections
4. Clear session cache
5. Select Session for Disconnect
6. Disconnect all Active Sessions
7. Return to Main Menu
"
	while ($true)
	{
		Clear-Host
		Write-Host $conn_menu
		$option = Read-Host "Enter Command Number"
		Switch ($option)
		{
			1 { Connect_Ucs }
			
			#--- Print all active UCS handles to the screen ---#
			2 {	
				Clear-Host
				if(!(HaveHandle)){
					Read-Host "There are currently no connected UCS domains`n`nPress any key to continue"
					break
				}
				$index = 1
				Write-Host "`t`tActive Session List`n$("-"*60)"
				foreach	($Domain in $UCS.get_keys())
				{
					#--- Checks if the UCS domain is active and prints a formatted list ---#
					if(HandleExists($UCS[$Domain]))
					{
						"{0,-28} {1,20}" -f "$index) $($UCS[$Domain].Name)",$UCS[$Domain].VIP
						$index++
					}
				}
				Read-Host "`nPress any key to return to menu"

			}
			
			#--- Cache all UCS handles to a cache file for future reference ---#
			3 {
				#--- Check for an empty domain list ---#
				if($UCS_Creds.Count -eq 0)
				{
					Read-Host "`nThere are currently no connected UCS domains`n`nPress any key to continue"
					break
				}
				#--- Iterate through UCS domain hash and store information to cache file ---#
				foreach	($Domain in $UCS.get_keys())
				{
					#--- If the cache file already exists remove any lines that match the current domain name ---#
					If(Test-Path "$((Get-Location).Path)\ucs_cache.ucs")
					{
						(Get-Content "$((Get-Location).Path)\ucs_cache.ucs") | % {$_ -replace "$($UCS_Creds[$Domain].VIP).*", ""} | Set-Content "$((Get-Location).Path)\ucs_cache.ucs"
					}
					#--- Add the current domain access data to the cache ---#
					$UCS_Creds[$Domain].VIP + ',' + $UCS_Creds[$Domain].Creds.Username + ',' + ($UCS_Creds[$Domain].Creds.Password | ConvertFrom-SecureString) | Add-Content "$((Get-Location).Path)\ucs_cache.ucs"
				}
				Read-Host "`nCredentials have been cached to $((Get-Location).Path)\ucs_cache.ucs`n`nPress any key to continue"
			
			}
			
			#--- Removes the UCS cache file for storing domain connection data ---#
			4 {
				Remove-Item "$((Get-Location).Path)\ucs_cache.ucs"
			
			}
			
			#--- Text driven user interface for disconnecting from multiple UCS domains ---#
			5 {
				Clear-Host
				if(!(HaveHandle)){
					Read-Host "There are currently no connected UCS domains`n`nPress any key to continue"
					break
				}
				$index = 1
				$target = @{}
				Write-Host "`t`tActive Session List`n$("-"*60)"
				
				#--- Creates a hash of all active domains and prints them in a list ---#
				foreach	($Domain in $UCS.get_keys())
				{
					if(HandleExists($UCS[$Domain]))
					{
						"{0,-28} {1,20}" -f "$index) $($UCS[$Domain].Name)",$UCS[$Domain].VIP
						$target.add($index, $UCS[$Domain].Name)
						$index++
					}
				}
				
				$command = Read-host "`nPlease Select Domains to disconnect (comma separated)"
				$disconnectList = $command.split(",")
				foreach($id in $disconnectList){
					#--- Check if entered id is within the valid range ---#
					if($id -lt 1 -or $id -gt $target.count)
					{
						Write-Host "$id is not a valid option.  Ommitting..."
					}
					#--- Disconnect UCS handle ---#
					else
					{
						Write-Host "Disconnecting $($target[[int]$id])..."
						$target[$id]
						Disconnect-Ucs -Ucs $UCS[$target[[int]$id]].Handle
						$script:UCS.Remove($target[[int]$id])
					}
				}
				Read-Host "`nPress any key to return to continue"
				
			}
			
			#--- Disconnects all UCS domain handles ---#
			6 {
				Clear-Host
				if(!(HaveHandle)){
					Read-Host "There are currently no connected UCS domains`n`nPress any key to continue"
					break
				}
				$target = @()
				foreach	($Domain in $UCS.get_keys())
				{
					if(HandleExists($UCS[$Domain]))
					{
						Write-Host "Disconnecting $($UCS[$Domain].Name)..."
						Disconnect-Ucs -Ucs $UCS[$Domain].Handle
						$target += $UCS[$Domain].Name
					}
				}
				foreach ($id in $target)
				{
					$script:UCS.Remove($id)
				}
				
				Read-Host "`nPress any key to continue"
				break
			}
			#--- Returns to the main menu ---#
			7 {
				return
			}
			default {
				Read-Host "Invalid Option.  Please select a valid option from the Menu above`nPress any key to continue"
			}
		}
	}
}

#===================================================================================#
#	Function Definition:															#
#																					#
#	Get-SaveFile - Creates a Windows File Dialog to select the save file location	#
#																					#
#===================================================================================#
Function Get-SaveFile($initialDirectory)
{
	Clear-Host
	
	#--- SaveDialog Form requires powershell version 3.0 or higher.  Check for the users powershell version ---#
	if($Version -gt 2)
	{
		[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

		$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
		$SaveFileDialog.initialDirectory = $initialDirectory
		$SaveFileDialog.filter = "HTML Document (*.html)| *.html"
		$SaveFileDialog.ShowDialog() | Out-Null
		$SaveFileDialog.filename
	}
	#--- If user powershell version is less than 3.0 use a text based prompt for collecting file-path ---#
	else
	{
		while ($true)
		{
			$savePath = Read-Host "Please enter the path for where the report will be saved"
			if (!(Test-Path $savePath))
			{
				Write-Host "Error: File Path could not be validated`n"
			}
			else
			{
				$fileName = Read-Host "Please enter the filename for the report (no file extensions)"
				$savePath = $savePath + "$filename.html"
				$savePath
				break
			}
		}
		
	}
} 

#===================================================================================#
#	Function Definition:															#
#																					#
#	Generate_Health_Check - Function for creating the html health check report for	#
#	all of the connected UCS domains												#
#																					#
#===================================================================================#
function Generate_Health_Check
{
	#--- Check to ensure an active UCS handle exists before generating the report ---#
	if(!(HaveHandle)){
		Read-Host "There are currently no connected UCS domains`n`nPress any key to continue"
		return
	}
	#--- Function variable that computes the elapsed time based on the start time parameter and returns a formatted time string ---#
	$GetElapsedTime = {
		param ($start)
		$runtime = $(get-date) - $start
		$retStr = [string]::format("{0} days, {1} hours, {2} minutes, {3}.{4} seconds", `
			$runtime.Days, `
			$runtime.Hours, `
			$runtime.Minutes, `
			$runtime.Seconds, `
			$runtime.Milliseconds)
		$retStr
	}
	if($Silent)
	{
		$OutputFile = $Silent_Path + $Silent_FileName
	}
	else
	{
		#--- Grab filename for the report ---#
		$OutputFile = Get-SaveFile
	}
	Clear-Host
	Write-Host "Generating Report..."
	
	#--- Get Start time to track report generation run time ---#
	$start = get-date
	
	#--- Creates a synchronized hash variable of all the UCS domains and credential info ---#
	$Process_Hash = [hashtable]::Synchronized(@{})
	$Process_Hash.Creds = $UCS_Creds
	$Process_Hash.Keys = @()
	$Process_Hash.Keys += $UCS.get_keys()
	$Process_Hash.Domains = @{}
	$Process_Hash.Progress = @{}
	
	#--- Function Variable called for each UCS domain ---#
	$GetUcsData = {
		Param ($domain, $Process_Hash)
		
		#--- Set Job Progress to 0 and connect to the UCS domain passed ---#
		$Process_Hash.Progress[$domain] = 0;
		Import-Module CiscoUcsPs
		$handle = Connect-Ucs $Process_Hash.Creds[$domain].VIP -Credential $Process_Hash.Creds[$domain].Creds

		#--- Initialize DomainHash variable for this domain ---#
		Start-UcsTransaction -Ucs $handle
		$DomainHash = @{}
		$DomainHash.System = @{}
		$DomainHash.Inventory = @{}
		$DomainHash.Policies = @{}
		$DomainHash.Profiles = @{}
		$DomainHash.Lan = @{}
		$DomainHash.San = @{}
		$DomainHash.Faults = @()
		
		#===================================#
		#	Start System Data Collection	#
		#===================================#
		$Process_Hash.Progress[$domain] = 1
		
		#--- Get UCS Cluster State ---#
		$system = Get-UcsStatus -Ucs $handle | Select-Object Name,VirtualIpv4Address,HaReady,FiALeadership,FiAManagementServicesState,FiBLeadership,FiBManagementServicesState
		$DomainName = $system.Name
		$DomainHash.System.VIP = $system.VirtualIpv4Address
		$DomainHash.System.UCSM = (Get-UcsMgmtController -Ucs $handle -Subject system | Get-UcsFirmwareRunning).Version
		$DomainHash.System.HA_Ready = $system.HaReady
		#--- Get Full State and Logical backup configuration ---#
		$DomainHash.System.Backup_Policy = (Get-UcsMgmtBackupPolicy -Ucs $handle | Select AdminState).AdminState
		$DomainHash.System.Config_Policy = (Get-UcsMgmtCfgExportPolicy -Ucs $handle | Select AdminState).AdminState
		#--- Get Call Home admin state ---#
		$DomainHash.System.CallHome = (Get-UcsCallHome -Ucs $handle | Select-Object AdminState).AdminState
		#--- Get System and Server power statistics ---#
		$DomainHash.System.Chassis_Power = @()
		$DomainHash.System.Chassis_Power += Get-UcsChassisStats -Ucs $handle | Select-Object Dn,InputPower,InputPowerAvg,InputPowerMax,OutputPower,OutputPowerAvg,OutputPowerMax,Suspect
		$DomainHash.System.Chassis_Power | % {$_.Dn = $_.Dn -replace ('(sys[/])|([/]stats)',"") }
		$DomainHash.System.Server_Power = @()
		$DomainHash.System.Server_Power += Get-UcsComputeMbPowerStats -Ucs $handle | Sort-Object -Property Dn | Select-Object Dn,ConsumedPower,ConsumedPowerAvg,ConsumedPowerMax,InputCurrent,InputCurrentAvg,InputVoltage,InputVoltageAvg,Suspect
		$DomainHash.System.Server_Power | % {$_.Dn = $_.Dn -replace ('([/]board.*)',"") }
		#--- Get Server temperatures ---#
		$DomainHash.System.Server_Temp = @()
		$DomainHash.System.Server_Temp += Get-UcsComputeMbTempStats -Ucs $handle | Sort-Object -Property Ucs,Dn | Select-Object Dn,FmTempSenIo,FmTempSenIoAvg,FmTempSenIoMax,FmTempSenRear,FmTempSenRearAvg,FmTempSenRearMax,FmTempSenRearL,FmTempSenRearLAvg,FmTempSenRearLMax,FmTempSenRearR,FmTempSenRearRAvg,FmTempSenRearRMax,Suspect
		$DomainHash.System.Server_Temp | % {$_.Dn = $_.Dn -replace ('([/]board.*)',"") }
		
		#===================================#
		#	Start Inventory Collection		#
		#===================================#
		
		#--- Start Fabric Interconnect Inventory Collection ---#
		
		#--- Set Job Progress ---#
		$Process_Hash.Progress[$domain] = 12
		$DomainHash.Inventory.FIs = @()
		#--- Iterate through Fabric Interconnects and grab relevant data points ---#
		Get-UcsNetworkElement -Ucs $handle | % {
			#--- Store current pipe value to fi variable ---#
			$fi = $_
			#--- Hash variable for storing current FI details ---#
			$fiHash = @{}
			$fiHash.Dn = $fi.Dn
			$fiHash.Fabric_Id = $fi.Id
			$fiHash.Operability = $fi.Operability
			$fiHash.Thermal = $fi.Thermal
			#--- Get leadership role and management service state ---#
			if($fi.Id -eq "A")
			{
				$fiHash.Role = $system.FiALeadership
				$fiHash.State = $system.FiAManagementServicesState
			}
			else
			{
				$fiHash.Role = $system.FiBLeadership
				$fiHash.State = $system.FiAManagementServicesState
			}
			
			#--- Get the common name of the fi from the manufacturing definition and format the text ---#
			$fiModel = (Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "Sku -cmatch $($fi.Model)" | Select-Object Name).Name -replace "Cisco UCS ", ""
			if($fiModel -is [array]) { $fiHash.Model = $fiModel.Item(0) -replace "Cisco UCS ", "" }
			else { $fiHash.Model = $fiModel -replace "Cisco UCS ", "" }
			
			
			$fiHash.Serial = $fi.Serial
			#--- Get FI System and Kernel FW versions ---#
			${fiBoot} = Get-UcsMgmtController -Ucs $handle -Dn "$($fi.Dn)/mgmt" | Get-ucsfirmwarebootdefinition | Get-UcsFirmwareBootUnit -Filter 'Type -ieq system -or Type -ieq kernel' | Select-Object Type,Version
			$fiHash.System = (${fiBoot} | where {$_.Type -eq "system"}).Version
			$fiHash.Kernel = (${fiBoot} | where {$_.Type -eq "kernel"}).Version
			
			#--- Get out of band management IP and Port licensing information ---#
			$fiHash.IP = $fi.OobIfIp
			$fiHash.Ports_Used = (Get-UcsLicense -Ucs $handle -Scope $fi.Id | Select-Object UsedQuant).UsedQuant
			$fiHash.Ports_Licensed = (Get-UcsLicense -Ucs $handle -Scope $fi.Id | Select-Object AbsQuant).AbsQuant
			
			#--- Get Ethernet and FC Switching mode of FI ---#
			$fiHash.Ethernet_Mode = (Get-UcsLanCloud -Ucs $handle).Mode
			$fiHash.FC_Mode = (Get-UcsSanCloud -Ucs $handle).Mode
			
			#--- Get Local storage, VLAN, and Zone utilization numbers ---#
			$fiHash.Storage = $fi | Get-UcsStorageItem | Select Name,Size,Used
			$fiHash.VLAN = $fi | Get-UcsSwVlanPortNs | Select Limit,AccessVlanPortCount,BorderVlanPortCount,AllocStatus
			$fiHash.Zone = $fi | Get-UcsManagedObject -Classid SwFabricZoneNs | Select-Object Limit,ZoneCount,AllocStatus
			
			#--- Sort Expression to filter port id to be just the numerical port number and sort ascending ---#
			$sortExpr = {if ($_.Dn -match "(?=port[-]).*") {($matches[0] -replace ".*(?<=[-])",'') -as [int]}}
			#--- Get Fabric Port Configuration and sort by port id using the above sort expression ---#
			$fiHash.Ports = Get-UcsFabricPort -Ucs $handle -SwitchId "$($fi.Id)" -AdminState enabled | Sort-Object $sortExpr | Select-Object AdminState,Dn,IfRole,IfType,LicState,LicGP,Mac,Mode,OperState,OperSpeed,XcvrType,PeerDn,PeerPortId,PeerSlotId,PortId,SlotId,SwitchId
			
			#--- Store fi hash to domain hash variable ---#
			$DomainHash.Inventory.FIs += $fiHash
			
			#--- Get FI Role and IP for system tab of report ---#
			if($fiHash.Fabric_Id -eq 'A')
			{
				$DomainHash.System.FI_A_Role = $fiHash.Role
				$DomainHash.System.FI_A_IP = $fiHash.IP
			}
			else
			{
				$DomainHash.System.FI_B_Role = $fiHash.Role
				$DomainHash.System.FI_B_IP = $fiHash.IP
			}
		
		}
		#--- End FI Inventory Collection ---#
		
		#--- Start Chassis Inventory Collection ---#
		
		#--- Initialize array variable for storing Chassis data ---#
		$DomainHash.Inventory.Chassis = @()
		#--- Iterate through chassis inventory and grab relevant data ---#
		Get-UcsChassis -Ucs $handle | % {
			#--- Store current pipe variable ---#
			$chassis = $_
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
			$chassisHash.Blades = @()	
			
			#--- Initialize chassis used slot count to 0 ---#
			$slotCount = 0
			#--- Iterate through all blades within current chassis ---#
			$chassis | Get-UcsBlade | Select Model,SlotId,AssignedToDn | % {
				#--- Hash variable for storing current blade data ---#
				$bladeHash = @{}
				$bladeHash.Model = $_.Model
				$bladeHash.SlotId = $_.SlotId
				$bladeHash.Service_Profile = $_.AssignedToDn
				#--- Get width of blade and convert to slot count ---#
				$bladeHash.Width = [math]::floor(((Get-UcsEquipmentPhysicalDef -Filter "Dn -ilike *$($_.Model)*").Width)/8)
				#--- Increment used slot count by current blade width ---#
				$slotCount += $bladeHash.Width
				$chassisHash.Blades += $bladeHash
			}
			#--- Get Used slots and slots available from iterated slot count ---#
			$chassisHash.SlotsUsed = $slotCount
			$chassisHash.SlotsAvailable = 8 - $slotCount
			
			#--- Get chassis PSU data and redundancy mode ---#
			$chassisHash.Psus = $chassis | Get-UcsPsu | Sort Id | Select Type,Id,Model,Serial,Dn
			$chassisHash.Power_Redundancy = ($chassis | Get-UcsComputePsuControl | Select Redundancy).Redundancy
			
			#--- Add chassis to domain hash variable ---#
			$DomainHash.Inventory.Chassis += $chassisHash
		}
		#--- End Chassis Inventory Collection ---#
		
		#--- Start IOM Inventory Collection ---#
		
		#--- Increment job progress ---#
		$Process_Hash.Progress[$domain] = 24

		#--- Get all fabric and blackplane ports for future iteration ---#
		$FabricPorts = Get-UcsEtherSwitchIntFIo -Ucs $handle
		$BackplanePorts = Get-UcsEtherServerIntFIo -Ucs $handle
		
		#--- Initialize array for storing IOM inventory data ---#
		$DomainHash.Inventory.IOMs = @()
		#--- Iterate through each IOM and grab relevant data ---#
		Get-UcsIom -Ucs $handle | Select-Object ChassisId,SwitchId,Model,Serial,Dn | % {
			$iom = $_
			$iomHash = @{}
			$iomHash.Dn = $iom.Dn
			$iomHash.Chassis = $iom.ChassisId
			$iomHash.Fabric_Id = $iom.SwitchId
			
			#--- Get common name of IOM model and format for viewing ---#
			$iomHash.Model = (Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "Sku -cmatch $($iom.Model)").Name -replace "Cisco UCS ", ""
			$iomHash.Serial = $iom.Serial
			
			#--- Get the IOM uplink port channel name if configured ---#
			$iomHash.Channel = (Get-ucsportgroup -Ucs $handle -Dn "$($iom.Dn)/fabric-pc" | Get-UcsEtherSwitchIntFIoPc).Rn
			
			#--- Get IOM running and backup fw versions ---#
			$iomHash.Running_FW = (Get-UcsMgmtController -Ucs $handle -Dn "$($iom.Dn)/mgmt" | Get-UcsFirmwareRunning -Deployment system | Select-Object Version).Version
			$iomHash.Backup_FW = (Get-UcsMgmtController -Ucs $handle -Dn "$($iom.Dn)/mgmt" | Get-UcsFirmwareUpdatable | Select-Object Version).Version
			
			#--- Initialize FabricPorts array for storing IOM port data ---#
			$iomHash.FabricPorts = @()
			
			#--- Iterate through all fabric ports tied to the current IOM ---#
			$FabricPorts | ? {$_.ChassisId -eq "$($iomHash.Chassis)" -and $_.SwitchId -eq "$($iomHash.Fabric_Id)"} | Select-Object SlotId,PortId,OperState,EpDn,PeerSlotId,PeerPortId,SwitchId,Ack,PeerDn | % {
				#--- Hash variable for storing current fabric port data ---#
				$portHash = @{}
				$portHash.Name = 'Fabric Port ' + $_.SlotId + '/' + $_.PortId
				$portHash.OperState = $_.OperState
				$portHash.PortChannel = $_.EpDn
				$portHash.PeerSlotId = $_.PeerSlotId
				$portHash.PeerPortId = $_.PeerPortId
				$portHash.FabricId = $_.SwitchId
				$portHash.Ack = $_.Ack
				$portHash.Peer = $_.PeerDn
				#--- Add current fabric port hash variable to FabricPorts array ---#
				$iomHash.FabricPorts += $portHash
			}
			#--- Initialize BackplanePorts array for storing IOM port data ---#
			$iomHash.BackplanePorts = @()
			
			#--- Iterate through all backplane ports tied to the current IOM ---#
			$BackplanePorts | ? {$_.ChassisId -eq "$($iomHash.Chassis)" -and $_.SwitchId -eq "$($iomHash.Fabric_Id)"} | Sort-Object {($_.SlotId) -as [int]},{($_.PortId) -as [int]} | Select-Object SlotId,PortId,OperState,EpDn,SwitchId,PeerDn | % {
				#--- Hash variable for storing current backplane port data ---#
				$portHash = @{}
				$portHash.Name = 'Backplane Port ' + $_.SlotId + '/' + $_.PortId
				$portHash.OperState = $_.OperState
				$portHash.PortChannel = $_.EpDn
				$portHash.FabricId = $_.SwitchId
				$portHash.Peer = $_.PeerDn
				#--- Add current backplane port hash variable to FabricPorts array ---#
				$iomHash.BackplanePorts += $portHash
			}
			#--- Add IOM to domain hash variable ---#
			$DomainHash.Inventory.IOMs += $iomHash
		}
		#--- End IOM Inventory Collection ---#
		
		#--- Start Blade Inventory Collection ---#
		
		#--- Get all memory and vif data for future iteration ---#
		$memoryArray = Get-UcsMemoryUnit -Ucs $handle
		$paths = Get-UcsFabricPathEp -Ucs $handle
		
		#--- Set progress of current job ---#
		$Process_Hash.Progress[$domain] = 36
		
		#--- Initialize array for storing blade data ---#
		$DomainHash.Inventory.Blades = @()
			
		#--- Iterate through each blade and grab relevant data ---#	
		Get-UcsBlade -Ucs $handle | % {
			#--- Store current pipe variable to local variable ---#
			$blade = $_
			#--- Hash variable for storing current blade data ---#
			$bladeHash = @{}
			
			$bladeHash.Dn = $blade.Dn
			$bladeHash.Status = $blade.OperState
			$bladeHash.Chassis = $blade.ChassisId
			$bladeHash.Slot = $blade.SlotId
			($bladeHash.Model,$bladeHash.Model_Description) = Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "Sku -ieq $($blade.Model)" | Select Name,Description | % {($_.Name -replace "Cisco UCS ", ""),$_.Description}
			$bladeHash.Serial = $blade.Serial
			$bladeHash.Uuid = $blade.Uuid
			$bladeHash.UsrLbl = $blade.UsrLbl
			$bladeHash.Name = $blade.Name
			$bladeHash.Service_Profile = $blade.AssignedToDn
			
			#--- If blade doesn't have a service profile set profile name to Unassociated ---#
			if(!($bladeHash.Service_Profile))
			{
				$bladeHash.Service_Profile = "Unassociated"
			}
			#--- Get blade child object for future iteration ---#
			$childTargets = $blade | Get-UcsChild | where {$_.Rn -ieq "bios" -or $_.Rn -ieq "mgmt" -or $_.Rn -ieq "board"} | get-ucschild
			
			#--- Get blade CPU data ---#
			$cpu = ($childTargets | where {$_.Rn -match "cpu"} | Select-Object -first 1).Model
			#--- Get CPU common name and format text ---#
			$bladeHash.CPU_Model = '(' + $blade.NumOfCpus + ') ' + ($cpu.Substring(([regex]::match($cpu,'CPU ').Index) + ([regex]::match($cpu,'CPU ').Length))).Replace(" ","")
			$bladeHash.CPU_Cores = $blade.NumOfCores
			$bladeHash.CPU_Threads = $blade.NumOfThreads
			#--- Format available memory in GB ---#
			$bladeHash.Memory = $blade.AvailableMemory/1024
			$bladeHash.Memory_Speed = $blade.MemorySpeed
			$bladeHash.BIOS = (($childTargets | where {$_.Type -eq "blade-bios"}).Version -replace ('(?!(.*[.]){2}).*',"")).TrimEnd('.')
			$bladeHash.CIMC = ($childTargets | where {$_.Type -eq "blade-controller" -and $_.Deployment -ieq "system"}).Version
			$bladeHash.Board_Controller = ($childTargets | where {$_.Type -eq "board-controller"}).Version
			
			#--- Set Board Controller model to N/A if not present ---#
			if(!($bladeHash.Board_Controller))
			{
				$bladeHash.Board_Controller = 'N/A'
			}
			#--- Array variable for storing blade adapter data ---#
			$bladeHash.Adapters = @()
			
			#--- Iterate through each blade adapter and grab relevant data ---#
			$blade | Get-UcsAdaptorUnit | % {
				#--- Hash variable for storing current adapter data ---#
				$adapterHash = @{}
				#--- Get common name of adapter and format string ---#
				$adapterHash.Model = (Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "Sku -ieq $($_.Model)").Name -replace "Cisco UCS ", ""
				$adapterHash.Name = 'Adaptor-' + $_.Id
				$adapterHash.Slot = $_.Id
				$adapterHash.Fw = ($_ | Get-UcsMgmtController | Get-UcsFirmwareRunning -Deployment system).Version
				$adapterHash.Serial = $_.Serial
				#--- Add current adapter hash to blade adapter array ---#
				$bladeHash.Adapters += $adapterHash
			}
			
			#--- Array variable for storing blade memory data ---#
			$bladeHash.Memory_Array = @()
			#--- Iterage through all memory tied to current server and grab relevant data ---#
			$memoryArray | ? {$_.Dn -match $blade.Dn} | Select Id,Location,Capacity,Clock | Sort-Object {($_.Id) -as [int]} | % {
				#--- Hash variable for storing current memory data ---#
				$memHash = @{}
				$memHash.Name = "Memory " + $_.Id
				$memHash.Location = $_.Location
				#--- Format DIMM capacity in GB ---#
				$memHash.Capacity = ($_.Capacity)/1024
				$memHash.Clock = $_.Clock
				$bladeHash.Memory_Array += $memHash
			}
			#--- Array variable for storing local storage configuration data ---#
			$bladeHash.Storage = @()
			
			#--- Iterate through each blade storage controller and grab relevant data ---#
			$blade | Get-UcsComputeBoard | Get-UcsStorageController | % {
				#--- Store current pipe variable to local variable ---#
				$controller = $_
				#--- Hash variable for storing current storage controller data ---#
				$controllerHash = @{}
				
				#--- Grab relevant controller data and store to respective controllerHash variable ---#
				$controllerHash.Id,$controllerHash.Vendor,$controllerHash.Revision,$controllerHash.RaidSupport,$controllerHash.PciAddr,$controllerHash.RebuildRate,$controllerHash.Model,$controllerHash.Serial,$controllerHash.ControllerStatus = $controller.Id,$controller.Vendor,$controller.HwRevision,$controller.RaidSupport,$controller.PciAddr,$controller.XtraProperty.RebuildRate,$controller.Model,$controller.Serial,$controller.XtraProperty.ControllerStatus
				$controllerHash.Disk_Count = 0
				#--- Array variable for storing controller disks ---#
				$controllerHash.Disks = @()
				#--- Iterate through each local disk and grab relevant data ---#
				$controller | Get-UcsStorageLocalDisk -Presence "equipped" | % {
					#--- Store current pipe variable to local variable ---#
					$disk = $_
					#--- Hash variable for storing current disk data ---#
					$diskHash = @{}
					#--- Get common name of disk model and format text ---#
					$equipmentDef = Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "OemPartNumber -ieq $($disk.Model)"
					#--- Get detailed disk capability data ---#
					$capabilities = Get-UcsEquipmentLocalDiskDef -Ucs $handle -Filter "Dn -cmatch $($disk.Model)"
					$diskHash.Id = $disk.Id
					$diskHash.Pid = $equipmentDef.Pid
					$diskHash.Vendor = $disk.Vendor
					$diskHash.Vid = $equipmentDef.Vid
					$diskHash.Serial = $disk.Serial
					$diskHash.Product_Name = $equipmentDef.Name
					$diskHash.Drive_State = $disk.XtraProperty.DiskState
					$diskHash.Power_State = $disk.XtraProperty.PowerState
					#--- Format disk size to whole GB value ---#
					$diskHash.Size = "{0:N2}" -f ($disk.Size/1024)
					$diskHash.Link_Speed = $disk.XtraProperty.LinkSpeed
					$diskHash.Blocks = $disk.NumberOfBlocks
					$diskHash.Block_Size = $disk.BlockSize
					$diskHash.Technology = $capabilities.Technology
					$diskHash.Avg_Seek_Time = $capabilities.SeekAverageReadWrite
					$diskHash.Track_To_Seek = $capabilities.SeekTrackToTrackReadWrite
					$diskHash.Operability = $disk.Operability
					$diskHash.Presence = $disk.Presence
					$diskHash.Running_Version = ($disk | Get-UcsFirmwareRunning).Version
					$controllerHash.Disk_Count += 1
					#--- Add current disk hash to controller hash disk array ---#
					$controllerHash.Disks += $diskHash
				}
				#--- Add controller hash variable to current blade hash storage array ---#
				$bladeHash.Storage += $controllerHash
			}
			
			#--- Array variable for storing VIF information for current blade ---#
			$bladeHash.VIFs = @()
			#--- Grab all circuits that match the current blade DN and are active or link-down ---#
			$circuits = Get-UcsDcxVc -Ucs $handle -Filter "Dn -cmatch $($blade.Dn) -and (OperState -cmatch active -or OperState -cmatch link-down)" | Select Dn,Id,OperBorderPortId,OperBorderSlotId,SwitchId,Vnic,LinkState
			#--- Iterate through all paths of type "mux-fabric" for the current blade ---#
			$paths | ? {$_.Dn -Match $blade.Dn -and $_.CType -match "mux-fabric" -and $_.CType -notmatch "mux-fabric(.*)?[-]"} | % {
				#--- Store current pipe variable to local variable ---#
				$vif = $_
				#--- Hash variable for storing current VIF data ---#
				$vifHash = @{}
				
				#--- The name of the current Path formatted to match the presentation in UCSM ---#
				$vifHash.Name = "Path " + $_.SwitchId + '/' + ($_.Dn | Select-String -pattern "(?<=path[-]).*(?=[/])")[0].Matches.Value
				
				#--- Gets peer port information filtered to the current path for adapter and fex host port ---#
				$vifPeers = $paths | ? {$_.EpDn -match ($vif.EpDn | Select-String -pattern ".*(?=(.*[/]){2})").Matches.Value -and $_.Dn -match ($vif.Dn | Select-String -pattern ".*(?=(.*[/]){3})").Matches.Value -and $_.Dn -ne $vif.Dn}									
				#--- If Adapter PortId is greater than 1000 then format string as a port channel ---#
				if($vifPeers[1].PeerPortId -gt 1000)
				{
					$vifHash.Adapter_Port = 'PC-' + $vifPeers[1].PeerPortId
				}
				#--- Else format in slot/port notation ---#
				else
				{
					$vifHash.Adapter_Port = "$($vifPeers[1].PeerSlotId)/$($vifPeers[1].PeerPortId)"
				}
				#--- If FEX PortId is greater than 1000 then format string as a port channel ---#
				if($vifPeers[0].PortId -gt 1000)
				{
					$vifHash.Fex_Host_Port = 'PC-' + $vifPeers[0].PortId
				}
				#--- Else format in chassis/slot/port notation ---#
				else
				{
					$vifHash.Fex_Host_Port = "$($vifPeers[0].ChassisId)/$($vifPeers[0].SlotId)/$($vifPeers[0].PortId)"
				}
				#--- If Network PortId is greater than 1000 then format string as a port channel ---#
				if($vif.PortId -gt 1000)
				{
					$vifHash.Fex_Network_Port = 'PC-' + $vif.PortId
				}
				#--- Else format in fabricId/slot/port notation ---#
				else
				{
					$vifHash.Fex_Network_Port = $vif.PortId
				}
				#--- Server Port for current path as formatted in UCSM ---#
				$vifHash.FI_Server_Port = "$($vif.SwitchId)/$($vif.PeerSlotId)/$($vif.PeerPortId)"
				
				#--- Array variable for storing virtual circuit data ---#
				$vifHash.Circuits = @()
				#--- Iterate through all circuits for the current vif ---#
				$circuits | ? {$_.Dn -cmatch ($vif.Dn | Select-String -pattern ".*(?<=[/])")[0].Matches.Value} | Select Id,vNic,OperBorderPortId,OperBorderSlotId,LinkState,SwitchId | % {
					#--- Hash variable for storing current circuit data ---#
					$vcHash = @{}
					$vcHash.Name = 'Virtual Circuit ' + $_.Id
					$vcHash.vNic = $_.vNic
					$vcHash.Link_State = $_.LinkState
					#--- Check if the current circuit is pinned to a PC uplink ---#
					if($_.OperBorderPortId -gt 0 -and $_.OperBorderSlotId -eq 0)
					{
						$vcHash.FI_Uplink = "$($_.SwitchId)/PC - $($_.OperBorderPortId)"
					}
					#--- Check if the current circuit is unpinned ---#
					elseif($_.OperBorderPortId -eq 0 -and $_.OperBorderSlotId -eq 0)
					{
						$vcHash.FI_Uplink = "unpinned"
					}
					#--- Assume that the circuit is pinned to a single uplink port ---#
					else
					{
						$vcHash.FI_Uplink = "$($_.SwitchId)/$($_.OperBorderSlotId)/$($_.OperBorderPortId)"
					}
					#--- Add current circuit data to loop array variable ---#
					$vifHash.Circuits += $vcHash
				}
				#--- Add vif data to blade hash ---#
				$bladeHash.VIFs += $vifHash
			}
			
			#--- Get the configured boot definition of the current blade ---#
			
			#--- Array variable for storing boot order data ---#
			$bladeHash.Configured_Boot_Order = @()
			#--- Iterate through all boot parameters for current blade ---#
			$blade | Get-UcsBootDefinition | % {
				#--- Store current pipe variable to local variable ---#
				$policy = $_
				#--- Hash variable for storing current boot data ---#
				$bootHash = @{}
				#--- Grab multiple boot policy data points from current policy ---#
				($bootHash.Dn,$bootHash.BootMode,$bootHash.EnforceVnicName,$bootHash.Name,$bootHash.RebootOnUpdate,$bootHash.Owner) = $policy.Dn,$policy.BootMode,$policy.EnforceVnicName,$policy.Name,$policy.RebootOnUpdate,$policy.Owner
			
				#--- Array variable for string boot policy entries ---#
				$bootHash.Entries = @()
				#--- Get all child objects of the current policy and sort by boot order ---#
				$policy | Get-UcsChild | Sort-Object Order | % {
					#--- Store current pipe variable to local variable ---#
					$entry = $_
					#===========================================================#
					#	Switch statement using the device type as the target	#
					#															#
					#	Variable Definitions:									#
					#		Level1 - VNIC, Order								#
					#		Level2 - Type, VNIC Name							#
					#		Level3 - Lun, Type, WWN								#
					#===========================================================#
					Switch ($entry.Type)
					{
						#--- Matches either local media or SAN storage ---#
						'storage' {
							#--- Get child data of boot entry for more detailed information ---#
							$entry | Get-UcsChild | Sort-Object Type | % {
								#--- Hash variable for storing current boot entry data ---#
								$entryHash = @{}
								#--- Checks if current entry is a SAN target ---#
								if($_.Rn -match "san")
								{
									#--- Grab Level1 data ---#
									$entryHash.Level1 = $entry | Select-Object Type,Order
									#--- Array for storing Level2 data ---#
									$entryHash.Level2 = @()
									#--- Hash variable for storing current san entry data ---#
									$sanHash = @{}
									$sanHash.Type = $_.Type
									$sanHash.VnicName = $_.VnicName
									#--- Array variable for storing Level3 data ---#
									$sanHash.Level3 = @()
									#--- Get Level3 data from child object ---#
									$sanHash.Level3 += $_ | Get-UcsChild | Sort-Object Type | Select-Object Lun,Type,Wwn
									#--- Add sanHash to Level2 array variable
									$entryHash.Level2 += $sanHash
									#--- Add current boot entry data to boot hash ---#
									$bootHash.Entries += $entryHash
								}
								#--- Checks if current entry is a local storage target ---#
								elseif($_.Rn -match "local-storage")
								{
									#--- Selects Level1 data ---#
									$_ | Get-UcsChild | Sort-Object Order | % {
										$entryHash = @{}
										$entryHash.Level1 = $_ | Select-Object Type,Order
										$bootHash.Entries += $entryHash
									}
								}									
							}
						}
						#--- Matches virtual media types ---#
						'virtual-media' {
							$entryHash = @{}
							#--- Get Level1 data plus Access type to determine device type ---#
							$entryHash.Level1 = $entry | Select-Object Type,Order,Access
							if ($entryHash.Level1.Access -match 'read-only')
							{
								$entryHash.Level1.Type = 'CD/DVD'
							}
							else
							{
								$entryHash.Level1.Type = 'Floppy'
							}
							$bootHash.Entries += $entryHash
						}
						#--- Matches lan boot types ---#
						'lan' {
							$entryHash = @{}
							$entryHash.Level1 = $entry | Select-Object Type,Order
							$entryHash.Level2 = @()
							$entryHash.Level2 += $entry | Get-UcsChild | Select-Object VnicName,Type 
							$bootHash.Entries += $entryHash
						}
						#--- Matches SAN and iSCSI boot types ---#
						'san' {
							$entryHash = @{}
							#--- Grab Level1 data ---#
							$entryHash.Level1 = $entry | Select-Object Type,Order
							$entryHash.Level2 = @()
							$entry | Get-UcsChild | Sort-Object Type | % {
								#--- Hash variable for storing current san entry data ---#
								$sanHash = @{}
								#--- Grab Level2 Data ---#
								$sanHash.Type = $_.Type
								$sanHash.VnicName = $_.VnicName
								#--- Array variable for storing Level3 data ---#
								$sanHash.Level3 = @()
								#--- Get Level3 data from child object ---#
								$sanHash.Level3 += $_ | Get-UcsChild | Sort-Object Type | Select-Object Lun,Type,Wwn
								#--- Add sanHash to Level2 array variable
								$entryHash.Level2 += $sanHash
							}
							#--- Add current boot entry data to boot hash ---#
							$bootHash.Entries += $entryHash
						}
						'iscsi' {
							#--- Hash variable for storing iscsi boot entry data ---#
							$entryHash = @{}
							#--- Grab Level1 boot data ---#
							$entryHash.Level1 = $entry | Select-Object Type,Order
							#--- Array variable for storing Level2 boot data ---#
							$entryHash.Level2 = @()
							#--- Get all iSCSI Level2 data from child objects ---#
							$entryHash.Level2 += $entry | Get-UcsChild | Sort-Object Type | Select-Object ISCSIVnicName,Type
							#--- Add current boot entry data to boot hash ---#
							$bootHash.Entries += $entryHash
						}
					}
				}
				#--- Sort all boot entries by Level1 Order ---#
				$bootHash.Entries = $bootHash.Entries | Sort-Object {$_.Level1.Order}
				#--- Store boot entries to configured boot order array ---#
				$bladeHash.Configured_Boot_Order += $bootHash
			}
			
			#--- Grab actual boot order data from BIOS boot order table for current blade ---#
			
			#--- Array variable for storing boot entries ---#
			$bladeHash.Actual_Boot_Order = @()
			#--- Iterate through all boot entries ---#
			$blade | Get-UcsBiosUnit | Get-UcsBiosBOT | Get-UcsBiosBootDevGrp | Sort-Object Order | % {
				#--- Store current pipe variable to local variable ---#
				$entry = $_
				#--- Hash variable for storing current entry data ---#
				$bootHash = @{}
				#--- Grab entry device type ---#
				$bootHash.Descr = $entry.Descr
				#--- Grab detailed information about current boot entry ---#
				$bootHash.Entries = @()
				$entry | Get-UcsBiosBootDev | % {
					#--- Formats Entry string like UCSM presentation ---#
					$bootHash.Entries += "($($_.Order)) $($_.Descr)"
				}
				#--- Add boot entry data to actual boot order array ---#
				$bladeHash.Actual_Boot_Order += $bootHash
			}
			#--- Add current blade hash data to DomainHash variable ---#
			$DomainHash.Inventory.Blades += $bladeHash
		}
		#--- End Blade Inventory Collection ---#
		
		#--- Start Rack Inventory Collection ---#
		
		#--- Set current job progress ---#
		$Process_Hash.Progress[$domain] = 48
		
		#--- Array variable for storing rack server data ---#
		$DomainHash.Inventory.Rackmounts = @()
		#--- Array variable for storing rack server adapter data ---#
		$DomainHash.Inventory.Rackmount_Adapters = @()
		
		#--- Iterate through each rackmount server and grab relevant data ---#
		Get-UcsRackUnit -Ucs $handle | % {
			#--- Store current pipe variable and store to local variable ---#
			$rack = $_
			#--- Hash variable for storing current rack server data ---#
			$rackHash = @{}
			$rackHash.Rack_Id = $rack.Id
			$rackHash.Dn = $rack.Dn
			#--- Get Model and Description common names and format the text ---#
			($rackHash.Model,$rackHash.Model_Description) = Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "Sku -ieq $($rack.Model)" | Select Name,Description | % {($_.Name -replace "Cisco UCS ", ""),$_.Description}
			$rackHash.Serial = $rack.Serial
			$rackHash.Service_Profile = $rack.AssignedToDn
			$rackHash.Uuid = $rack.Uuid
			$rackHash.UsrLbl = $rack.UsrLbl
			$rackHash.Name = $rack.Name
			#--- If no service profile exists set profile name to "Unassociated" ---#
			if(!($rackHash.Service_Profile))
			{
				$rackHash.Service_Profile = "Unassociated"
			}
			#--- Get child objects for pulling detailed information
			$childTargets = $rack | Get-UcsChild | where {$_.Rn -ieq "bios" -or $_.Rn -ieq "mgmt" -or $_.Rn -ieq "board"} | get-ucschild
			#--- Get rack CPU data ---#
			$cpu = ($childTargets | where {$_.Rn -match "cpu"} | Select-Object -first 1).Model
			#--- Get CPU common name and format text ---#
			$rackHash.CPU = '(' + $rack.NumOfCpus + ')' + ($cpu.Substring(([regex]::match($cpu,'CPU ').Index) + ([regex]::match($cpu,'CPU ').Length))).Replace(" ","")
			$rackHash.CPU_Cores = $rack.NumOfCores
			$rackHash.CPU_Threads = $rack.NumOfThreads
			#--- Format available memory in GB ---#
			$rackHash.Memory = $rack.AvailableMemory/1024
			$rackHash.Memory_Speed = $rack.MemorySpeed
			$rackHash.BIOS = (($childTargets | where {$_.Type -eq "blade-bios"}).Version -replace ('(?!(.*[.]){2}).*',"")).TrimEnd('.')
			$rackHash.CIMC = ($childTargets | where {$_.Type -eq "blade-controller" -and $_.Deployment -ieq "system"}).Version
			#--- Iterate through each server adapter and grab detailed information ---#
			foreach (${adapter} in ($rack | Get-UcsAdaptorUnit))
			{
				$adapterHash = @{}
				$adapterHash.Rack_Id = $rack.Id
				$adapterHash.Slot = ${adapter}.PciSlot
				#--- Get common name of adapter model and format text ---#
				$adapterHash.Model = (Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "Sku -cmatch $(${adapter}.Model)").Name -replace "Cisco UCS ", ""
				$adapterHash.Serial = ${adapter}.Serial
				$adapterHash.Running_FW = (${adapter} | Get-UcsMgmtController | Get-UcsFirmwareRunning -Deployment system).Version
				#--- Add adapter data to Rackmount_Adapters array variable ---#
				$DomainHash.Inventory.Rackmount_Adapters += $adapterHash
			}
			#--- Array variable for storing rack memory data ---#
			$rackHash.Memory_Array = @()
			#--- Iterage through all memory tied to current server and grab relevant data ---#
			$memoryArray | ? Dn -cmatch $rack.Dn | Select Id,Location,Capacity,Clock | Sort-Object {($_.Id) -as [int]} | % {
				#--- Hash variable for storing current memory data ---#
				$memHash = @{}
				$memHash.Name = "Memory " + $_.Id
				$memHash.Location = $_.Location
				#--- Format DIMM capacity in GB ---#
				$memHash.Capacity = ($_.Capacity)/1024
				$memHash.Clock = $_.Clock
				$rackHash.Memory_Array += $memHash
			}
			
			#--- Array variable for storing local storage configuration data ---#
			$rackHash.Storage = @()
			#--- Iterate through each server storage controller and grab relevant data ---#
			$rack | Get-UcsComputeBoard | Get-UcsStorageController | % {
				#--- Store current pipe variable to local variable ---#
				$controller = $_
				#--- Hash variable for storing current storage controller data ---#
				$controllerHash = @{}
				#--- Grab relevant controller data and store to respective controllerHash variable ---#
				$controllerHash.Id,$controllerHash.Vendor,$controllerHash.Revision,$controllerHash.RaidSupport,$controllerHash.PciAddr,$controllerHash.RebuildRate,$controllerHash.Model,$controllerHash.Serial,$controllerHash.ControllerStatus = $controller.Id,$controller.Vendor,$controller.HwRevision,$controller.RaidSupport,$controller.PciAddr,$controller.XtraProperty.RebuildRate,$controller.Model,$controller.Serial,$controller.XtraProperty.ControllerStatus
				$controllerHash.Disk_Count = 0
				#--- Array variable for storing controller disks ---#
				$controllerHash.Disks = @()
				$controller | Get-UcsStorageLocalDisk -Presence "equipped" | % {
					#--- Store current pipe variable to local variable ---#
					$disk = $_
					#--- Hash variable for storing current disk data ---#
					$diskHash = @{}
					#--- Get common name of disk model and format text ---#
					$equipmentDef = Get-UcsEquipmentManufacturingDef -Ucs $handle -Filter "OemPartNumber -ieq $($disk.Model)"
					#--- Get detailed disk capability data ---#
					$capabilities = Get-UcsEquipmentLocalDiskDef -Ucs $handle -Filter "Dn -cmatch $($disk.Model)"
					$diskHash.Id = $disk.Id
					$diskHash.Pid = $equipmentDef.Pid
					$diskHash.Vendor = $disk.Vendor
					$diskHash.Vid = $equipmentDef.Vid
					$diskHash.Serial = $disk.Serial
					$diskHash.Product_Name = $equipmentDef.Name
					$diskHash.Drive_State = $disk.XtraProperty.DiskState
					$diskHash.Power_State = $disk.XtraProperty.PowerState
					#--- Format disk size to whole GB value ---#
					$diskHash.Size = "{0:N2}" -f ($disk.Size/1024)
					$diskHash.Link_Speed = $disk.XtraProperty.LinkSpeed
					$diskHash.Blocks = $disk.NumberOfBlocks
					$diskHash.Block_Size = $disk.BlockSize
					$diskHash.Technology = $capabilities.Technology
					$diskHash.Avg_Seek_Time = $capabilities.SeekAverageReadWrite
					$diskHash.Track_To_Seek = $capabilities.SeekTrackToTrackReadWrite
					$diskHash.Operability = $disk.Operability
					$diskHash.Presence = $disk.Presence
					$diskHash.Running_Version = ($disk | Get-UcsFirmwareRunning).Version
					$controllerHash.Disk_Count += 1
					#--- Add current disk hash to controller hash disk array ---#
					$controllerHash.Disks += $diskHash
				}
				#--- Add controller hash variable to current rack hash storage array ---#
				$rackHash.Storage += $controllerHash
			}
			#--- Array variable for storing VIF information for current rack ---#
			$rackHash.VIFs = @()
			#--- Grab all circuits that match the current rack DN and are active or link-down ---#
			$circuits = Get-UcsDcxVc -Ucs $handle -Filter "Dn -cmatch $($rack.Dn) -and (OperState -cmatch active -or OperState -cmatch link-down)" | Select Dn,Id,OperBorderPortId,OperBorderSlotId,SwitchId,Vnic,LinkState
			#--- Iterate through all paths of type "mux-fabric" for the current rack ---#
			$paths | ? {$_.Dn -Match $rack.Dn -and $_.CType -match "mux-fabric" -and $_.CType -notmatch "mux-fabric(.*)?[-]"} | % {
				#--- Store current pipe variable to local variable ---#
				$vif = $_
				#--- Hash variable for storing current VIF data ---#
				$vifHash = @{}
				#--- The name of the current Path formatted to match the presentation in UCSM ---#
				$vifHash.Name = "Path " + $_.SwitchId + '/' + ($_.Dn | Select-String -pattern "(?<=path[-]).*(?=[/])")[0].Matches.Value
				#--- Gets peer port information filtered to the current path for adapter and fex host port ---#
				$vifPeers = $paths | ? {$_.EpDn -match ($vif.EpDn | Select-String -pattern ".*(?=(.*[/]){2})").Matches.Value -and $_.Dn -match ($vif.Dn | Select-String -pattern ".*(?=(.*[/]){3})").Matches.Value -and $_.Dn -ne $vif.Dn}									
				
				$vifHash.Adapter_Port = "$($vifPeers[1].PeerSlotId)/$($vifPeers[1].PeerPortId)"
				$vifHash.Fex_Host_Port = "$($vifPeers[1].ChassisId)/$($vifPeers[1].SlotId)/$($vifPeers[1].PortId)"
				$vifHash.Fex_Network_Port = $vifPeers[0].PortId
				$vifHash.FI_Server_Port = "$($vif.SwitchId)/$($vif.PeerSlotId)/$($vif.PeerPortId)"
				
				#--- Array variable for storing virtual circuit data ---#
				$vifHash.Circuits = @()
				#--- Iterate through all circuits for the current vif ---#
				$circuits | ? {$_.Dn -cmatch ($vif.Dn | Select-String -pattern ".*(?<=[/])")[0].Matches.Value} | Select Id,vNic,OperBorderPortId,OperBorderSlotId,LinkState,SwitchId | % {
					#--- Hash variable for storing current circuit data ---#
					$vcHash = @{}
					$vcHash.Name = 'Virtual Circuit ' + $_.Id
					$vcHash.vNic = $_.vNic
					$vcHash.Link_State = $_.LinkState
					#--- Check if the current circuit is pinned to a PC uplink ---#
					if($_.OperBorderPortId -gt 0 -and $_.OperBorderSlotId -eq 0)
					{
						$vcHash.FI_Uplink = "$($_.SwitchId)/PC - $($_.OperBorderPortId)"
					}
					#--- Check if the current circuit is unpinned ---#
					elseif($_.OperBorderPortId -eq 0 -and $_.OperBorderSlotId -eq 0)
					{
						$vcHash.FI_Uplink = "unpinned"
					}
					#--- Assume that the circuit is pinned to a single uplink port ---#
					else
					{
						$vcHash.FI_Uplink = "$($_.SwitchId)/$($_.OperBorderSlotId)/$($_.OperBorderPortId)"
					}
					$vifHash.Circuits += $vcHash
				}
				$rackHash.VIFs += $vifHash
			}
			#--- Get the configured boot definition of the current rack ---#
			
			#--- Array variable for storing boot order data ---#
			$rackHash.Configured_Boot_Order = @()
			#--- Iterate through all boot parameters for current rack ---#
			$rack | Get-UcsBootDefinition | % {
				#--- Store current pipe variable to local variable ---#
				$policy = $_
				#--- Hash variable for storing current boot data ---#
				$bootHash = @{}
				#--- Grab multiple boot policy data points from current policy ---#
				($bootHash.Dn,$bootHash.BootMode,$bootHash.EnforceVnicName,$bootHash.Name,$bootHash.RebootOnUpdate,$bootHash.Owner) = $policy.Dn,$policy.BootMode,$policy.EnforceVnicName,$policy.Name,$policy.RebootOnUpdate,$policy.Owner
			
				#--- Array variable for string boot policy entries ---#
				$bootHash.Entries = @()
				#--- Get all child objects of the current policy and sort by boot order ---#
				$policy | Get-UcsChild | Sort-Object Order | % {
					#--- Store current pipe variable to local variable ---#
					$entry = $_
					#===========================================================#
					#	Switch statement using the device type as the target	#
					#															#
					#	Variable Definitions:									#
					#		Level1 - VNIC, Order								#
					#		Level2 - Type, VNIC Name							#
					#		Level3 - Lun, Type, WWN								#
					#===========================================================#
					Switch ($entry.Type)
					{
						#--- Matches either local media or SAN storage ---#
						'storage' {
							#--- Get child data of boot entry for more detailed information ---#
							$entry | Get-UcsChild | Sort-Object Type | % {
								#--- Hash variable for storing current boot entry data ---#
								$entryHash = @{}
								#--- Checks if current entry is a SAN target ---#
								if($_.Rn -match "san")
								{
									#--- Grab Level1 data ---#
									$entryHash.Level1 = $entry | Select-Object Type,Order
									#--- Array for storing Level2 data ---#
									$entryHash.Level2 = @()
									#--- Hash variable for storing current san entry data ---#
									$sanHash = @{}
									$sanHash.Type = $_.Type
									$sanHash.VnicName = $_.VnicName
									#--- Array variable for storing Level3 data ---#
									$sanHash.Level3 = @()
									#--- Get Level3 data from child object ---#
									$sanHash.Level3 += $_ | Get-UcsChild | Sort-Object Type | Select-Object Lun,Type,Wwn
									#--- Add sanHash to Level2 array variable
									$entryHash.Level2 += $sanHash
									#--- Add current boot entry data to boot hash ---#
									$bootHash.Entries += $entryHash
								}
								#--- Checks if current entry is a local storage target ---#
								elseif($_.Rn -match "local-storage")
								{
									#--- Selects Level1 data ---#
									$_ | Get-UcsChild | Sort-Object Order | % {
										$entryHash = @{}
										$entryHash.Level1 = $_ | Select-Object Type,Order
										$bootHash.Entries += $entryHash
									}
								}									
							}
						}
						#--- Matches virtual media types ---#
						'virtual-media' {
							$entryHash = @{}
							#--- Get Level1 data plus Access type to determine device type ---#
							$entryHash.Level1 = $entry | Select-Object Type,Order,Access
							if ($entryHash.Level1.Access -match 'read-only')
							{
								$entryHash.Level1.Type = 'CD/DVD'
							}
							else
							{
								$entryHash.Level1.Type = 'floppy'
							}
							$bootHash.Entries += $entryHash
						}
						#--- Matches lan boot types ---#
						'lan' {
							$entryHash = @{}
							$entryHash.Level1 = $entry | Select-Object Type,Order
							$entryHash.Level2 = @()
							$entryHash.Level2 += $entry | Get-UcsChild | Select-Object VnicName,Type 
							$bootHash.Entries += $entryHash
						}
						#--- Matches SAN and iSCSI boot types ---#
						'san' {
							$entryHash = @{}
							#--- Grab Level1 data ---#
							$entryHash.Level1 = $entry | Select-Object Type,Order
							$entryHash.Level2 = @()
							$entry | Get-UcsChild | Sort-Object Type | % {
								#--- Hash variable for storing current san entry data ---#
								$sanHash = @{}
								#--- Grab Level2 Data ---#
								$sanHash.Type = $_.Type
								$sanHash.VnicName = $_.VnicName
								#--- Array variable for storing Level3 data ---#
								$sanHash.Level3 = @()
								#--- Get Level3 data from child object ---#
								$sanHash.Level3 += $_ | Get-UcsChild | Sort-Object Type | Select-Object Lun,Type,Wwn
								#--- Add sanHash to Level2 array variable
								$entryHash.Level2 += $sanHash
							}
							#--- Add current boot entry data to boot hash ---#
							$bootHash.Entries += $entryHash
						}
						'iscsi' {
							#--- Hash variable for storing iscsi boot entry data ---#
							$entryHash = @{}
							#--- Grab Level1 boot data ---#
							$entryHash.Level1 = $entry | Select-Object Type,Order
							#--- Array variable for storing Level2 boot data ---#
							$entryHash.Level2 = @()
							#--- Get all iSCSI Level2 data from child objects ---#
							$entryHash.Level2 += $entry | Get-UcsChild | Sort-Object Type | Select-Object ISCSIVnicName,Type
							#--- Add current boot entry data to boot hash ---#
							$bootHash.Entries += $entryHash
						}
					}
				}
				#--- Sort all boot entries by Level1 Order ---#
				$bootHash.Entries = $bootHash.Entries | Sort-Object {$_.Level1.Order}
				#--- Store boot entries to configured boot order array ---#
				$rackHash.Configured_Boot_Order += $bootHash
			}
			
			#--- Grab actual boot order data from BIOS boot order table for current rack ---#
			
			#--- Array variable for storing boot entries ---#
			$rackHash.Actual_Boot_Order = @()
			#--- Iterate through all boot entries ---#
			$rack | Get-UcsBiosUnit | Get-UcsBiosBOT | Get-UcsBiosBootDevGrp | Sort-Object Order | % {
				#--- Store current pipe variable to local variable ---#
				$entry = $_
				#--- Hash variable for storing current entry data ---#
				$bootHash = @{}
				#--- Grab entry device type ---#
				$bootHash.Descr = $entry.Descr
				#--- Grab detailed information about current boot entry ---#
				$bootHash.Entries = @()
				$entry | Get-UcsBiosBootDev | % {
					#--- Formats Entry string like UCSM presentation ---#
					$bootHash.Entries += "($($_.Order)) $($_.Descr)"
				}
				#--- Add boot entry data to actual boot order array ---#
				$rackHash.Actual_Boot_Order += $bootHash
			}
			#--- Add racmount server hash to Inventory array ---#
			$DomainHash.Inventory.Rackmounts += $rackHash
		}
		#--- End Rack Inventory Collection ---#
		
		
		#--- Start Policy Data Collection ---#
		
		#--- Update job progress percent ---#
		$Process_Hash.Progress[$domain] = 60
		#--- Hash variable for storing system policies ---#
		$DomainHash.Policies.SystemPolicies = @{}
		#--- Grab DNS and NTP data ---#
		$DomainHash.Policies.SystemPolicies.DNS = @()
		$DomainHash.Policies.SystemPolicies.DNS += (Get-UcsDnsServer -Ucs $handle).Name
		$DomainHash.Policies.SystemPolicies.NTP = @()
		$DomainHash.Policies.SystemPolicies.NTP += (Get-UcsNtpServer -Ucs $handle).Name
		#--- Get chassis discovery data for future use ---#
		$Chassis_Discovery = Get-UcsChassisDiscoveryPolicy -Ucs $handle | Select Action,LinkAggregationPref
		$DomainHash.Policies.SystemPolicies.Action = $Chassis_Discovery.Action
		$DomainHash.Policies.SystemPolicies.Grouping = $Chassis_Discovery.LinkAggregationPref
		$DomainHash.Policies.SystemPolicies.Power = (Get-UcsPowerControlPolicy -Ucs $handle | Select Redundancy).Redundancy
		$DomainHash.Policies.SystemPolicies.Maint = (Get-UcsMaintenancePolicy -Name "default" -Ucs $handle | Select UptimeDisr).UptimeDisr
		$DomainHash.Policies.SystemPolicies.Timezone = (Get-UcsTimezone).Timezone -replace '([(].*[)])', ""
		
		#--- Maintenance Policies ---#
		$DomainHash.Policies.Maintenance = @()
		$DomainHash.Policies.Maintenance += Get-UcsMaintenancePolicy -Ucs $handle | Select-Object Name,Dn,UptimeDisr,Descr,SchedName
		
		#--- Host Firmware Packages ---#
		$DomainHash.Policies.FW_Packages = @()
		$DomainHash.Policies.FW_Packages += Get-UcsFirmwareComputeHostPack -Ucs $handle | Select Name,BladeBundleVersion,RackBundleVersion
		
		#--- LDAP Policy Data ---#
		$DomainHash.Policies.LDAP_Providers = @()
		$DomainHash.Policies.LDAP_Providers += Get-UcsLdapProvider -Ucs $handle | Select-Object Name,Rootdn,Basedn,Attribute
		$mappingArray = @()
		$DomainHash.Policies.LDAP_Mappings = @()
		$mappingArray += Get-UcsLdapGroupMap -Ucs $handle
		$mappingArray | % {
			$mapHash = @{}
			$mapHash.Name = $_.Name
			$mapHash.Roles = ($_ | Get-UcsUserRole).Name
			$mapHash.Locales = ($_ | Get-UcsUserLocale).Name
			$DomainHash.Policies.LDAP_Mappings += $mapHash
		}
		
		#--- Boot Order Policies ---#
		$DomainHash.Policies.Boot_Policies = @()
		Get-UcsBootPolicy | % {
			#--- Store current pipe variable to local variable ---#
			$policy = $_
			#--- Hash variable for storing current boot data ---#
			$bootHash = @{}
			#--- Grab multiple boot policy data points from current policy ---#
			($bootHash.Dn,$bootHash.Description,$bootHash.BootMode,$bootHash.EnforceVnicName,$bootHash.Name,$bootHash.RebootOnUpdate,$bootHash.Owner) = $policy.Dn,$policy.Descr,$policy.BootMode,$policy.EnforceVnicName,$policy.Name,$policy.RebootOnUpdate,$policy.Owner
			#--- Array variable for string boot policy entries ---#
			$bootHash.Entries = @()
			#--- Get all child objects of the current policy and sort by boot order ---#
			$policy | Get-UcsChild | Sort-Object Order | % {
				#--- Store current pipe variable to local variable ---#
				$entry = $_
				#===========================================================#
				#	Switch statement using the device type as the target	#
				#															#
				#	Variable Definitions:									#
				#		Level1 - VNIC, Order								#
				#		Level2 - Type, VNIC Name							#
				#		Level3 - Lun, Type, WWN								#
				#===========================================================#
				Switch ($entry.Type)
				{
					#--- Matches either local media or SAN storage ---#
					'storage' {
						#--- Get child data of boot entry for more detailed information ---#
						$entry | Get-UcsChild | Sort-Object Type | % {
							#--- Hash variable for storing current boot entry data ---#
							$entryHash = @{}
							#--- Checks if current entry is a SAN target ---#
							<#if($_.Rn -match "san")
							{
								#--- Grab Level1 data ---#
								$entryHash.Level1 = $entry | Select-Object Type,Order
								#--- Array for storing Level2 data ---#
								$entryHash.Level2 = @()
								#--- Hash variable for storing current san entry data ---#
								$sanHash = @{}
								$sanHash.Type = $_.Type
								$sanHash.VnicName = $_.VnicName
								#--- Array variable for storing Level3 data ---#
								$sanHash.Level3 = @()
								#--- Get Level3 data from child object ---#
								$sanHash.Level3 += $_ | Get-UcsChild | Sort-Object Type | Select-Object Lun,Type,Wwn
								#--- Add sanHash to Level2 array variable
								$entryHash.Level2 += $sanHash
								#--- Add current boot entry data to boot hash ---#
								$bootHash.Entries += $entryHash
							}
							#>
							#--- Checks if current entry is a local storage target ---#
							if($_.Rn -match "local-storage")
							{
								#--- Selects Level1 data ---#
								$_ | Get-UcsChild | Sort-Object Order | % {
									$entryHash = @{}
									$entryHash.Level1 = $_ | Select-Object Type,Order
									$bootHash.Entries += $entryHash
								}
							}									
						}
					}
					#--- Matches virtual media types ---#
					'virtual-media' {
						$entryHash = @{}
						$entryHash.Level1 = $entry | Select-Object Type,Order,Access
						if ($entryHash.Level1.Access -match 'read-only')
						{
							$entryHash.Level1.Type = 'CD/DVD'
						}
						else
						{
							$entryHash.Level1.Type = 'floppy'
						}
						$bootHash.Entries += $entryHash
					}
					#--- Matches lan boot types ---#
					'lan' {
						$entryHash = @{}
						$entryHash.Level1 = $entry | Select-Object Type,Order
						$entryHash.Level2 = @()
						$entryHash.Level2 += $entry | Get-UcsChild | Select-Object VnicName,Type 
						$bootHash.Entries += $entryHash
					}
					#--- Matches SAN boot types ---#
					'san' {
						$entryHash = @{}
						#--- Grab Level 1 Data ---#
						$entryHash.Level1 = $entry | Select-Object Type,Order
						#--- Array variable for Level 2 data ---#
						$entryHash.Level2 = @()
						#--- Iterate through each child object for Level 2 and 3 details ---#
						$entry | Get-UcsChild | Sort-Object Type | % {
							$sanHash = @{}
							$sanHash.Type = $_.Type
							$sanHash.VnicName = $_.VnicName
							$sanHash.Level3 = @()
							$sanHash.Level3 += $_ | Get-UcsChild | Sort-Object Type | Select-Object Lun,Type,Wwn
							$entryHash.Level2 += $sanHash
						}
						#--- Add current boot entry data to boot hash ---#
						$bootHash.Entries += $entryHash
					}
					#--- Matches ISCSI boot types ---#
					'iscsi' {
						#--- Hash variable for storing iscsi boot entry data ---#
						$entryHash = @{}
						#--- Grab Level1 boot data ---#
						$entryHash.Level1 = $entry | Select-Object Type,Order
						#--- Array variable for storing Level2 boot data ---#
						$entryHash.Level2 = @()
						#--- Get all iSCSI Level2 data from child objects ---#
						$entryHash.Level2 += $entry | Get-UcsChild | Sort-Object Type | Select-Object ISCSIVnicName,Type
						#--- Add current boot entry data to boot hash ---#
						$bootHash.Entries += $entryHash
					}
				}
			}
			#--- Sort all boot entries by Level1 Order ---#
			$bootHash.Entries = $bootHash.Entries | Sort-Object {$_.Level1.Order}
			#--- Store boot entries to system boot policies array ---#
			$DomainHash.Policies.Boot_Policies+= $bootHash
		}
			
		#--- End System Policies Collection ---#
		
		#--- Start ID Pool Collection ---#
		#--- External Mgmt IP Pool ---#
		$DomainHash.Policies.Mgmt_IP_Pool = @{}
		#--- Get the default external management pool ---#
		$mgmtPool = Get-ucsippoolblock -Ucs $handle -Filter "Dn -cmatch ext-mgmt"
		$DomainHash.Policies.Mgmt_IP_Pool.From = $mgmtPool.From
		$DomainHash.Policies.Mgmt_IP_Pool.To = $mgmtPool.To
		$parentPool = $mgmtPool | get-UcsParent
		$DomainHash.Policies.Mgmt_IP_Pool.Size = $parentPool.Size
		$DomainHash.Policies.Mgmt_IP_Pool.Assigned = $parentPool.Assigned
		
		#--- Mgmt IP Allocation ---#
		$DomainHash.Policies.Mgmt_IP_Allocation = @()
		$parentPool | Get-UcsIpPoolPooled -Filter "Assigned -ieq yes" | Select AssignedToDn,Id,Subnet,DefGw | % {
			$allocationHash = @{}
			$allocationHash.Dn = $_.AssignedToDn -replace "/mgmt/*.*", ""
			$allocationHash.IP = $_.Id
			$allocationHash.Subnet = $_.Subnet
			$allocationHash.GW = $_.DefGw
			$DomainHash.Policies.Mgmt_IP_Allocation += $allocationHash
		}
		#--- UUID ---#
		$DomainHash.Policies.UUID_Pools = @()
		$DomainHash.Policies.UUID_Pools += Get-UcsUuidSuffixPool -Ucs $handle | Select-Object Dn,Name,AssignmentOrder,Prefix,Size,Assigned
		$DomainHash.Policies.UUID_Assignments = @()
		$DomainHash.Policies.UUID_Assignments += Get-UcsUuidpoolAddr -Ucs $handle -Assigned yes | select-object AssignedToDn,Id | sort-object -property AssignedToDn
		
		#--- Server Pools ---#
		$DomainHash.Policies.Server_Pools = @()
		$DomainHash.Policies.Server_Pools += Get-UcsServerPool -Ucs $handle | Select-Object Dn,Name,Size,Assigned
		$DomainHash.Policies.Server_Pool_Assignments = @()
		$DomainHash.Policies.Server_Pool_Assignments += Get-UcsServerPoolAssignment -Ucs $handle | Select-Object Name,AssignedToDn
		
		#--- End ID Pools Collection ---#
		
		#--- Start Service Profile data collection ---#
		#--- Get Service Profiles by Template ---#
		
		#--- Update current job progress ---#
		$Process_Hash.Progress[$domain] = 72
		#--- Grab all Service Profiles ---#
		$profiles = Get-ucsServiceProfile -Ucs $handle
		#--- Grab all performance statistics for future use ---#
		$statistics = Get-UcsStatistics -Ucs $handle
		
		#--- Array variable for storing template data ---#
		$templates = @()
		#--- Grab all service profile templates ---#
		$templates += ($profiles | ? {$_.Type -match "updating[-]template|initial[-]template"} | Select Name).Name
		#--- Add an empty template entry for profiles not bound to a template ---#
		$templates += ""
		#--- Iterate through templates and grab configuration data ---#
		$templates | % {
			#--- Grab the current template name ---#
			$templateName = $_
			#--- Unchanged copy of the current template name used later in the script ---#
			$profileCheck = $_
			#--- Find the profile template that matches the current name ---#
			$template = $profiles | ? {$_.Name -eq "$templateName"}
			#--- If template name is empty then set template name to "Unbound" ---#
			if ($templateName -eq "")
			{
				$templateName = "Unbound"
			}
			#--- Hash variable to store data for current templateName ---#
			$DomainHash.Profiles[$templateName] = @{}
			#--- Switch statement to format the template type ---#
			switch (($profiles | ? {$_.Name -ieq "$templateName"}).Type)
			{
					"updating-template"	{$DomainHash.Profiles[$templateName].Type = "Updating"}
					"initial-template"	{$DomainHash.Profiles[$templateName].Type = "Initial"}
					default {$DomainHash.Profiles[$templateName].Type = "N/A"}
			}
			#--- Template Details - General Tab ---#
			
			#--- Hash variable for storing general template data ---#
			$DomainHash.Profiles[$templateName].General = @{}
			$DomainHash.Profiles[$templateName].General.Name = $templateName
			$DomainHash.Profiles[$templateName].General.Type = $DomainHash.Profiles[$templateName].Type
			$DomainHash.Profiles[$templateName].General.Description = $template.Descr
			$DomainHash.Profiles[$templateName].General.UUIDPool = $template.IdentPoolName
			$DomainHash.Profiles[$templateName].General.Boot_Policy = $template.OperBootPolicyName
			$DomainHash.Profiles[$templateName].General.PowerState = ($template | Get-UcsServerPower).State
			$DomainHash.Profiles[$templateName].General.MgmtAccessPolicy = $template.ExtIPState
			$DomainHash.Profiles[$templateName].General.Server_Pool = $template | Get-UcsServerPoolAssignment | Select Name,Qualifier,RestrictMigration
			$DomainHash.Profiles[$templateName].General.Maintenance_Policy = Get-UcsMaintenancePolicy -Ucs $handle -Filter "Dn -ieq $($template.OperMaintPolicyName)" | Select Name,Dn,Descr,UptimeDisr
			
			#--- Template Details - Storage Tab ---#
			
			#--- Hash variable for storing storage template data ---#
			$DomainHash.Profiles[$templateName].Storage = @{}
			
			#--- Node WWN Configuration ---#
			$fcNode = $template | Get-UcsVnicFcNode
			#--- Grab VNIC connectivity  ---#
			$vnicConn = $template | Get-UcsVnicConnDef
			$DomainHash.Profiles[$templateName].Storage.Nwwn = $fcNode.Addr
			$DomainHash.Profiles[$templateName].Storage.Nwwn_Pool = $fcNode.IdentPoolName
			$DomainHash.Profiles[$templateName].Storage.Local_Disk_Config = Get-UcsLocalDiskConfigPolicy -Dn $template.OperLocalDiskPolicyName | Select Mode,ProtectConfig,XtraProperty
			$DomainHash.Profiles[$templateName].Storage.Connectivity_Policy = $vnicConn.SanConnPolicyName
			$DomainHash.Profiles[$templateName].Storage.Connectivity_Instance = $vnicConn.OperSanConnPolicyName
			#--- Array variable for storing HBA data ---#
			$DomainHash.Profiles[$templateName].Storage.Hbas = @()
			$template | Get-UcsVhba | % {
				$hbaHash = @{}
				$hbaHash.Name = $_.Name
				$hbaHash.Pwwn = $_.IdentPoolName
				$hbaHash.FabricId = $_.SwitchId
				$hbaHash.Desired_Order = $_.Order
				$hbaHash.Actual_Order = $_.OperOrder
				$hbaHash.Desired_Placement = $_.AdminVcon
				$hbaHash.Actual_Placement = $_.OperVcon
				$hbaHash.Vsan = ($_ | Get-UcsChild | Select Name).Name
				$DomainHash.Profiles[$templateName].Storage.Hbas += $hbaHash
			}
			
			#--- Template Details - Network Tab ---#
			
			#--- Hash variable for storing template network configuration ---#
			$DomainHash.Profiles[$templateName].Network = @{}
			#--- Lan Connectivity Policy ---#
			$DomainHash.Profiles[$templateName].Network.Connectivity_Policy = $vnicConn.LanConnPolicyName
			$DomainHash.Profiles[$templateName].Network.DynamicVnic_Policy = $template.DynamicConPolicyName
			#--- Array variable for storing ---#
			$DomainHash.Profiles[$templateName].Network.Nics = @()
			#--- Iterate through each NIC and grab configuration details ---#
			$template | Get-UcsVnic | % {
				$nicHash = @{}
				$nicHash.Name = $_.Name
				$nicHash.Mac_Address = $_.Addr
				$nicHash.Desired_Order = $_.Order
				$nicHash.Actual_Order = $_.OperOrder
				$nicHash.Fabric_Id = $_.SwitchId
				$nicHash.Desired_Placement = $_.AdminVcon
				$nicHash.Actual_Placement = $_.OperVcon
				$nicHash.Adaptor_Profile = $_.AdaptorProfileName
				$nicHash.Control_Policy = $_.NwCtrlPolicyName
				#--- Array for storing VLANs ---#
				$nicHash.Vlans = @()
				#--- Grab all VLANs ---#
				$nicHash.Vlans += $_ | Get-UcsChild -ClassId VnicEtherIf | Select OperVnetName,Vnet,DefaultNet | Sort-Object {($_.Vnet) -as [int]}
				$DomainHash.Profiles[$templateName].Network.Nics += $nicHash
			}
	
			#--- Template Details - iSCSI vNICs Tab ---#
			
			#--- Array variable for storing iSCSI configuration ---#
			$DomainHash.Profiles[$templateName].iSCSI = @()
			#--- Iterate through iSCSI interface configuration ---#
			$template | Get-UcsVnicIscsi | % {
				$iscsiHash = @{}
				$iscsiHash.Name = $_.Name
				$iscsiHash.Overlay = $_.VnicName
				$iscsiHash.Iqn = $_.InitiatorName
				$iscsiHash.Adapter_Policy = $_.AdaptorProfileName
				$iscsiHash.Mac = $_.Addr
				$iscsiHash.Vlan = ($_ | Get-UcsVnicVlan).VlanName
				$DomainHash.Profiles[$templateName].iSCSI += $iscsiHash
			}
	
			#--- Template Details - Policies Tab ---#
			
			#--- Hash variable for storing template Policy configuration data ---#
			$DomainHash.Profiles[$templateName].Policies = @{}
			$DomainHash.Profiles[$templateName].Policies.Bios = $template.BiosProfileName
			$DomainHash.Profiles[$templateName].Policies.Fw = $template.HostFwPolicyName
			$DomainHash.Profiles[$templateName].Policies.Ipmi = $template.MgmtAccessPolicyName
			$DomainHash.Profiles[$templateName].Policies.Power = $template.PowerPolicyName
			$DomainHash.Profiles[$templateName].Policies.Scrub = $template.ScrubPolicyName
			$DomainHash.Profiles[$templateName].Policies.Sol = $template.SolPolicyName
			$DomainHash.Profiles[$templateName].Policies.Stats = $template.StatsPolicyName
	
			#--- Service Profile Instances ---#
			
			#--- Array variable for storing profiles tied to current template name ---#
			$DomainHash.Profiles[$templateName].Profiles = @()
			#--- Iterate through all profiles tied to the current template name ---#
			$profiles | ? {$_.SrcTemplName -ieq "$profileCheck" -and $_.Type -ieq "instance"} | % {
				#--- Store current pipe variable to local variable ---#
				$sp = $_
				#--- Hash variable for storing current profile configuration data ---#
				$profileHash = @{}
				$profileHash.Dn = $sp.Dn
				$profileHash.Service_Profile = $sp.Name
				$profileHash.UsrLbl = $sp.UsrLbl
				$profileHash.Assigned_Server = $sp.PnDn
				$profileHash.Assoc_State = $sp.AssocState
				$profileHash.Maint_Policy = $sp.MaintPolicyName
				$profileHash.Maint_PolicyInstance = $sp.OperMaintPolicyName
				$profileHash.FW_Policy = $sp.HostFwPolicyName
				$profileHash.BIOS_Policy = $sp.BiosProfileName
				$profileHash.Boot_Policy = $sp.OperBootPolicyName
				
				#--- Service Profile Details - General Tab ---#
				
				#--- Hash variable for storing general profile configuration data ---#
				$profileHash.General = @{}
				$profileHash.General.Name = $sp.Name
				$profileHash.General.Overall_Status = $sp.operState
				$profileHash.General.AssignState = $sp.AssignState
				$profileHash.General.AssocState = $sp.AssocState
				$profileHash.General.Power_State = ($sp | Get-UcsChild -ClassId LsPower | Select State).State
				
				$profileHash.General.UserLabel = $sp.UsrLbl
				$profileHash.General.Descr = $sp.Descr
				$profileHash.General.Owner = $sp.PolicyOwner
				$profileHash.General.Uuid = $sp.Uuid
				$profileHash.General.UuidPool = $sp.OperIdentPoolName
				$profileHash.General.Associated_Server = $sp.PnDn
				$profileHash.General.Template_Name = $templateName
				$profileHash.General.Template_Instance = $sp.OperSrcTemplName
				$profileHash.General.Assignment = @{}
				$pool = $sp | Get-UcsServerPoolAssignment
				if($pool.Count -gt 0)
				{
					$profileHash.General.Assignment.Server_Pool = $pool.Name
					$profileHash.General.Assignment.Qualifier = $pool.Qualifier
					$profileHash.General.Assignment.Restrict_Migration = $pool.RestrictMigration
				}
				else
				{
					$lsServer = $sp | Get-UcsLsBinding
					$profileHash.General.Assignment.Server = $lsServer.AssignedToDn
					$profileHash.General.Assignment.Restrict_Migration = $lsServer.RestrictMigration
				}
				
				#--- Service Profile Details - Storage Tab ---#
				$profileHash.Storage = @{}
				$fcNode = $sp | Get-UcsVnicFcNode
				$vnicConn = $sp | Get-UcsVnicConnDef
				$profileHash.Storage.Nwwn = $fcNode.Addr
				$profileHash.Storage.Nwwn_Pool = $fcNode.IdentPoolName
				$profileHash.Storage.Local_Disk_Config = Get-UcsLocalDiskConfigPolicy -Dn $sp.OperLocalDiskPolicyName | Select Mode,ProtectConfig,XtraProperty
				$profileHash.Storage.Connectivity_Policy = $vnicConn.SanConnPolicyName
				$profileHash.Storage.Connectivity_Instance = $vnicConn.OperSanConnPolicyName
				#--- Array variable for storing HBA configuration data ---#
				$profileHash.Storage.Hbas = @()
				#--- Iterate through each HBA interface
				$sp | Get-UcsVhba | Sort-Object OperVcon,OperOrder | % {
					$hbaHash = @{}
					$hbaHash.Name = $_.Name
					$hbaHash.Pwwn = $_.Addr
					$hbaHash.FabricId = $_.SwitchId
					$hbaHash.Desired_Order = $_.Order
					$hbaHash.Actual_Order = $_.OperOrder
					$hbaHash.Desired_Placement = $_.AdminVcon
					$hbaHash.Actual_Placement = $_.OperVcon
					$hbaHash.EquipmentDn = $_.EquipmentDn
					$hbaHash.Vsan = ($_ | Get-UcsChild | Select OperVnetName).OperVnetName
					$profileHash.Storage.Hbas += $hbaHash
				}
				
				#--- Service Profile Details - Network Tab ---#
				$profileHash.Network = @{}
				$profileHash.Network.Connectivity_Policy = $vnicConn.LanConnPolicyName
				#--- Array variable for storing NIC configuration data ---#
				$profileHash.Network.Nics = @()
				#--- Iterate through each vNIC and grab configuration data ---#
				$sp | Get-UcsVnic | % {
					$nicHash = @{}
					$nicHash.Name = $_.Name
					$nicHash.Mac_Address = $_.Addr
					$nicHash.Desired_Order = $_.Order
					$nicHash.Actual_Order = $_.OperOrder
					$nicHash.Fabric_Id = $_.SwitchId
					$nicHash.Desired_Placement = $_.AdminVcon
					$nicHash.Actual_Placement = $_.OperVcon
					$nicHash.Mtu = $_.Mtu
					$nicHash.EquipmentDn = $_.EquipmentDn
					$nicHash.Adaptor_Profile = $_.AdaptorProfileName
					$nicHash.Control_Policy = $_.NwCtrlPolicyName
					$nicHash.Qos = $_.OperQosPolicyName
					$nicHash.Vlans = @()
					$nicHash.Vlans += $_ | Get-UcsChild -ClassId VnicEtherIf | Select OperVnetName,Vnet,DefaultNet | Sort-Object {($_.Vnet) -as [int]}
					$profileHash.Network.Nics += $nicHash
				}
				
				#--- Service Profile Details - iSCSI vNICs ---#
				$profileHash.iSCSI = @()
				#--- Iterate through all iSCSI interfaces and grab configuration data ---#
				$sp | Get-UcsVnicIscsi | % {
					$iscsiHash = @{}
					$iscsiHash.Name = $_.Name
					$iscsiHash.Overlay = $_.VnicName
					$iscsiHash.Iqn = $_.InitiatorName
					$iscsiHash.Adapter_Policy = $_.AdaptorProfileName
					$iscsiHash.Mac = $_.Addr
					$iscsiHash.Vlan = ($_ | Get-UcsVnicVlan).VlanName
					$profileHash.iSCSI += $iscsiHash
				}
				
				#--- Service Profile Details - Performance ---#
				$profileHash.Performance = @{}
				#--- Only grab performance data if the profile is associated ---#
				if($profileHash.Assoc_State -eq 'associated')
				{
					#--- Get the collection time interval for adapter performance ---#
					$interval = (Get-UcsCollectionPolicy -Name "adapter" | Select CollectionInterval).CollectionInterval
					#--- Normalize collection interval to seconds ---#
					Switch -wildcard (($interval -split '[0-9]')[-1])
					{
						"minute*" { $profileHash.Performance.Interval = ((($interval -split '[a-z]')[0]) -as [int]) * 60 }
						"second*" { $profileHash.Performance.Interval = ((($interval -split '[a-z]')[0]) -as [int]) }
					}
					$profileHash.Performance.vNics = @{}
					$profileHash.Performance.vHbas = @{}
					#--- Iterate through each vHBA and grab performance data ---#
					$profileHash.Storage.Hbas | % {
						$hba = $_
						$profileHash.Performance.vHbas[$hba.Name] = $statistics | ? {$_.Dn -cmatch $hba.EquipmentDn -and $_.Rn -ieq "vnic-stats"} | Select-Object BytesRx,BytesRxDeltaAvg,BytesTx,BytesTxDeltaAvg,PacketsRx,PacketsRxDeltaAvg,PacketsTx,PacketsTxDeltaAvg
					}
					#--- Iterate through each vNIC and grab performance data ---#
					$profileHash.Network.Nics | % {
						$nic = $_
						$profileHash.Performance.vNics[$nic.Name] = $statistics | ? {$_.Dn -cmatch $nic.EquipmentDn -and $_.Rn -ieq "vnic-stats"} | Select-Object BytesRx,BytesRxDeltaAvg,BytesTx,BytesTxDeltaAvg,PacketsRx,PacketsRxDeltaAvg,PacketsTx,PacketsTxDeltaAvg
					}
				}
				
				#--- Service Profile Policies ---#
				$profileHash.Policies = @{}
				$profileHash.Policies.Bios = $sp.BiosProfileName
				$profileHash.Policies.Fw = $sp.HostFwPolicyName
				$profileHash.Policies.Ipmi = $sp.MgmtAccessPolicyName
				$profileHash.Policies.Power = $sp.PowerPolicyName
				$profileHash.Policies.Scrub = $sp.ScrubPolicyName
				$profileHash.Policies.Sol = $sp.SolPolicyName
				$profileHash.Policies.Stats = $sp.StatsPolicyName
				
				#--- Add current profile to template profile array ---#
				$DomainHash.Profiles[$templateName].Profiles += $profileHash
			}
			
		}
		#--- End Service Profile Collection ---#
		
		#--- Start LAN Configuration ---#
		#--- Get the collection time interval for port performance ---#
		$DomainHash.Collection = @{}
		$interval = (Get-UcsCollectionPolicy -Name "port" | Select CollectionInterval).CollectionInterval
		#--- Normalize collection interval to seconds ---#
		Switch -wildcard (($interval -split '[0-9]')[-1])
		{
			"minute*" { $DomainHash.Collection.Port = ((($interval -split '[a-z]')[0]) -as [int]) * 60 }
			"second*" { $DomainHash.Collection.Port = ((($interval -split '[a-z]')[0]) -as [int]) }
		}
		#--- Uplink and Server Ports with Performance ---#
		$DomainHash.Lan.UplinkPorts = @()
		$DomainHash.Lan.ServerPorts = @()
		#--- Iterate through each FI and collect port performance data based on port role ---#
		$DomainHash.Inventory.FIs | % {
			#--- Uplink Ports ---#
			$_.Ports | ? IfRole -eq network | % {
				$port = $_
				$uplinkHash = @{}
				$uplinkHash.Dn = $_.Dn
				$uplinkHash.PortId = $_.PortId
				$uplinkHash.SlotId = $_.SlotId
				$uplinkHash.Fabric_Id = $_.SwitchId
				$uplinkHash.Mac = $_.Mac
				$uplinkHash.Speed = $_.OperSpeed
				$uplinkHash.IfType = $_.IfType
				$uplinkHash.XcvrType = $_.XcvrType
				$uplinkHash.Performance = @{}
				$uplinkHash.Performance.Rx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "rx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$uplinkHash.Performance.Tx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "tx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$uplinkHash.Status = $_.OperState
				$uplinkHash.State = $_.AdminState
				$DomainHash.Lan.UplinkPorts += $uplinkHash
			}
			#--- Server Ports ---#
			$_.Ports | ? IfRole -eq server | % {
				$port = $_
				$serverPortHash = @{}
				$serverPortHash.Dn = $_.Dn
				$serverPortHash.PortId = $_.PortId
				$serverPortHash.SlotId = $_.SlotId
				$serverPortHash.Fabric_Id = $_.SwitchId
				$serverPortHash.Mac = $_.Mac
				$serverPortHash.Speed = $_.OperSpeed
				$serverPortHash.IfType = $_.IfType
				$serverPortHash.XcvrType = $_.XcvrType
				$serverPortHash.Performance = @{}
				$serverPortHash.Performance.Rx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "rx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$serverPortHash.Performance.Tx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "tx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$serverPortHash.Status = $_.OperState
				$serverPortHash.State = $_.AdminState
				$DomainHash.Lan.ServerPorts += $serverPortHash
			}
		}
		#--- Fabric PortChannels ---#
		$DomainHash.Lan.FabricPcs = @()
		Get-UcsFabricServerPortChannel -Ucs $handle | % {
			$uplinkHash = @{}
			$uplinkHash.Name = $_.Rn
			$uplinkHash.Chassis = $_.ChassisId
			$uplinkHash.Fabric_Id = $_.SwitchId
			$uplinkHash.Members = $_ | Get-UcsFabricServerPortChannelMember | Select EpDn,PeerDn
			$DomainHash.Lan.FabricPcs += $uplinkHash
		}
		#--- Uplink PortChannels ---#
		$DomainHash.Lan.UplinkPcs = @()
		Get-UcsUplinkPortChannel -Ucs $handle | % {
			$uplinkHash = @{}
			$uplinkHash.Name = $_.Rn
			$uplinkHash.Members = $_ | Get-UcsUplinkPortChannelMember | Select EpDn,PeerDn
			$DomainHash.Lan.UplinkPcs += $uplinkHash
		}
		#--- Qos Domain Policies ---#
		$DomainHash.Lan.Qos = @{}
		$DomainHash.Lan.Qos.Domain = @()
		$DomainHash.Lan.Qos.Domain += Get-UcsQosClass -Ucs $handle | Sort-Object Cos -Descending
		$DomainHash.Lan.Qos.Domain += Get-UcsBestEffortQosClass -Ucs $handle
		$DomainHash.Lan.Qos.Domain += Get-UcsFcQosClass -Ucs $handle
		
		#--- Qos Policies ---#
		$DomainHash.Lan.Qos.Policies = @()
		Get-UcsQosPolicy -Ucs $handle | % {
			$qosHash = @{}
			$qosHash.Name = $_.Name
			$qosHash.Owner = $_.PolicyOwner
			($qoshash.Burst,$qoshash.HostControl,$qoshash.Prio,$qoshash.Rate) = $_ | Get-UcsChild -ClassId EpqosEgress | Select Burst,HostControl,Prio,Rate | % {$_.Burst,$_.HostControl,$_.Prio,$_.Rate}
			$DomainHash.Lan.Qos.Policies += $qosHash
		}
		
		#--- VLANs ---#
		$DomainHash.Lan.Vlans = @()
		$DomainHash.Lan.Vlans += Get-UcsVlan -Ucs $handle | where {$_.IfRole -eq "network"} | Sort-Object -Property Ucs,Id
		
		#--- Network Control Policies ---#
		$DomainHash.Lan.Control_Policies = @()
		$DomainHash.Lan.Control_Policies += Get-UcsNetworkControlPolicy -Ucs $handle | ? Dn -ne "fabric/eth-estc/nwctrl-default" | Select Cdp,MacRegisterMode,Name,UplinkFailAction,Descr,Dn,PolicyOwner
		
		#--- Mac Address Pool Definitions ---#
		$DomainHash.Lan.Mac_Pools = @()
		Get-UcsMacPool -Ucs $handle | % {
			$macHash = @{}
			$macHash.Name = $_.Name
			$macHash.Assigned = $_.Assigned
			$macHash.Size = $_.Size
			($macHash.From,$macHash.To) = $_ | Get-UcsMacMemberBlock | Select From,To | % {$_.From,$_.To}
			$DomainHash.Lan.Mac_Pools += $macHash
		}
		
		#--- Mac Address Pool Allocations ---#
		$DomainHash.Lan.Mac_Allocations = @()
		$DomainHash.Lan.Mac_Allocations += Get-UcsMacPoolPooled | Select Id,Assigned,AssignedToDn
		
		#--- Ip Pool Definitions ---#
		$DomainHash.Lan.Ip_Pools = @()
		Get-UcsIpPool -Ucs $handle | % {
			$ipHash = @{}
			$ipHash.Name = $_.Name
			$ipHash.Assigned = $_.Assigned
			$ipHash.Size = $_.Size
			($ipHash.From,$ipHash.To,$ipHash.DefGw,$ipHash.Subnet,$ipHash.PrimDns) = $_ | Get-UcsIpPoolBlock | Select From,To,DefGw,PrimDns,Subnet | % {$_.From,$_.To,$_.DefGw,$_.Subnet,$_.PrimDns}
			$DomainHash.Lan.Ip_Pools += $ipHash
		}
		
		#--- Ip Pool Allocations ---#
		$DomainHash.Lan.Ip_Allocations = @()
		$DomainHash.Lan.Ip_Allocations += Get-UcsIpPoolPooled | Select AssignedToDn,DefGw,Id,PrimDns,Subnet,Assigned
		
		#--- vNic Templates ---#
		$DomainHash.Lan.vNic_Templates = @()
		$DomainHash.Lan.vNic_Templates += Get-UcsVnicTemplate -Ucs $handle | Select-Object Ucs,Dn,Name,Descr,SwitchId,TemplType,IdentPoolName,Mtu,NwCtrlPolicyName,QosPolicyName
		
		#--- End Lan Configuration ---#

		#--- Start SAN Configuration ---#
		#--- Uplink and Storage Ports ---#
		$DomainHash.San.UplinkPorts = @()
		$DomainHash.San.StoragePorts = @()
		#--- Iterate through each FI and grab san performance data based on port role ---#
		$DomainHash.Inventory.FIs | % {
			#--- SAN uplink ports ---#
			$_.Ports | ? IfRole -cmatch "fc.*uplink" | % {
				$port = $_
				$uplinkHash = @{}
				$uplinkHash.Dn = $_.Dn
				$uplinkHash.PortId = $_.PortId
				$uplinkHash.SlotId = $_.SlotId
				$uplinkHash.Fabric_Id = $_.SwitchId
				$uplinkHash.Mac = $_.Mac
				$uplinkHash.Speed = $_.OperSpeed
				$uplinkHash.IfType = $_.IfType
				$uplinkHash.XcvrType = $_.XcvrType
				$uplinkHash.Performance = @{}
				$uplinkHash.Performance.Rx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "rx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$uplinkHash.Performance.Tx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "tx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$uplinkHash.Status = $_.OperState
				$uplinkHash.State = $_.AdminState
				$DomainHash.San.UplinkPorts += $uplinkHash
			}
			#--- SAN storage ports ---#
			$_.Ports | ? IfRole -cmatch "storage" | % {
				$port = $_
				$storagePortHash = @{}
				$storagePortHash.Dn = $_.Dn
				$storagePortHash.PortId = $_.PortId
				$storagePortHash.SlotId = $_.SlotId
				$storagePortHash.Fabric_Id = $_.SwitchId
				$storagePortHash.Mac = $_.Mac
				$storagePortHash.Speed = $_.OperSpeed
				$storagePortHash.IfType = $_.IfType
				$storagePortHash.XcvrType = $_.XcvrType
				$storagePortHash.Performance = @{}
				$storagePortHash.Performance.Rx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "rx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$storagePortHash.Performance.Tx = $statistics | ? {$_.Dn -cmatch "$($port.Dn)/.*stats" -and $_.Rn -cmatch "tx[-]stats"} | Select TotalBytes,TotalPackets,TotalBytesDeltaAvg
				$storagePortHash.Status = $_.OperState
				$storagePortHash.State = $_.AdminState
				$DomainHash.San.StoragePorts += $storagePortHash
			}
		}
		#--- Uplink PortChannels ---#
		$DomainHash.San.UplinkPcs = @()
		#--- Native FC PC uplinks ---#
		Get-UcsFcUplinkPortChannel -Ucs $handle | % {
			$uplinkHash = @{}
			$uplinkHash.Name = $_.Rn
			$uplinkHash.Members = $_ | Get-UcsUplinkFcPort | Select EpDn,PeerDn
			$DomainHash.San.UplinkPcs += $uplinkHash
		}
		#--- FCoE PC uplinks ---#
		Get-UcsFabricFcoeSanPc -Ucs $handle | % {
			$uplinkHash = @{}
			$uplinkHash.Name = $_.Rn
			$uplinkHash.Members = $_ | Get-UcsFabricFcoeSanPcEp | Select EpDn
			$DomainHash.San.FcoePcs += $uplinkHash
		}
		
		#--- VSANs ---#
		$DomainHash.San.Vsans = @()
		$DomainHash.San.Vsans += Get-UcsVsan -Ucs $handle | Select FcoeVlan,Id,name,SwitchId,ZoningState,IfRole,IfType,Transport
		
		#--- WWN Pools ---#
		$DomainHash.San.Wwn_Pools = @()
		Get-UcsWwnPool -Ucs $handle | % {
			$wwnHash = @{}
			$wwnHash.Name = $_.Name
			$wwnHash.Assigned = $_.Assigned
			$wwnHash.Size = $_.Size
			$wwnHash.Purpose = $_.Purpose
			($wwnHash.From,$wwnHash.To) = $_ | Get-UcsWwnMemberBlock | Select From,To | % {$_.From,$_.To}
			$DomainHash.San.Wwn_Pools += $wwnHash
		}
		#--- WWN Allocations ---#
		$DomainHash.San.Wwn_Allocations = @()
		$DomainHash.San.Wwn_Allocations += Get-UcsWwnInitiator | Select AssignedToDn,Id,Assigned,Purpose
		
		#--- vHba Templates ---#
		$DomainHash.San.vHba_Templates = Get-UcsVhbaTemplate -Ucs $handle | Select Name,TempType
		
		#--- End San Configuration ---#
		
		#--- Get Event List ---#
		#--- Update current job progress ---#
		$Process_Hash.Progress[$domain] = 84
		#--- Grab faults of critical, major, minor, and warning severity sorted by severity ---#
		$faultList = Get-UcsFault -Ucs $handle -Filter 'Severity -cmatch "critical|major|minor|warning"' | Sort-Object -Property Ucs,Severity | Select-Object Ucs,Severity,Created,Descr,dn
		if($faultList)
		{
			#--- Iterate through each fault and grab information ---#
			foreach ($fault in $faultList)
			{
				$faultHash = @{}
				$faultHash.Severity = $fault.Severity;
				$faultHash.Descr = $fault.Descr
				$faultHash.Dn = $fault.Dn
				$faultHash.Date = $fault.Created
				$DomainHash.Faults += $faultHash
			}
		}
		#--- Update current job progress ---#
		$Process_Hash.Progress[$domain] = 96
		Complete-UcsTransaction -Ucs $handle
		#--- Add current Domain data to global process Hash ---#
		$Process_Hash.Domains[$DomainName] = $DomainHash
		#--- Disconnect from current UCS domain ---#
		Disconnect-Ucs -Ucs $handle
	}
	#--- Initialize runspaces to allow simultaneous domain data collection (could also use workflows) ---#	
	$Script:runspaces = New-Object System.Collections.ArrayList
	$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
	$runspacepool = [runspacefactory]::CreateRunspacePool(1, 10, $sessionstate, $Host)
	$runspacepool.Open() 
	#--- Iterate through each domain key and pass to GetUcsData script block ---# 
	$UCS.get_keys() | % {
		$domain = $_
		#--- Create powershell thread to execute script block with current domain ---#
		$powershell = [powershell]::Create().AddScript($GetUcsData).AddArgument($domain).AddArgument($Process_Hash)
		$powershell.RunspacePool = $runspacepool
		$temp = "" | Select-Object PowerShell,Runspace,Computer
		$Temp.Computer = $Computer
		$temp.PowerShell = $powershell
		#--- Invoke runspace ---#
		$temp.Runspace = $powershell.BeginInvoke()
		Write-Verbose ("Adding {0} collection" -f $temp.Computer)
		$runspaces.Add($temp) | Out-Null
	}
	
	Do {
		#--- Monitor each job progress and update write-progress ---#
		$Progress = 0
		#--- Catch conditions where no script progress has occurred ---#
		try{
			#--- Iterate through each process and add progress divided by process count ---#
			$Process_Hash.Progress.GetEnumerator() | % {
				$Progress += ($_.Value / $Process_Hash.Progress.Count)
			}
		}
		catch
		{
		}
		#--- Write Progress to alert user of overall progress ---#
		Write-Progress -Activity "Health Report in Progress..." `
			-PercentComplete $progress `
			-CurrentOperation "$progress% complete" `
			-Status "Data Collection can take several minutes"
		$more = $false
		#--- Iterate through each runspace in progress ---#
		Foreach($runspace in $runspaces) {
			#--- If runspace is complete cleanly end/exit runspace ---#
			If ($runspace.Runspace.isCompleted) {
				$runspace.powershell.EndInvoke($runspace.Runspace)
				$runspace.powershell.dispose()
				$runspace.Runspace = $null
				$runspace.powershell = $null                 
			} ElseIf ($runspace.Runspace -ne $null) {
				$more = $true
			}
		}
		#--- Sleep for 100ms before updating progress ---#
		If ($more) {
			Start-Sleep -Milliseconds 100
		}   
		#--- Clean out unused runspace jobs ---#
		$temphash = $runspaces.clone()
		$temphash | Where {
			$_.runspace -eq $Null
		} | ForEach {
			Write-Verbose ("Removing {0}" -f $_.computer)
			$Runspaces.remove($_)
		}  
		[console]::Title = ("Remaining Runspace Jobs: {0}" -f ((@($runspaces | Where {$_.Runspace -ne $Null}).Count)))             
	} while ($more)
	
	#--- Update overall progress to complete ---#
	Write-Progress "Done" "Done" -Completed
	
	#--- End collection script ---#
	
	#--- Start HTML report generation ---#
	
	#--- Add HTML and CSS markup to output file ---#
	$section_1 -replace 'DATE_REPLACE',(Get-Date -format MM/dd/yyyy) | Set-Content $OutputFile
	#--- Convert Process Hash to JSON variable and inject into report javascript variable ---#
	"Domains = " + ($Process_Hash.Domains | ConvertTo-JSON -Depth 14 -Compress) | Add-Content $OutputFile
	#--- Add javascript code to output file ---#
	$section_2 | Add-Content $OutputFile

	#--- Email Report if Email switch is set or Email_Report is set ---#
	if ($Email_Report -or $Email) 
	{ 
		$msg = new-object Net.Mail.MailMessage
		$att = new-object Net.Mail.Attachment(resolve-path $OutputFile)
		$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
		$msg.From = $mailfrom
		$msg.To.Add($mailto) 
		$msg.Subject = "Cisco UCS Health Check"
		$msg.Body = "Cisco UCS Health Check, open the attached HTML file to view the report."
		$msg.Attachments.Add($att) 
		$smtp.Send($msg)
	}
	#--- Write elapsed time to user ---#
	Write-host "Total Elapsed Time: $(&$GetElapsedTime $start)"
	if(-Not $Silent) { Read-Host "Health Check Complete.  Press any key to continue" }
}

#--- Get CCO credentials from user to pull firmware data from cisco.com ---#
function Get_CCO_Credentials
{
	while ($true)
	{
		Clear-Host
		Write-Host "Please enter CCO Credentials"
		$error.clear()
		try {
			$testCreds = Get-Credential
			$imageList = Get-UcsCcoImageList -Credential $testCreds
		}
		catch { 
			$ans = Read-Host "Error authenticating CCO Credentials.`n`nPress enter to retry or M to return to Main Menu"
			Switch -regex ($ans.ToUpper())
			{
				"^[M]" {
					return 0
				}
				default { continue }
			}
		}
		if(!$error) {
			$script:CCO_Creds = $testCreds
			$script:CCO_Image_List = $imageList
			return 1
		}
	}
}

#--- Funtion for user to view available firmware from Cisco.com ---#
function View_FW()
{

if(!(Get_CCO_Credentials)) { return }

	$list_menu = "
        UCSM FW Menu

1. View Available UCSM FW		
2. View Available Driver CDs
3. View Available Utilities
4. View All FW
5. Return to Main Menu
"
	while ($true)
	{
		Clear-Host
		Write-Host $list_menu
		$option = Read-Host "`nEnter Command Number"
		
		Switch ($option)
		{
			1 {
				Clear-Host
				Write-Host "Generating List.....`n"
				$CCO_Image_List | where {$_.ImageName -match ("bundle-infra|bundle-b-series|bundle-c-series")} | Select-Object Version,ImageName | Sort-Object Version -descending | Select-Object -first 30 | Format-Table
				$ans = Read-Host "`nPress any key to search for more firmware or M to return to the main menu"
				if ($ans -match "M") { return }
			}
			2 {
				Clear-Host
				Write-Host "Generating List.....`n"
				$CCO_Image_List | where {$_.ImageName -match "bxxx-drivers"} | Select-Object Version,ImageName | Sort-Object Version -descending | Format-Table
				$ans = Read-Host "`nPress any key to search for more firmware or M to return to the main menu"
				if ($ans -match "M") { return }
			}
			
			3 {
				Clear-Host
				Write-Host "Generating List.....`n"
				$CCO_Image_List | where {$_.ImageName -match "bxxx-utils"} | Select-Object Version,ImageName | Sort-Object Version -descending | Format-Table
				$ans = Read-Host "`nPress any key to search for more firmware or M to return to the main menu"
				if ($ans -match "M") { return }
			}
			
			4 {
				Clear-Host
				Write-Host "Generating List.....`n"
				$CCO_Image_List | where {$_.ImageName -notmatch "docs"} | select-object Version,ImageName | Sort-object Version -descending
				$ans = Read-Host "`nPress any key to continue"
			}
			
			5 {
				return
			}
		}

	}
}

#--- Disconnects all UCS Domains and exits the script ---#
function Exit_Program()
{
	foreach	($Domain in $UCS.get_keys())
	{
		if(HandleExists($UCS[$Domain]))
		{
			Write-Host "Disconnecting $($UCS[$Domain].Name)..."
			Disconnect-Ucs -Ucs $UCS[$Domain].Handle
			$script:UCS[$Domain].Remove("Handle")
		}
	}
	$script:UCS = $null
	Write-Host "Exiting Program`n"
}
#--- Function that checks that all required powershell modules are present ---#
function Check_Modules
{
	if(@(Get-Module -ListAvailable | ? {$_.Name -eq "CiscoUcsPs"}).Count -lt 1)
	{
		#--- Windows Form to alert user that the UCS powertool is not detected ---#
		[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
		$ans = [System.Windows.Forms.MessageBox]::Show(     
			"This script requires the UCS PowerTool Modules`n`nClick Yes to be directed to the download page", `
			"Attention", `
			[System.Windows.Forms.MessageBoxButtons]::YesNo, `
			[System.Windows.Forms.MessageBoxIcon]::Exclamation)
		if($ans -eq "Yes")
		{
		 start 'http://software.cisco.com/download/type.html?mdfid=283850978&flowid=25021'
		}
		exit
	}
	else
	{
			#--- Load UCS Module if not already loaded ---#
			if ((Get-Module | where {$_.Name -eq "CiscoUcsPS"}).Count -lt 1)
			{
				Write-Host "Loading Module: Cisco UCS PowerTool Module"
				Write-Host ""
				Import-Module CiscoUcsPs -ErrorAction Stop
			}
	}
}
#--- Function to check user powershell version ---#
function Check_PS_Version
{
	$version = (Get-Host).Version.Major
	if($version -lt 3)
	{
		#--- Windows Form to alert user the detected powershell version is not sufficient ---#
		[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
		$ans = [System.Windows.Forms.MessageBox]::Show(     
			"This script requires Windows Management Framework 3.0 or higher`n`nClick Yes to be directed to the download page", `
			"Attention", `
			[System.Windows.Forms.MessageBoxButtons]::YesNo, `
			[System.Windows.Forms.MessageBoxIcon]::Exclamation)
		if($ans -eq "Yes")
		{
		 start 'http://www.microsoft.com/en-us/download/details.aspx?id=34595'
		}
		exit
	}
}
#--- Ensures cached credentials are passed for automated execution ---#
if($UseCached -eq $false -and $RunReport -eq $true)
{
	Write-Host "`nCached Credentials must be specified to run report (-UseCached)`n`n"
	exit
}
#--- Loads cached ucs credentials from current directory ---#
if($UseCached)
{
	If(Test-Path "$((Get-Location).Path)\ucs_cache.ucs")
	{
		Connect_Ucs
	}
	else
	{
		Write-Host "`nCache File not found at $((Get-Location).Path)\ucs_cache.ucs`n`n"
		exit
	}
}
#--- Automates health check report execution if RunReport switch is passed ---#
If($UseCached -and $RunReport)
{
	Generate_Health_Check
	if($Silent)
	{
		Exit_Program
		exit
	}
}
#--- Check that required modules are present ---#
Check_Modules
#--- Check that the user is running powershell version 3.0 or higher ---#
Check_PS_Version
#--- Main Menu ---#
$main_menu = "
        Menu

1. Connect/Disconnect UCS Domains
2. Generate UCS Health Check Report
3. View Available UCS Firmware from Cisco.com
4. Exit Program
"
:menu
while ($true)
{
	Clear-Host
	Write-Host $main_menu
	$command = Read-Host "Enter Command Number"
	Switch ($Command)
	{
		#--- Connect to UCS domains ---#
		1 {	Connection_Mgmt	}
		#--- Run UCS Health Check Report ---#
		2 { Generate_Health_Check }
		#--- View available FW from Cisco.com ---#
		3 { View_FW }
		#--- Cleanly exit program ---#
		4 {
			Exit_Program
			break menu
		}
	}
}
