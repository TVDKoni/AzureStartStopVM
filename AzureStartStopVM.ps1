#Requires -Version 2.0

# Configuration
$tenantTimeZone = "Central Europe Standard Time"
$runTime = get-date
$toTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($tenantTimeZone)
$minutesDiff = $toTimeZone.GetUtcOffset($runTime).TotalMinutes
$runTime = $runTime.AddMinutes($minutesDiff)

# With automation connection
$automationConnectionName = "AzureRunAsConnection"
$conn = Get-AutomationConnection -Name $automationConnectionName
Add-AzureRmAccount -ServicePrincipal -TenantId $conn.TenantId -ApplicationId $conn.ApplicationId -CertificateThumbprint $conn.CertificateThumbprint

# With automation credentials
<#
$automationCredentialName = "AzureRunAsCredential"
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$psCredential = Get-AutomationPSCredential -Name $automationCredentialName
Login-AzureRmAccount -TenantId $TenantId -Credential $psCredential
#>

Get-AzureRmSubscription | foreach {
    "Checking subscription $($_.SubscriptionName) $($_.SubscriptionId)"
    $tmp = Select-AzureRmSubscription -SubscriptionId $_.SubscriptionId
    Get-AzureRmResourceGroup | foreach {
        $ResGName = $_.ResourceGroupName
        "Checking resource group $($ResGName)"
        foreach($vm in (Get-AzureRmVM -ResourceGroupName $ResGName))
        {
            "Checking VM $($vm.Name)"
            $tags = $vm.Tags
            $tKeys = $tags | select -ExpandProperty keys
            $startTime = $null
            $stopTime = $null
            foreach ($tkey in $tkeys)
            {
                if ($tkey.ToUpper() -eq "STARTTIME")
                {
                    $startTimeTag = $tags[$tkey]
                    "- startTimeTag: $($startTimeTag)"
                    $startTime = [datetime]::parseexact($startTimeTag,"HH:mm",$null)
                    "- startTime parsed: $($startTime)"
                }
                if ($tkey.ToUpper() -eq "STOPTIME")
                {
                    $stopTimeTag = $tags[$tkey]
                    "- stopTimeTag: $($stopTimeTag)"
                    $stopTime = [datetime]::parseexact($stopTimeTag,"HH:mm",$null)
                    "- stopTime parsed: $($stopTime)"
                }
            }
            if ($startTime)
            {
                if ($runTime -gt $startTime -and -not ($stopTime -and $startTime -lt $stopTime -and $runTime -gt $stopTime))
                {
                    $VMDetail = Get-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name -Status
                    foreach ($VMStatus in $VMDetail.Statuses)
                    {
                        "- VM Status: $($VMStatus.Code)"
                        if($VMStatus.Code.CompareTo("PowerState/deallocated") -eq 0)
                        {
                            "- Starting VM"
                            Start-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name
                        }
                    }
                }
            }
            if ($stopTime)
            {
                if ($runTime -gt $stopTime -and -not ($startTime -and $startTime -gt $stopTime -and $runTime -gt $startTime))
                {
                    $VMDetail = Get-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name -Status
                    foreach ($VMStatus in $VMDetail.Statuses)
                    { 
                        "- VM Status: $($VMStatus.Code)"
                        if($VMStatus.Code.CompareTo("PowerState/running") -eq 0)
                        {
                            "- Stopping VM"
                            Stop-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name -Force
                        }
                    }
                }
            }
        }
    }
}
