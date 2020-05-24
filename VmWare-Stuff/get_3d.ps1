#
# Script to get VM's that have 3d enabled 
#
# GluffiS <gluffis @ gmail.com >
# 
# need fixing for generating nice output

Connect-VIServer -server <vi server>

Get-View -ViewType VirtualMachine -Property Name,Config.Hardware.Device |

ForEach-Object {
  $vm = $_
  $vm.Config.Hardware.Device |   Where-Object {$_ -is [VMware.Vim.VirtualMachineVideoCard]} |   Select-Object -property @{N="VM";E={$vm.Name}},Enable3DSupport
} 