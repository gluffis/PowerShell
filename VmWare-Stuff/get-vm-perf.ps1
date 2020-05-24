# 
# Script for getting cpu/memory data from VMs
# push it into influxdb 
#
# GluffiS <gluffis @ gmail.com >

# update $uri to point to your influx server
function  pushToInflux($influxString) {
    $uri = 'http://localhost:8086/write?db=test'
    Invoke-RestMethod -Uri $uri -Method POST -Body $influxString
}

$stats = Get-VM | Where-Object {$_.powerstate -eq 'PoweredOn'} |Get-Stat -Realtime -MaxSamples 1 |where{$_.Instance -eq ''} |Select @{N='VM';E={$_.Entity.Name}},metricid,Value 

foreach ($metric in $stats) {
    $timestamp = "$(([DateTimeOffset](Get-Date)).ToUnixTimeMilliseconds())000000"
    if ($metric.metricid -eq "cpu.usage.average") {
#        write-host $metric.ESXi   $metric.Value
        $infstring = "cpu_usage_average,vm=" + $metric.VM + " value=" + $metric.Value + " " + $timestamp
        pushToInflux($infstring)
    } 
    
    if ($metric.metricid -eq "cpu.usagemhz.average") {
#        write-host $metric.ESXi   $metric.Value
        $infstring = "cpu_usagemhz_average,vm=" + $metric.VM + " value=" + $metric.Value + " " + $timestamp
        pushToInflux($infstring)
    } 
    
    if ($metric.metricid -eq "mem.usage.average") {
 #       write-host $metric.ESXi   $metric.Value
        $infstring = "mem_usage_average,vm=" + $metric.VM + " value=" + $metric.Value + " " + $timestamp
        pushToInflux($infstring)
    } 
 
}
