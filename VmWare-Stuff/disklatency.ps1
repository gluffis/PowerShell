# 
# Get storage latency
#
# Needs updating with logging on to vcenter and produce a proper report
# GluffiS <gluffis @ gmail.com >

$stat = "disk.deviceReadLatency.average","disk.deviceWriteLatency.average"

$finish = get-date
$start = $finish.AddHours(-1)

$entities = Get-Inventory -name "esxi"

get-stat -Entity $entities -Stat $stat -Start $start -Finish $finish