#
# Oneliner to get thick provisioned disks
#
# GluffiS <gluffis @ gmail.com >

Get-Datastore | Get-Vm | get-harddisk| where {$_.storageformat -eq "Thick"} select Parent,Name,CapacityGB,storageformat|sort-object -property Name | FT -autosize