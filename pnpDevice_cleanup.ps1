# Get-Module *pnp* -ListAvailable
Import-Module pnpdevice
@(Get-PnpDevice).Where({ ($_.present -ne $true) }) | Select-Object -Property Name,Description,Manufacturer,Present,PNPClass,PNPDeviceID | Out-GridView -PassThru | foreach ($currentItemName in $collection) {
    <# $currentItemName is the current item #>
} ({ $cmdLine = 'pnputil /remove-device ' + '"' + $_.pnpdeviceid + '"'; Invoke-Expression -Command $cmdLine })

<# 

#pnputil /enum-devices /disconnected
#pnputil /remove-device "USB\VID_045E&PID_00DB\6&870CE29&0&1"

get-help Get-PnpDevice -full
Get-PnpDevice: No matching Win32_PnPEntity objects found by CIM query for instances of the ROOT\cimv2\Win32_PnPEntity class on the  CIM server: SELECT * FROM Win32_PnPEntity  WHERE ((DeviceId LIKE 'False')) AND ((Present = TRUE)). 
Verify query parameters and retry
#>
