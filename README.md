
# Bicep Factory

 <p align="center">
  <img src="images/bicep.svg" />
</p>


## Introduction

This repo contains the basic foundation for developing and maintaining Internal Bicep Orchestration Modules.

## How it works?

Managing infrastructure at scale can be very difficult, using Infrastructure as Code Bicep Modules helps accelerate the process of deploying new Infrastructure by tenfold.
But as your Organization grows it becomes increasingly difficult to maintain configuration and security standards across a large Organization. Using multiple CI/CD tools also makes it even more difficult to re-use existing assets.

Bicep Factory follows a modern approach of authoring and sharing Bicep Orchestration Modules across an Organization, by leveraging Azure Container Registries as Repositories to hold Internally Validated and Tailored Bicep Modules that are ready for on-demand use. This approach works well in large environments as the Bicep Modules would be addressable via a simple URL e.g bicepfactory.azure.cr.io and can be access via Entra ID Auth.

This Repo contains a sample Bicep Orchestration Module 'classic-az-infra' for testing.

## Usage and Testing

### Prerequisites

1. Take a fork of this repo. In order to be able to use the Bicep Module in this repo, you must first Build and Publish the module to your own **Container Registry.**
<br> Create an Azure Container Registry in your Azure Subscription before you begin.  <br/>

2. In EntraID, Create a Service Principal with a Github Federated credential in your Azure Tenant that has AcrPull and AcrPush Permissions. Take note of the CLIENT_ID, TENANT_ID and SUBSCRIPTION_ID (the subscription ID where the Azure Container Registry will be) as you will need it in the next step.

3. In your Github Org/Account where you will fork this repo to, create the Github Environment Secrets CLIENT_ID, TENANT_ID and SUBSCRIPTION_ID. 

### Publish Bicep Module using Github Workflow

Once you have completed the Prereq steps, run the Github Action in your repo to start publishing your new Bicep Module.

### Publish Bicep Module using Azure CLI
Or you can publish your Module Manually using the following command:
```
az bicep publish --file main.bicep  --target br:AzureContainerRegistryName.azurecr.io/bicep/classic-az-infra:latest --force
```


<img src=images/bicepmodule.png  align="center">

## Next Steps
### Consuming Modules from an Azure Container Registry using .BicepParam file

Consuming your new Bicep Module is as easy as creating a new .bicepparam file using your favorite editor then running the Deployment Commands below.

```
using 'br:yourContainerRegistryName.azurecr.io/bicep/classic-azure-infra:latest'
param <Insert Param1 Name> = <Insert Param1 Value>
param <Insert Param2 Name> = <Insert Param2 Value>
param <Insert Param3 Name> = <Insert Param3 Value>
..  ..  ..  ..
```
Deployment Commands:<br/> ```az account set --subscription insertSubscriptionName```<br/>
```az deployment sub create --name insertDeploymentName --location  insertLocation --parameters params.bicepparam```
