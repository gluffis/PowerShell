# 
# Script for getting cpu/memory data from ESXi/vCenter
# push it into influxdb 
#
# GluffiS <gluffis @ gmail.com >
#
# Assumes that you are connected to vcenter

function  pushToInflux($influxString) {
    $uri = 'http://localhost:8086/write?db=test'
    Invoke-RestMethod -Uri $uri -Method POST -Body $influxString
}

$stats = Get-VMHost |Get-Stat -Realtime -MaxSamples 1 |where{$_.Instance -eq ''} |Select @{N='ESXi';E={$_.Entity.Name}},metricid,Value 

foreach ($metric in $stats) {
    $timestamp = "$(([DateTimeOffset](Get-Date)).ToUnixTimeMilliseconds())000000"
    if ($metric.metricid -eq "cpu.usage.average") {
#        write-host $metric.ESXi   $metric.Value
        $infstring = "cpu_load_average,host=" + $metric.ESXi + " value=" + $metric.Value + " " + $timestamp
        pushToInflux($infstring)
    } 
    if ($metric.metricid -eq "mem.usage.average") {
 #       write-host $metric.ESXi   $metric.Value
        $infstring = "mem_usage_average,host=" + $metric.ESXi + " value=" + $metric.Value + " " + $timestamp
        pushToInflux($infstring)
    } 
 
}
