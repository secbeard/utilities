function dnsZone-backup() {
param(
    [parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage='ComputerName, usually a domain controller, can be obtained with: "Get-ADDomainController -Service PrimaryDC -Discover"' )]
    [string]$computerName=(Get-ADDomainController -Service PrimaryDC -Discover).hostname[0] ,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage='Name of the DNS zone to work with, current domain zone name can be obtained with: "(Get-ADDomain).dnsroot"')]
    [string]$zoneName = (Get-ADDomain).dnsroot ,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage='Backup file literal path')]
    [string]$filePath="$($Env:USERPROFILE)\Documents\dnsBackup-$zoneName.xml"
)
    Get-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zoneName | Export-Clixml -Depth 100 -Path $filePath -Force
}


function dnsZone-restore() {

param(
    [parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage='ComputerName, usually a domain controller, can be obtained with: "Get-ADDomainController -Service PrimaryDC -Discover"' )]
    [string]$computerName=(Get-ADDomainController -Service PrimaryDC -Discover).hostname[0] ,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage='Name of the DNS zone to work with, current domain zone name can be obtained with: "(Get-ADDomain).dnsroot"')]
    [string]$zoneName = (Get-ADDomain).dnsroot ,
    [parameter(Mandatory=$true,ValueFromPipeline=$false,HelpMessage='Backup file literal path')]
    [string]$filePath ,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,HelpMessage='Strip domain name, will split domain no "." and only keep the first record')]
    [switch]$splitDot

)
    $restore = Import-Clixml -Path $filePath | Out-GridView -PassThru -Title "Select record to restore"
    foreach ($r in $restore) {

        if ($stripDomain) { $rHostname = ($r.hostname.split("."))[0] }
        else { $rHostname = $r.HostName }

        switch ($r.RecordType) {
            'a' { Add-DnsServerResourceRecord -A -ComputerName $computerName -ZoneName $zoneName -AllowUpdateAny -Name $rHostname -TimeToLive $r.TimeToLive -IPv4Address $r.recordData.IPv4Address.IPAddressToString }

            'cname' { Add-DnsServerResourceRecord -CName -ComputerName $computerName -ZoneName $zoneName -Name $rHostname -TimeToLive $r.TimeToLive -HostNameAlias $r.RecordData.HostNameAlias }

            'ns' { Add-DnsServerResourceRecord -NS -ComputerName $computerName -ZoneName $zoneName -TimeToLive $r.TimeToLive -Name $rHostname -NameServer $r.RecordData.NameServer }
            
            'mx' { Add-DnsServerResourceRecord -MX -ComputerName $computerName -ZoneName $zoneName -TimeToLive $r.TimeToLive -Name $rHostname -MailExchange $r.RecordData.MailExchange -Preference $r.RecordData.Preference }

            'srv' {
                Add-DnsServerResourceRecord -Srv -ComputerName $computerName -ZoneName $zoneName `
                 -TimeToLive $r.TimeToLive -Name $rHostname -DomainName $r.RecordData.DomainName `
                 -Priority $r.RecordData.Priority -Weight $r.RecordData.Weight -port $r.RecordData.Port
            }

            default { write-host -ForegroundColor Yellow "Unmanaged record type: $($r.hostname)" }
        }

        if ( ($Error[0].InvocationInfo.MyCommand.Name -eq "Add-DnsServerResourceRecord") -and ($Error[0].Exception.Message.Contains($r.hostname)) ) {
            Write-Host -ForegroundColor Yellow "failed restoring record: $($r.HostName)"
        } else { 
            Write-Host -ForegroundColor Cyan "record restored: $($r.HostName)"
        }

    }
}





function computer-exists([string]$computerName) {
    if (Get-ADComputer -Filter {name -eq $computerName }) { return $true }
    else { return $false }
}

$restoreFile = "restoreStaleDnsLog.csv"
[string]$zone = (Get-ADDomain).dnsroot
[string]$computerName = (Get-ADDomainController -Service PrimaryDC -Discover).hostname[0]


#region remove record
$dnsRecords = Get-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -RRType A
#$dnsRecords = [System.Collections.ArrayList]@( Get-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -RRType A )
#Get-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -RRType CName

$stale = [System.Collections.ArrayList]@()
foreach ( $r in $dnsRecords.Where({$_.Hostname -notmatch '^@|^DomainDnsZones$|^ForestDnsZones$'}) ) {
    $rFQDN = "$($r.HostName).$zone"
    $pingResult = Test-NetConnection -ComputerName $rFQDN -ErrorAction SilentlyContinue
    if (!($pingResult.PingSucceeded)) {

        $staleRecord = [pscustomobject]@{
            "fqdn" = $rFQDN
            "hostname" = $r.HostName
            "ipv4address" = $r.RecordData.IPv4Address
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

$delete = $stale | Out-GridView -PassThru -Title "Select records to delete"
$stale | Add-Member -MemberType NoteProperty -Name deleteDate -Value $null

foreach ($s in $delete) {
    Write-Host "removing record: $($s.HostName)"
    Remove-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -RRType $s.RecordType  -Name $s.hostname -Force
    
    if ( ($Error[0].InvocationInfo.MyCommand.Name -eq "Remove-DnsServerResourceRecord") -and ($Error[0].Exception.Message.Contains($s.hostname)) ) {
        Write-Host -ForegroundColor Yellow "failed removing record: $($s.HostName)"
    } else { 
        Write-Host -ForegroundColor Cyan "record removed: $($s.HostName)"
        $s.deleteDate = Get-Date -Format yyyy-MM-dd
        $s | Export-Csv -NoTypeInformation -Path $restoreFile -Append
    }
}

Import-Csv -Path $restoreFile | Out-GridView
#endregion remove record


#region restore
$restore = Import-Csv -Path $restoreFile | Out-GridView -PassThru -Title "Select record to restore"
foreach ($s in $restore) {
    switch ($s.RecordType) {
        'a' { Add-DnsServerResourceRecord -ComputerName $computerName -ZoneName $zone -AllowUpdateAny -Name $s.hostname -IPv4Address $s.ipv4address -TimeToLive $s.TimeToLive -A }

        default { write-host -ForegroundColor Yellow "Unmanaged record type: $($s.hostname)" }
    }

    if ( ($Error[0].InvocationInfo.MyCommand.Name -eq "Add-DnsServerResourceRecord") -and ($Error[0].Exception.Message.Contains($s.hostname)) ) {
        Write-Host -ForegroundColor Yellow "failed restoring record: $($s.HostName)"
    } else { 
        Write-Host -ForegroundColor Cyan "record restored: $($s.HostName)"
    }

}
#endregion restore
