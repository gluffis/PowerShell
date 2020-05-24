#
# Get list of snapshots older than 60 days
#
# GluffiS <gluffis @ gmail.com >
#
# Assumes that you are connected , should update with connect to vcenter section

$i = 0
$bork = @()
$snaps = get-vm|get-snapshot | where {$_.created -lt (get-date).adddays(-60)}
foreach ($sn in $snaps) {
    $storlek = [math]::Round($sn.SizeMB/1024,2)
    $bork += $sn,$storlek
    $bork[$i][name] = $sn.vm
    $bork[$i][storlek] = $storlek
    $bork[$i][created] = $sn.created
    write-host $sn.vm "`t" $storlek "`t" $sn.created "`t" $sn.powerstate
    $i++



}