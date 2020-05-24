# 
# Script for getting datastore IO data from ESXi/vCenter
# push it into influxdb 
#
# GluffiS <gluffis @ gmail.com >
#
# Needs vcenter connect section, now it assumes that you are connected



# statcoutners that we want
$stat = "datastore.totalReadLatency.average","datastore.totalWriteLatency.average", "datastore.numberReadAveraged.average","datastore.numberWriteAveraged.average"
# function to push data to influxdb
# update $uri with string to your influx DB
  function  pushToInflux($influxString) {
    $uri = 'http://localhost:8086/write?db=test'
    Invoke-RestMethod -Uri $uri -Method POST -Body $influxString
}

# create hash for looking up human readable datastore names
$dsTab = @{}
Get-Datastore | Where {$_.Type -eq "VMFS"} | %{
  $key = $_.ExtensionData.Info.Vmfs.Uuid
  if(!$dsTab.ContainsKey($key)){
    $dsTab.Add($key,$_.Name)
  }
  else{
    "Datastore $($_.Name) with UUID $key already in hash table"
  }
}

# get all metrics 
$diskmetrics = get-vmhost | Get-Stat -realtime -maxsamples 1 -stat $stat #|where{$_.Instance -eq ''} |Select @{N='ESXi';E={$_.Entity.Name}},metricid,Value 

# iterate over metrics and push to database
foreach ($ds in $diskmetrics) {
    $timestamp = "$(([DateTimeOffset](Get-Date)).ToUnixTimeMilliseconds())000000"
    # read latency
    if ($ds.metricid -eq "datastore.totalreadlatency.average") {
        [string]$bork = $dstab[$ds.Instance]
        if ($bork.Length -gt 2) {
            $infstring = "disk_readlatency_avg,datastore=" + $dstab[$ds.Instance] + " value=" + $ds.Value + " " + $timestamp
            pushToInflux($infstring)
        }
    }
    # write latency
    if ($ds.metricid -eq "datastore.totalwritelatency.average") {
        [string]$bork = $dstab[$ds.Instance]
        if ($bork.Length -gt 2) {
            $infstring = "disk_writelatency_avg,datastore=" + $dstab[$ds.Instance] + " value=" + $ds.Value + " " + $timestamp
            pushToInflux($infstring)
        }
    }
    # number reads
    if ($ds.metricid -eq "datastore.numberReadAveraged.average") {
        [string]$bork = $dstab[$ds.Instance]
        if ($bork.Length -gt 2) {
            $infstring = "disk_reads_avg,datastore=" + $dstab[$ds.Instance] + " value=" + $ds.Value + " " + $timestamp
            pushToInflux($infstring)
        }
    }
    # number writes
    if ($ds.metricid -eq "datastore.numberWriteAveraged.average") {
        [string]$bork = $dstab[$ds.Instance]
        if ($bork.Length -gt 2) {
            $infstring = "disk_writes_avg,datastore=" + $dstab[$ds.Instance] + " value=" + $ds.Value + " " + $timestamp
            pushToInflux($infstring)
        }
    }



}

