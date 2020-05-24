#
# Powershell to get som data from your esxi servers
# 
# generates a csv and a html report
#
# Takes the following paramters
# server    = Your vcenter/esxi unless we shall use the dfault one
# usecred   = shall we use a credentials file, true/false 
# credfile  = where to find your file with credentials
# username  = your username 
# password  = your password

# GluffiS <gluffis @ gmail.com >

# Read some paramters
param (
    [string]$server = "<your default vcenter/esxi>",
    [switch]$usecred = $false ,
    [string]$credfile = "creds.xml",
    [string]$username,
    [string]$password
)

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'
# The ESXi summarizer
$vmcounthash = @{}
$esxihash = @{}

if ($usecred -eq $true) {
    write-host "Using credentials from " $credfile
    $credentials = Import-Clixml $credfile
    $username = $credentials.UserName
    $password = $credentials.getnetworkcredential().Password
}

# connect to VI server
write-host "Connecting to " $server
connect-viserver -server $server -Username $username -Password $password



# count vm's per ESXi
foreach ($esxi in $servers.Name) {
    $vmcounthash[$esxi] = (get-vm -location $esxi).count
}

$report = @()
foreach($esxi in Get-Vmhost ){
    $esxis = "" | Select-Object Name,Version,Build,Model,CpuTotalMhz, CpuUsageMhz ,MemoryTotalMB, MemoryUsageMB,MemPercent,ProcessorType,NumVM,NumVMStarted
    $esxis.Name =$esxi.Name
    $esxis.Version = $esxi.Version
    $esxis.Build = $esxi.Build
    $esxis.Model = $esxi.Model
    $esxis.CpuTotalMhz = $esxi.CpuTotalMhz
    $esxis.CpuUsageMhz = $esxi.CpuUsageMhz
    $esxis.MemoryTotalMB = [math]::Round($esxi.MemoryTotalMB)
    $esxis.MemoryUsageMB = $esxi.MemoryUsageMB
    $esxis.MemPercent = [math]::Round(($esxis.MemoryUsageMB / $esxis.MemoryTotalMB)*100)
    $esxis.ProcessorType = $esxi.ProcessorType
    $esxis.NumVM = (get-vm -location $esxi.name).count
    $esxis.NumVMStarted = ($esxi| Get-VM | Where-Object {$_.powerstate -eq 'PoweredOn'}).count
    $Report += $esxis
    $esxi = ""
}

# creating empty array
$report2 = @()

# iterate over datastores
foreach ($ds in Get-Datastore) {
    $storages = "" | select-object Name,FreeSpaceGB,CapacityGB,Type,state,datacenter
    $storages.Name = $ds.Name
    $storages.State = $ds.state
    $storages.datacenter = $ds.datacenter
    $storages.CapacityGB = [math]::Round($ds.CapacityGB)
    $storages.FreeSpaceGB = [math]::Round($ds.FreeSpaceGB)
    $storages.Type = $ds.type
    $report2 += $storages
    $ds = ""
}



#$servers = Get-Vmhost
#$snapshots = get-vm | Get-Snapshot | select vm,name, description, created,sizegb
#$vms = get-vm
# count vm's per ESXi
#foreach ($esxi in $servers.Name) {
#    $vmcounthash[$esxi] = (get-vm -location $esxi).count
#}
# get datastores
#$datastores = Get-Datastore | select Name,CapacityMB,FreeSpaceMB,Type
#$b = Get-Datastore | select Name,CapacityMB,FreeSpaceMB,Type
#$a = get-vmhost| select Name,Version,Build,Model,CpuTotalMhz, CpuUsageMhz ,MemoryTotalMB, MemoryUsageMB,ProcessorType


$head=@"
<style type="text/css">
table{
    width:100%; 
    border-collapse:collapse; 
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

# Generate html reports

# generate filenames
$timer = (Get-Date -Format yyy-mm-dd-HHmm.ss)
$esxifilename_h = "esxi." + $timer + ".html"
$esxifilename_c = "esxi." + $timer + ".csv"
$dsfilename_h = "datastores." + $timer + ".html"
$dsfilename_c = "datastores." + $timer + ".csv"

# sort reports
$report_sorted = $report | Sort-Object -Property Name
$report2_sorted = $report2 | sort-object -Property Name

# export to html
$body = $report_sorted | ConvertTo-Html -Fragment  | Out-String
$HTML = $pre, $body
$post = "<BR><i>Report generated on $((Get-Date).ToString()) </i>"
ConvertTo-HTML -Head $head -PostContent  $post -Body  $HTML |  Out-String |  Out-File $esxifilename_h

$body = $report2_sorted | ConvertTo-Html -Fragment  | Out-String
$HTML = $pre, $body
$post = "<BR><i>Report generated on $((Get-Date).ToString()) </i>"
ConvertTo-HTML -Head $head -PostContent  $post -Body  $HTML |  Out-String |  Out-File $dsfilename_h

# export to csv for excel
$report | Export-Csv -Path $esxifilename_c -Encoding utf8 -Delimiter ";"
$report2 | Export-Csv -Path $dsfilename_c -Encoding utf8 -Delimiter ";"
