param location string = resourceGroup().location
param sqlServerName string
param sqlServerLogin string
@secure()
param sqlServerPassword string
param sqlAzureAdLogin string
param sqlAzureAdPrincipalType string
param sqlAzureAdPrincipalId string
param sqlDatabaseName string
param sqlDatabaseLogin string
@secure()
param sqlDatabasePassword string
param storageAccountName string
param appServicePlanName string
param webAppName string

var shareName = 'sonarqube-extensions'

resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerLogin
    administratorLoginPassword: sqlServerPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      login: sqlAzureAdLogin
      principalType: sqlAzureAdPrincipalType
      sid: sqlAzureAdPrincipalId
      tenantId: subscription().tenantId
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }

  resource firewallRules 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  resource sqlDatabase 'databases' = {
    name: sqlDatabaseName
    location: location
    sku: {
      name: 'GP_S_Gen5_1'
    }
    properties: {
      collation: 'SQL_Latin1_General_CP1_CS_AS' // Collation MUST be case-sensitive (CS) and accent-sensitive (AS).
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }

  resource fileServices 'fileServices' = {
    name: 'default'

    resource shared 'shares' = {
      name: shareName
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'P1V3'
  }
  properties: {
    elasticScaleEnabled: false
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    reserved: true
    serverFarmId: appServicePlan.id
  }

  resource web 'config' = {
    name: 'web'
    properties: {
      alwaysOn: true
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      linuxFxVersion: 'DOCKER|sonarqube:latest'
      appCommandLine: '-Dsonar.es.bootstrap.checks.disable=true'
    }
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      SONAR_JDBC_URL: 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName};databaseName=${sqlDatabaseName}'
      SONAR_JDBC_USERNAME: sqlDatabaseLogin
      SONAR_JDBC_PASSWORD: sqlDatabasePassword
    }
  }

  resource share 'config' = {
    name: 'azurestorageaccounts'
    properties: {
      'sonarqube-extensions': {
        type: 'AzureFiles'
        accountName: storageAccountName
        accessKey: storageAccount.listKeys().keys[0].value
        shareName: shareName
        mountPath: '/opt/sonarqube/extensions'
      }
    }
  }
}
