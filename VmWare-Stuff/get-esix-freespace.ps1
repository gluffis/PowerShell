# 
# Script for getting free space on datastores from ESXi/vCenter
# push it into influxdb 
#
# GluffiS <gluffis @ gmail.com >

function  pushToInflux($influxString) {
    $uri = 'http://localhost:8086/write?db=test'
    Invoke-RestMethod -Uri $uri -Method POST -Body $influxString
}

# get metrics, skipping ISO storage filesystems
$datastores = Get-Datastore | where {$_.Name -notlike "*ISO*" -and $_.Name -notlike "*template*" } | sort -Property FreeSpaceGB -Descending

foreach ($ds in $datastores) {
    # get and format proper timestamp for InfluxDB
    $timestamp = "$(([DateTimeOffset](Get-Date)).ToUnixTimeMilliseconds())000000"
    $infstring = "datastore_free_space,datastore=" + $ds.Name + " value=" + $ds.FreeSpaceGB + " " + $timestamp
    pushToInflux($infstring)
}
