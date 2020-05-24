# 
# script to upgrade all vm hardware
#
# GluffiS <gluffis @ gmail.com >

$HardwareUpdateVMs =  Get-VM  | Where-Object {$_.powerstate -eq 'PoweredOff' }
 
Foreach ($VM in ($HardwareUpdateVMs)) {
    $VM.ExtensionData.UpgradeVM('vmx-15')
}