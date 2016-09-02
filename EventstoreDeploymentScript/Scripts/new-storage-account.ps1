Function New-StorageAccount(
            [string]$name,
            [string]$resourceGroup,
            [string]$location,
            [string]$type)
{
  $accountExists = $false #Test-AzureName -Storage $name

  if ($accountExists)
  {
    Write-Host "Storage Account '$name' already exists. Skipping creation."
  }
  else
  {  
    Write-Host "Creating Storage Account '$name'"
    try
    {
      New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $name -Location $location -Type $type | Out-Null
    }
    catch
    {
      Write-Host $_.Exception -fore Red
    }
  }
}