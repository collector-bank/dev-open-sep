param(
    [Parameter(Mandatory=$true)] [hashtable] $context
)

$resourceGroupName = $context.resourceGroupName
$resourceGroupLocation = $context.resourceGroupLocation
$environment = $context.environment

$esStorageName = "esstorage$environment".ToLower()
$deploymentStorageName = "deploystorage$environment".ToLower()
$deploymentFilesSourceDir = (resolve-path "$PSScriptRoot\files")
$deploymentFilesTargetDir = '01301051-2ef4-4b18-bcd9-455f5396b77b' #([guid]::NewGuid()).ToString()
$deploymentFilesContainerName = 'files'

. "$($context.paths.scripts)\new-storage-account.ps1"

$existingStorage = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName

if($existingStorage -eq $null) {
  New-StorageAccount -name $esStorageName -resourceGroup $resourceGroupName -location $resourceGroupLocation -type Premium_LRS
} else {
  Write-Host "Found account $($existingStorage.StorageAccountName) in $resourceGroupName. Skipping storage creation."
}

New-StorageAccount -name $deploymentStorageName -resourceGroup $resourceGroupName -location $resourceGroupLocation -type Standard_LRS

Write-Host 'Fetching the deployment storage account'
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -name $deploymentStorageName

Write-Host 'Fetching the deployment storage account key'
$storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccount.StorageAccountName
$key = $storageAccountKey[0].Value

Write-Host 'Ensuring we have a deployment storage context'
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $key

Write-Host 'Ensuring we have a deployment storage container'
$container = $null
try {
  $container = Get-AzureStorageContainer -Name $deploymentFilesContainerName -Context $storageContext
} catch {}
if ($container -eq $null) {
  $container = New-AzureStorageContainer -Name $deploymentFilesContainerName -Permission Blob -Context $storageContext
}

$context.result.predeploy = @{
  "blobs" = @()
  "containerName" = $container.Name
  "storageAccountName" = $storageAccount.StorageAccountName
  "storageContext" = $storageContext
}

Write-Host 'Uploading deployment files'
Get-ChildItem $deploymentFilesSourceDir | % {
    $file = $_.FullName
    $blobName = "$deploymentFilesTargetDir/$($_.Name)"
    $downloadUrl = "$($storageContext.BlobEndPoint + $container.Name)/$blobName"

    Write-Host "Uploading '$file' as '$downloadUrl'"
    $result = Set-AzureStorageBlobContent -Container $container.Name -File $file -Blob $blobName -Context $storageContext -Force
    $context.result.predeploy.blobs += $blobName
}
