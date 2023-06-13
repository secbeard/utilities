
$message = "The DNS server successfully completed transfer of version 3957916 of zone fondsftq.com to the DNS server at 172.17.20.221"

foreach ($s in Get-ADDomainController -Filter *) {
    Write-Host -ForegroundColor Green $s.HostName

    @(Get-DnsServerZone | Where-Object { ($_.zonetype -eq "primary") -and ($_.isReverseLookupZone -eq "false")} ).ForEach({ Get-DnsServerZoneTransferPolicy $_.zonename })
    #Invoke-Command -Authentication Kerberos -ComputerName $s.HostName -ScriptBlock { Get-WinEvent -FilterHashtable @{ LogName="DNS Server";id=6001;starttime=$((get-date).AddDays(-7).ToShortDateString());endtime=$((get-date).ToShortDateString()) }| foreach({ ($_.message.Split("at"))[-1] }) | Group-Object }
}


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

