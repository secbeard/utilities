

Get-DnsServerZone

Get-DnsServerZone -ComputerName $computerName -ZoneName $zone | select *
Get-DnsServerZone -ComputerName $computerName -ZoneName $zone | select DynamicUpdate,SecureSecondaries 

Get-DnsServerZone -ComputerName $computerName | Select-Object * | Out-GridView

Get-DnsServerForwarder

Get-DnsServerCache

Get-DnsServerDirectoryPartition

Get-DnsServerDnsSecZoneSetting -ComputerName $computerName -ZoneName $zone

Get-DnsServerDiagnostics

Get-DnsServerGlobalNameZone 

Get-DnsServerGlobalQueryBlockList

Get-DnsServerRecursion

Get-DnsServerRRL

Get-DnsServerScavenging

Get-DnsServerSetting

Get-DnsServerStatistics

Get-DnsServerZoneAging -ComputerName $computerName -ZoneName $zone

Get-DnsServerZoneDelegation -ComputerName $computerName -ZoneName $zone

Get-DnsServerZoneScope -ComputerName $computerName -ZoneName $zone

Get-DnsServerZoneTransferPolicy -ZoneName $zone

Get-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone | Out-GridView

