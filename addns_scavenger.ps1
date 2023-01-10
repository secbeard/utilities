

function computer-exists([string]$computerName) {
    if (Get-ADComputer -Filter {name -eq $computerName }) { return $true }
    else { return $false }
}


[string]$zone = (Get-ADDomain).dnsroot
[string]$computerName = (Get-ADDomainController -Service PrimaryDC -Discover).hostname[0]


$dnsRecords = Get-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -RRType A

$stale = [System.Collections.ArrayList]@()
foreach ( $r in $dnsRecords.Where({$_.Hostname -notmatch '^@|^DomainDnsZones$|^ForestDnsZones$'}) ) {
    $rFQDN = "$($r.HostName).$zone"
    $pingResult = Test-NetConnection -ComputerName $rFQDN -ErrorAction SilentlyContinue
    if (!($pingResult.PingSucceeded)) {

        $staleRecord = [pscustomobject]@{
            "fqdn" = $rFQDN
            "hostname" = $r.HostName
            "RecordData" = $r.RecordData
            "RecordType" = $r.RecordType
            "Timestamp" = $r.Timestamp
            "TimeToLive" = $r.TimeToLive
            "pingSuccess" = $pingResult.PingSucceeded
            "adEnabled" = "nonexistent"
        }   

        if ( computer-exists -computerName $r.HostName ) { $staleRecord.adEnabled = (Get-ADComputer $r.HostName).enabled }

        $stale.Add($staleRecord)

    } # if (!($pingResult.PingSucceeded)) {
    
}

$stale | Out-GridView

foreach ($s in $stale | Out-GridView -PassThru -Title "Select records to delete") {
    Write-Host "removing $($s.HostName)"
    Remove-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -RRType "A" -Name $s.hostname -Force
}