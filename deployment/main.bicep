@description('Create a new purview account or use an existing one')
@allowed([
  'new'
  'existing'
])
param newOrExistingPurviewAccount string = 'new'

@description('The name you provide will be appended with a unique sting to make it globally available. The Purview account name can contain only letters, numbers and hyphens. The first and last characters must be a letter or number. The hyphen(-) character must be immediately preceded and followed by a letter or number. Spaces are not allowed.')
param purviewAccountName string = 'purv'

@description('Povide the name of the resource group for the existing Purview account. Leave as it is if you are creating a new Purview account or if the existing Purview account is present in the same resource group where all other resources are going to be deployed. This resource group is required to get the Purview account path to assign required RBAC role(s) to the new or existing Purview account.')
param purviewResourceGroup string = resourceGroup().name

@description('The name you provide will be appended with a unique sting to make it globally available. The field can contain only lowercase letters and numbers. Name must be between 1 and 11 characters.')
param dataLakeAccountName string = 'dls'

@description('The name you provide will be appended with a unique sting to make it globally available. The field can contain only lowercase letters and numbers. Name must be between 1 and 11 characters.')
param storageAccountName string = 'sa'

@description('The name you provide will be appended with a unique sting to make it globally available. A vault\'s name must be between 1-11 alphanumeric characters. The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens.')
param keyVaultName string = 'kv'

@description('The name you provide will be appended with a unique sting to make it globally available. The name can contain only letters, numbers and hyphens. The first and last characters must be a letter or number. Spaces are not allowed.')
param factoryName string = 'adf'

@description('The client Id of azure active directory app/service principal')
param aadAppClientId string

@description('The client secret of azure active directory app/service principal')
@secure()
param aadAppClientSecret string

@description('Location where the resources will be deployed. It is, by default, set to the region of the resource group. You can upadate it to any other region. Note that all the resources will be deployed to the same location/region, that is why while chhosing the loaction, make sure all the resources/services are available in that location/region.')
param location string = resourceGroup().location

var uniqueS = uniqueString(resourceGroup().id)
var purviewAccountName_var =  toLower('${purviewAccountName}${uniqueS}')

module purviewDeployment  'purview.bicep' = if (newOrExistingPurviewAccount == 'new') {
  name: 'purviewDeployment'
  params: {
    location: location
    purviewAccountName: purviewAccountName_var
  }
  dependsOn: []
}


//output deletePurviewFunctionTriggerUrl string = deletePurviewFunctionTriggerUrl
//output configurePurviewFunctionTriggerUrl string = configurePurviewFunctionTriggerUrl
