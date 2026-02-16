// --------------------------------------------------------------------------
// Phase 1: Infrastructure for the Azure AI Search MCP Server.
//
// Creates:
//   1. Azure Container Registry  (Basic SKU, admin enabled)
//   2. Log Analytics workspace   (for Container App environment)
//   3. Container Apps Environment
//
// The Container App itself is deployed in Phase 2 (app.bicep) after the
// Docker image has been built and pushed to ACR.
// --------------------------------------------------------------------------

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Base name used to derive resource names.')
param appName string = 'mcp-search'

// ---- Derived names ----
var uniqueSuffix = uniqueString(resourceGroup().id, appName)
var acrName = replace('${appName}acr${uniqueSuffix}', '-', '')
var logAnalyticsName = '${appName}-logs-${uniqueSuffix}'
var envName = '${appName}-env-${uniqueSuffix}'

// ====================================================================
// 1. Azure Container Registry
// ====================================================================
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: take(acrName, 50)
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// ====================================================================
// 2. Log Analytics workspace
// ====================================================================
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ====================================================================
// 3. Container Apps Environment
// ====================================================================
resource appEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// ====================================================================
// Outputs (consumed by deploy.ps1 and app.bicep)
// ====================================================================
@description('ACR login server')
output acrLoginServer string = acr.properties.loginServer

@description('ACR name (for az acr login / az acr build)')
output acrName string = acr.name

@description('Container Apps Environment resource ID')
output environmentId string = appEnv.id
