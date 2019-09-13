$resourcegroupname="$(projectname)-rg"
$AutomationAccountName="AA$(projectname)"
$RunbookPath="$(System.DefaultWorkingDirectory)/_notejam-test-CI/infra/Runbook.ps1"
$storageAccountName="storage$(projectname)$(projectuniqeid)"
$StorageContainer="$(projectname)-$(projectuniqeid)"

New-AzureRmAutomationAccount -ResourceGroupName $resourcegroupname -Name $AutomationAccountName -Location "westeurope"
if (!(get-AzureRmAutomationRunbook -ResourceGroupName $resourcegroupname -Name notejamdbbackup -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue)) {
    Import-AzureRmAutomationRunbook -ResourceGroupName $resourcegroupname -Name notejamdbbackup -Published -Path $RunbookPath -AutomationAccountName $AutomationAccountName -Type PowerShell
}

$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroupname  -AccountName $storageAccountName).Value[0]

$StartTime = Get-Date "01:00:00"
if (!(get-AzureRmAutomationSchedule -ResourceGroupName $resourcegroupname -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue)) {
    New-AzureRmAutomationSchedule -ResourceGroupName $resourcegroupname -AutomationAccountName $AutomationAccountName `
        -Name "Daily-$StorageContainer-backup" -StartTime $StartTime -DayInterval 1 
}

Register-AzureRmAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -Name notejamdbbackup `
    -ScheduleName "Daily-$StorageContainer-backup" -ResourceGroupName $resourcegroupname `
    -Parameters @{StorageContainer=$StorageContainer;StorageAccount=$storageAccountName;StorageKey=$storageAccountKey}