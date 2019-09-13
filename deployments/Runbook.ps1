param (
    $StorageContainer = 'notejamdockeryy',
    $StorageAccount = "storagenotejamdockeryy",
    $StorageKey = "l8lhH8WeRiXAwGVDRFx2BMpsyxJ+VDiXPLW9+clutjjtpTsZKPxO1/hdApoXTwiyx0WkolkTkOZigJc0DkLxFQ=="
)

Disable-AzureRmContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection
$connection

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzureRmAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationID $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 10
}

$AzureContext = Select-AzureRmSubscription -SubscriptionId $connection.SubscriptionID

Get-AzureRmStorageAccount -ResourceGroupName test-notejam-rg -Name storagenotejamdockeryy -AzureRmContext $AzureContext

$StorageContext = New-AzureStorageContext –StorageAccountName $StorageAccount -StorageAccountKey $StorageKey
#$DestStorageContext = New-AzStorageContext –StorageAccountName $DestStorageAccount -StorageAccountKey $DestStorageKey

#$Blobs = Get-AzureStorageBlob -Context $StorageContext -Container $StorageContainer
#$Blobs

$backupdate = "backup-$(get-date -Format "dd-MM-yyyy")"
New-AzureStorageContainer -name backup -Context $StorageContext -ErrorAction SilentlyContinue

Get-AzureStorageBlob -Context $StorageContext -Container $StorageContainer | % {$_ | Start-AzureStorageBlobCopy -DestContext $StorageContext -DestContainer backup -DestBlob "$($_.name)-$backupdate"}
