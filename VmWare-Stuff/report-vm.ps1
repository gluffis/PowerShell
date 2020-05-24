#
# Powershell to get som data about your vm's
# generates a csv and a html report
# 
# Takes the following paramters
# server    = Your vcenter/esxi unless we shall use the dfault one
# usecred   = shall we use a credentials file, true/false 
# credfile  = where to find your file with credentials
# username  = your username 
# password  = your password

# GluffiS <gluffis @ gmail.com >


param (
    [string]$server = "192.168.2.200",
    [switch]$usecred = $false,
    [string]$credfile = "creds.xml",
    [string]$username,
    [string]$password
)

# first we do ESXi's

if ($usecred -eq $true) {
    write-host "Reading credentials from " $credfile
    $credentials = Import-Clixml $credfile
    $username = $credentials.UserName
    $password = $credentials.getnetworkcredential().Password
}

# connect to VI server
write-host "Connecting to: " $server
connect-viserver -server $server -Username $username -Password $password

# then we do VM's 

$report = @()
$report2 = @()
$report3 = @()
$report_csv = @()
foreach($vm in Get-View -ViewType Virtualmachine){
    $vms = "" | Select-Object VMName, Hostname, OS, Boottime,VMHost, TotalCPU, 
         OverallCpuUsage, CPUreservation,CPUShare, TotalMemory,  MemoryUsage,
         Swapped, Ballooned, Compressed, TotalNics, Portgroup,ToolsStatus,
         ToolsVersion, HardwareVersion, TimeSync, FaultTolerance, Capacity,UsedSpaceGB, Datastore,
         GuestFullName,NumSnapShots,SnapShotSize,Enable3DSupport,Notes,VMState

    $vms.VMName = $vm.Name
    $vms.Hostname = $vm.guest.hostname
 #   $vms.IPAddress = $vm.guest.ipAddress
    $vms.OS = $vm.Config.GuestFullName
    $vms.Boottime = $vm.Runtime.BootTime
    $vms.VMState = $vm.summary.runtime.powerState
    $vms.TotalCPU = $vm.summary.config.numcpu
#    $vms.CPUAffinity = $vm.Config.CpuAffinity
#    $vms.CPUHotAdd = $vm.Config.CpuHotAddEnabled
    $vms.CPUShare = $vm.Config.CpuAllocation.Shares.Level
    $vms.TotalMemory = $vm.summary.config.memorysizemb
#    $vms.MemoryHotAdd = $vm.Config.MemoryHotAddEnabled
  #  $vms.MemoryShare = $vm.Config.MemoryAllocation.Shares.Level
    $vms.TotalNics = $vm.summary.config.numEthernetCards
    $vms.OverallCpuUsage = $vm.summary.quickStats.OverallCpuUsage
    $vms.MemoryUsage = $vm.summary.quickStats.guestMemoryUsage
    $vms.ToolsStatus = $vm.guest.toolsstatus
    $vms.ToolsVersion = $vm.config.tools.toolsversion
    $vms.TimeSync = $vm.Config.Tools.SyncTimeWithHost
    $vms.HardwareVersion = $vm.config.Version
#    $vms.MemoryLimit = $vm.resourceconfig.memoryallocation.limit
#    $vms.MemoryReservation = $vm.resourceconfig.memoryallocation.reservation
    $vms.CPUreservation = $vm.resourceconfig.cpuallocation.reservation
#    $vms.CPUlimit = $vm.resourceconfig.cpuallocation.limit
#    $vms.CBT = $vm.Config.ChangeTrackingEnabled
    $vms.Swapped = $vm.Summary.QuickStats.SwappedMemory
    $vms.Ballooned = $vm.Summary.QuickStats.BalloonedMemory
    $vms.Compressed = $vm.Summary.QuickStats.CompressedMemory
    $vms.Portgroup = (Get-View -Id $vm.Network -Property Name | select -ExpandProperty Name|sort-object) -join ', '
    $vms.VMHost = Get-View -Id $vm.Runtime.Host -property Name | select -ExpandProperty Name
    #$vms.ProvisionedSpaceGB = [math]::Round($vm.Summary.Storage.UnCommitted/1GB,2)
    $vms.UsedSpaceGB = [math]::Round($vm.Summary.Storage.Committed/1GB,2)
    #$vms.UsedSpaceGB = [math]::Round($vm.Storage.PerDatastoreUsage.Committed/1GB,2)
    $vms.Capacity = [math]::Round(($vm.Config.Hardware.Device | Where-Object {$_.key -eq $vm.LayoutEx.Disk.Key} | Select-Object -ExpandProperty capacityInBytes)/1Gb,2)
    #$vms.ProvisionedSpaceGB = [math]::Round(($vm.Storage.PerDatastoreUsage.UnCommitted + $vm.Storage.PerDatastoreUsage.Committed )/1GB,2)
    #$vms.UsagePercent = [math]::Round(($vms.UsedSpaceGB / $vms.ProvisionedSpaceGB)*100,2)
    $vms.Datastore = $vm.Config.DatastoreUrl[0].Name
    #$vms.Notes = $vm.Config.Annotation
    $vms.FaultTolerance = $vm.Runtime.FaultToleranceState
    $vms.GuestFullName = $vm.Summary.Guest.GuestFullName
    $vms.NumSnapShots = (get-vm $vm.name|get-snapshot).count
    $vms.SnapShotSize = [math]::Round((get-snapshot -vm $vm.name |Measure-Object -sum SizeMB).sum)
    $vms.Enable3DSupport = $vm.config.hardware.device |   Where-Object {$_ -is [VMware.Vim.VirtualMachineVideoCard]} |   Select-Object -property Enable3DSupport
    $Report += $vms
    $vm = ""
}

foreach ($apa in $report) {
        #write-host "I WIN: " $apa.vmname
        if ($apa.Enable3DSupport -match "False") { 
            $apa.Enable3DSupport = "No"
        } else {
            $apa.Enable3DSupport = "Yes"
        }
        if ($apa.FaultTolerance -eq "notConfigured") {
            $apa.FaultTolerance = "No"
        } else {
            $apa.FaultTolerance = "Yes"
        }
        if ($apa.ToolsStatus -eq "toolsNotInstalled") {
            $apa.ToolsStatus = "Not installed"
        } elseif ($apa.ToolsStatus -eq "toolsOk"){
            $apa.ToolsStatus = "Ok" 
        } elseif ($apa.ToolsStatus -eq "toolsNotRunning") {
            $apa.ToolsStatus = "Not running"
        } else { 
            $apa.ToolsStatus = "Unknown" 
        }
        if ($apa.VMState -eq "poweredOn") { 
            $apa.VMState = "On"
            $report2 += $apa | select-object VMname,Hostname,OS,VMHost,TotalCpu,OverallCpuUsage,TotalMemory,TotalNics,Portgroup,ToolsStatus,ToolsVersion,
            HardwareVersion,Capacity,UsedSpaceGB,NumSnapShots,SnapShotSize,Enable3DSupport
        } else { $apa.VMState = "Off"}
        $report_csv += $apa
        $report3 = $report2 |Sort-Object -Property VMName
}

write-host "PoweredOns: " $report2.count

$head=@"
<style type="text/css">
table{
    width:100%; 
    border-collapse:collapse; 
    white-space:nowrap;
}
table td{ 
    padding:7px; border:#4e95f4 1px solid;
}
/* provide some minimal visual accomodation for IE8 and below */
table tr{
    background: #b8d1f3;
}
/*  Define the background color for all the ODD background rows  */
table tr:nth-child(odd){ 
    background: #b8d1f3;
}
/*  Define the background color for all the EVEN background rows  */
table tr:nth-child(even){
    background: #dae5f4;
}
</style>
"@ 

$pre = @"
  <H1>VM Report </H1>   
"@ 

$timer = (Get-Date -Format yyy-mm-dd-HHmm.ss)
$vmfilename_h = "vms." + $timer + ".html"
$vmfilename_c = "vms." + $timer + ".csv"


$body = $report3 | ConvertTo-Html -Fragment  | Out-String
$HTML = $pre, $body
$post = "<BR><i>Report generated on $((Get-Date).ToString()) </i>"
ConvertTo-HTML -Head $head -PostContent  $post -Body  $HTML |  Out-String |  Out-File $vmfilename_h

$report_csv |export-csv -path $vmfilename_c -Encoding utf8 -Delimiter ";"


