param resourceSuffix string
param databaseAdministratorName string
param databaseAdministratorObjectId string

var testApiHostname = '${resourceSuffix}-api-${uniqueString(resourceGroup().name)}-test'
var productionApiHostname = '${resourceSuffix}-api-${uniqueString(resourceGroup().name)}'

resource QuickStartServerFarm 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: '${resourceSuffix}-asp'
  location: resourceGroup().location
  sku: {
    name: 'S1'
  }
  kind: 'windows'
  properties: {
    reserved: true
  }
}

resource CiCdIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourceSuffix}-cicd-umi'
  location: resourceGroup().location
}

resource SqlDatabaseServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: '${resourceSuffix}-sqlserver'
  location: resourceGroup().location
  properties: {
    minimalTlsVersion: '1.2'
    administrators: {
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      login: databaseAdministratorName
      principalType: 'Application'
      tenantId: subscription().tenantId
      sid: databaseAdministratorObjectId
    }
  }
}

resource WebAppTest 'Microsoft.Web/sites@2021-01-15' = {
  name: '${resourceSuffix}-${uniqueString(resourceGroup().name)}-test'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: QuickStartServerFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Test'
        }
        {
          name: 'ApiSettings__URL'
          value: 'https://${testApiHostname}.azurewebsites.net/'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'DOTNET|5.0'
        }
      ]
    }
  }
}

resource WebApiTest 'Microsoft.Web/sites@2021-01-15' = {
  name: testApiHostname
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: QuickStartServerFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Test'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'DOTNET|5.0'
        }
      ]
    }
  }
}

resource SqlDatabaseTest 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: '${resourceSuffix}-test-sqldb'
  parent: SqlDatabaseServer
  location: resourceGroup().location
}

resource WebApp 'Microsoft.Web/sites@2021-01-15' = {
  name: '${resourceSuffix}-${uniqueString(resourceGroup().name)}'
  location: resourceGroup().location
  properties: {
    httpsOnly: true
    serverFarmId: QuickStartServerFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'ApiSettings__URL'
          value: 'https://${productionApiHostname}.azurewebsites.net/'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'DOTNET|5.0'
        }
      ]
    }
  }
}

resource WebAppGreen 'Microsoft.Web/sites/slots@2021-01-15' = {
  parent: WebApp
  name: 'green'
  location: resourceGroup().location
  properties: {
    httpsOnly: true
    serverFarmId: QuickStartServerFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'ApiSettings__URL'
          value: 'https://${productionApiHostname}.azurewebsites.net/'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'DOTNET|5.0'
        }
      ]
    }
  }
}


resource WebApi 'Microsoft.Web/sites@2021-01-15' = {
  name: productionApiHostname
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: QuickStartServerFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'DOTNET|5.0'
        }
      ]
    }
  }
}

resource WebApiGreen 'Microsoft.Web/sites/slots@2021-01-15' = {
  parent: WebApi
  name: 'green'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: QuickStartServerFarm.id
    siteConfig: {
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: 'DOTNET|5.0'
        }
      ]
    }
  }
}

resource SqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: '${resourceSuffix}-sqldb'
  parent: SqlDatabaseServer
  location: resourceGroup().location
}
