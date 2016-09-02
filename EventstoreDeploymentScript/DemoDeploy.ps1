# Demo script from Collector Developer Open Sept 1st 2016
#
# http://www.meetup.com/Collector-Bank/events/233364939
# https://github.com/collector-bank/dev-open-sep


set-strictmode -version 3

. ./scripts/azure-rm-helpers.ps1

$ErrorActionPreference = 'Stop'


# Configure this for your environment ###
$resourceGroupLocation = 'West Europe'
$resourceGroupName =  ''
# ---------------------------------------


$rootDir = '.'
$templateDir = "$rootDir\templates"
$environment = 'demo'


#Connect to azure
Write-Host 'Connecting to Azure'


Login-AzureRmAccount


Write-Host 'Deploying BankyMcBankface'


        $context = @{
          "environment" = $environment
          "resourceGroupName" = $resourceGroupName
          "resourceGroupLocation" = $resourceGroupLocation
          "tags" = 'DevOpen'
          "paths" = @{
            "scripts" = (resolve-path "$rootDir\scripts")
            "tools" = ''
          }
          "result" = @{}
        }


        
        Write-Host 'Running Virtual network deployment'

         $context.result.deploy = Deploy-Template `
           -ResourceGroupName $resourceGroupName `
           -ResourceGroupLocation $resourceGroupLocation `
           -Environment $environment `
           -Template "deploy" `
           -TemplatesDir "$templateDir\VirtualNetwork"




        Write-host 'Running Eventstore predeployment'

       $preDeploymentScriptFile = "$templateDir\EventstoreCluster\PreDeploy.ps1"
        
     . $preDeploymentScriptFile -context $context



        Write-host 'Running Eventstore deployment'

          $context.result.deploy = Deploy-Template `
            -ResourceGroupName $resourceGroupName `
            -ResourceGroupLocation $resourceGroupLocation `
            -Environment $environment `
            -Template "deploy" `
            -TemplatesDir "$templateDir\EventStoreCluster"



