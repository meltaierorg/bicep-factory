using 'br:bicepfactory.azurecr.io/bicep/classic-az-infra:latest'
//////////////////////////////
/////// PARAMETERs //////////
/////////////////////////////

// Define Az Deployment metdata 
param applicationName  = 'appnameplaceolder'                       

param owner = 'github-team-teamnameexample2'

param environmentTagValue = 'Sandbox'                

param primaryLocation  = 'australiaeast'

param resourceGroup  = 'rg--001'

param VMGroup01Count = 2                             
param VMGroup01VMPrefix  = 'vmprefix'                 
param VMGroup01Size = 'Standard_D4ads_v5' 
param secretsKeyVaultName = 'kv-meltaier-org'
param vmAdminPasswordSecret = 'secret-vmadmin-breakglass'
param secretsVaultResourceGroup = 'rg-sandbox-meltaierorg'         
param subnetNameVMGroup01 = 'snet-sandbox-meltaierorg'    
param VMGroup01ASGPrefix = 'appnameplaceolder' 
