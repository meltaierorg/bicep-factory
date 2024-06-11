targetScope = 'subscription'
param repoName string = 'unset'



/////////////////////////////////// Provide Context. App Prefix is used for naming ARM Deployment and tagging (avoids deployment concurrency issues) 
////////////////////////////  START ////////////////////////////////////////////

@maxLength(20)
@description('REQUIRED. Application Name used for Tagging.')
param applicationName string

@description('REQUIRED. Owner information is used to configure Azure tags .')
param owner string


@description('REQUIRED. Main Resource Group used to deploy Application Components.')
param resourceGroup  string

/////////// Define Essential Resource Tags
@description('REQUIRED. Environment Tag to add to Resource Group and Azure Resources')
@allowed([
  'Sandbox'
  'Test'
])
param environmentTagValue string



////////////////////////////  END ////////////////////////////////////////////



///////////////////////////   Define network related parameters    /////////////
//////////////////////// START
@description('OPTIONAL.The name of the existing Spoke VNet Resource Group')
param existingSpokeVnetRG string = 'rg-sandbox-meltaierorg'


@description('OPTIONAL.Primary Region')
param primaryLocation string = 'australiaeast'
////////////////////// END
//////////////////////////////////////////////////////////////////////////////                                               



@description('OPTIONAL. Name of the Keyvault Resource Group that contains Virtual Machine Svc Account credentials. ')
param secretsVaultResourceGroup string = 'rg-sandbox-meltaierorg'

@description('OPTIONAL. Name of the Keyvault that contains VM Svc Account Secret. ')
param secretsKeyVaultName string =  'kv-meltaier-org'




////////////////////// Define Vnet and default Landing Zone Subnet names 
//////////// START
@allowed([
  'vnet-sandbox-meltaierorg'
])
@description('OPTIONAL.Name of the Vnet that will host the Virtual Machines')
param vnetName string = 'vnet-sandbox-meltaierorg'



@allowed([
  'snet-sandbox-meltaierorg'
])
@description('OPTIONAL.VM Group 01 Subnet Name')
param subnetNameVMGroup01 string  = 'snet-sandbox-meltaierorg'

@description('OPTIONAL.VM Prefix for VMGroup01. Default is abc1sbx')
@maxLength(10)
param VMGroup01VMPrefix string = 'abc1sbx'

//
@description('OPTIONAL. Flag to enable ASG deployment .')
param VMGroupDeployASG bool = true

@description('OPTIONAL.ASG Prefix for VMGroup01. Default is VMGroup01')
@maxLength(20)
param VMGroup01ASGPrefix string = 'VMGroup01'

//

//
var VMGroup01Naming  = 'vm${VMGroup01VMPrefix}0'                                 

//
@description('OPTIONAL.VM Prefix Starting Integer for VMGroup01.')
param VMGroup01VMPrefixStartInt int = 1

//
@description('OPTIONAL.Number of VMGroup01 Servers')
param VMGroup01Count int = 0  // This value is used to determine the number of VMs to deploy for VMGroup01, set to 1 or higher to deploy VMs.     


@description('OPTIONAL.Size of VMGroup01 Servers')
param VMGroup01Size string = 'Standard_D4ads_v5'   


@description('OPTIONAL. The Windows Image Profile for all VMs.')
param windowsServerBaseImageReference object = {
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    sku: '2022-datacenter-smalldisk-g2'
    version: 'latest'
}
 
@description('OPTIONAL.VM Admin Username to be used for all VMs. Can be used as a breakglass account')
param vmAdminUsername string = 'localvmadmin'


@description('OPTIONAL.VM Admin Password to be used for all VMs. Can be used as a breakglass account')
param vmAdminPasswordSecret string = ''

@description('OPTIONAL.VM OS type for all VMs')
param vmOsType string = 'Windows'
//



//


//
@description('OPTIONAL.The OS Disk Profile for all VMGroup01 VMs.')
param VMGroup01OsDiskProfile object  = {
  osDisk : {
    caching: 'None'
    createOption: 'fromImage'
    deleteOption: 'Delete'
    diskSizeGB: '100'
    managedDisk: {
      storageAccountType: 'Premium_LRS'
  }
}}

//
@description('OPTIONAL.The Data Disk Profile for VMGroup01. Single Disk')
param VMGroup01DataDiskProfile object = {

    dataDisks: [
    {
      name: 'data01'
      diskSizeGB: 128
      caching: 'ReadWrite'
      createOption: 'Empty'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
    }
    }
  ]
  }


// Construct Master VM Deployment Template
var vmBuildTemplate  = {
  vmRoles:{
    vmGroup01:{ 
      prefix: VMGroup01Naming
      count: VMGroup01Count
      vmSize: VMGroup01Size
      subnet: resourceId(subscription().subscriptionId, existingSpokeVnetRG, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetNameVMGroup01)
      osDiskProfile: VMGroup01OsDiskProfile.osDisk
      dataDiskProfile : VMGroup01DataDiskProfile.dataDisks
    }
}
}
//




var VMGroup01ListofVMs = [for i in range(0, vmBuildTemplate.vmRoles.vmGroup01.count): {
  name: '${vmBuildTemplate.vmRoles.vmGroup01.prefix}${(i + VMGroup01VMPrefixStartInt)}'
  resourceID: resourceId(subscription().subscriptionId, resourceGroup, 'Microsoft.Compute/virtualMachines', '${vmBuildTemplate.vmRoles.vmGroup01.prefix}${(i + VMGroup01VMPrefixStartInt)}')
  vmSize: vmBuildTemplate.vmRoles.vmGroup01.vmSize
  subnet: vmBuildTemplate.vmRoles.vmGroup01.subnet
  osDiskProfile: vmBuildTemplate.vmRoles.vmGroup01.osDiskProfile
  dataDiskProfile: vmBuildTemplate.vmRoles.vmGroup01.dataDiskProfile
  availzone:  i % 2 == 0 ? 1 : 2  // select zone 1 for the first VM and 2 for the second, 1 for the third, 2 for fourth 
}]




// Deploy Primary  Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroup
  location: primaryLocation
  tags: {
    'Owner': owner
    'RepoURL': repoName
    'Environment': environmentTagValue
  }
}

resource existingSecretKeyvaultRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: secretsVaultResourceGroup
  
}

// Existing Key vault is used. 
resource secretsKv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  scope: existingSecretKeyvaultRg
  name: secretsKeyVaultName
}




// Deploy VM Group 1 Servers 
module VMGroup01 '../../modules/Microsoft.Compute/virtualMachines/deploy.bicep' =  [for vm in VMGroup01ListofVMs: if(VMGroup01Count > 0) {
  name: 'deploy-${vm.name}'
  scope: rg
  params: {
    name: vm.name
    location: primaryLocation
    tags: {
      'Owner': owner
      'RepoURL': repoName
      'Application': applicationName
      'Environment': environmentTagValue
    }
    vmSize: vm.vmSize
    osDisk: vm.osDiskProfile
    dataDisks: vm.dataDiskProfile
    enableAutomaticUpdates: false
    osType: vmOsType
    imageReference: windowsServerBaseImageReference
    encryptionAtHost: false
    nicConfigurations: [
      {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          subnetResourceId : vm.subnet
        }
        
      ]
    }
    ]

    adminUsername: vmAdminUsername
    adminPassword: secretsKv.getSecret(vmAdminPasswordSecret)
    availabilityZone: vm.availzone

    ASGPrefix: VMGroup01ASGPrefix
    deployASG: VMGroupDeployASG
  }
  dependsOn: [
    
  ]
}]
