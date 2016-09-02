Import-Module Azure #-ErrorAction SilentlyContinue
Write-Host 'Imports azure helper functions'

function Authenticate {
    param(
        $reuseExistingAuthentication,
        $useOrganisationalAccount,
        $azureAccountName,
        $azureAccountPassword,
        $subscriptionName
    )

    try {
        [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.9")
    } catch {}

    $isAuthenticated = $false
    try {
        Get-AzureRmContext | Out-Null
        if ((Get-AzureSubscription) -ne $null) {
            $isAuthenticated = $true            
        }
    } catch {}
    $shouldLogin = -not $isAuthenticated -or -not $reuseExistingAuthentication

    if ($shouldLogin) {
        if ($useOrganisationalAccount) {
            Write-Host "Authenticating with Azure"

            if ($azureAccountName -eq $null) {
                $azureAccountName = Read-Host 'Please enter your Azure account name'
            }
            if ($azureAccountPassword -eq $null) {
                $azureAccountPassword = Read-Host -AsSecureString 'Please enter your Azure account password'
            }

            $azureCredential = New-Object System.Management.Automation.PSCredential($azureAccountName, $azureAccountPassword)
            Add-AzureAccount -Credential $azureCredential | Out-Null
            Add-AzureRmAccount -Credential $azureCredential | Out-Null
        } else {
            Add-AzureAccount | Out-Null
            Add-AzureRmAccount | Out-Null
        }
    } else {
        Write-Host 'Reusing existing Azure authentication'
    }

    $context = Set-AzureRmContext -SubscriptionName $subscriptionName

    return $context.Account.ToString()
}


function Deploy-Template {
    param(
        [string] $resourceGroupName,
        [string] $resourceGroupLocation,
        [string] $environment,
        [string] $template,
        [string] $templatesDir
    )

    $templateFile = "$templatesDir\$template.json"
    if (-not (Test-Path $templateFile)) {
      Write-Host "Template file ($templateFile) not found. Skipping deployment!" -fore yellow
      return $null
    } else {
      $templateFile = resolve-path $templateFile
    }

    $templateParametersFile = "$templatesDir\$template.parameters.$environment.json"
    if (-not (Test-Path $templateParametersFile)) {
      Write-Host "Parameters file ($templateParametersFile) for template $template is missing. Skipping deployment!" -fore yellow
      return $null
    } else {
      $templateParametersFile = resolve-path $templateParametersFile
    }

    Write-Host "Deploying template $templateFile to $resourceGroupName in $resourceGroupLocation"

    $deploymentName = ((Get-ChildItem $templateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('yyyyMMdd-HHmm'))

# If you need a new resource group, uncomment the line below
#    Create-ResourceGroup -resourceGroupName $resourceGroupName -resourceGroupLocation $resourceGroupLocation

    $deployment = New-AzureRmResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -TemplateParameterFile $templateParametersFile `
        -Force -Verbose
    # This is all we want to return from this function. Make sure to pipe every other command to Out-Null.
    $deployment
}

