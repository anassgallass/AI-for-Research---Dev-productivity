// --------------------------------------------------------------------------
// Phase 2: Container App for the Azure AI Search MCP Server.
//
// Assumes infra.bicep has already been deployed and the Docker image has
// been pushed to ACR.  Receives infrastructure references as parameters.
// --------------------------------------------------------------------------

@description('Azure region.')
param location string = resourceGroup().location

@description('Base name used to derive resource names (must match infra.bicep).')
param appName string = 'mcp-search'

// ---- Infrastructure references (from infra.bicep outputs) ----
@description('ACR login server (e.g. myacr.azurecr.io).')
param acrLoginServer string

@description('Container Apps Environment resource ID.')
param environmentId string

// ---- Container image ----
@description('Full container image reference (e.g. myacr.azurecr.io/mcp-search-server:latest).')
param imageReference string

// ---- Azure AI Search secrets ----
@secure()
@description('Azure AI Search endpoint URL.')
param azureSearchEndpoint string

@secure()
@description('Azure AI Search query/admin API key.')
param azureSearchApiKey string

@description('Azure AI Search index name.')
param azureSearchIndexName string

@description('Comma-separated fields to exclude from search results.')
param azureSearchExcludeFields string = 'contentVector'

// ---- Derived names ----
var containerAppName = '${appName}-app'
var imageName = '${appName}-server'

// Look up the existing ACR to get credentials
var uniqueSuffix = uniqueString(resourceGroup().id, appName)
var acrName = take(replace('${appName}acr${uniqueSuffix}', '-', ''), 50)

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// ====================================================================
// Container App
// ====================================================================
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        allowInsecure: false
      }
      registries: [
        {
          server: acrLoginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'azure-search-endpoint'
          value: azureSearchEndpoint
        }
        {
          name: 'azure-search-api-key'
          value: azureSearchApiKey
        }
      ]
    }
    template: {
      containers: [
        {
          name: imageName
          image: imageReference
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'AZURE_SEARCH_ENDPOINT'
              secretRef: 'azure-search-endpoint'
            }
            {
              name: 'AZURE_SEARCH_API_KEY'
              secretRef: 'azure-search-api-key'
            }
            {
              name: 'AZURE_SEARCH_INDEX_NAME'
              value: azureSearchIndexName
            }
            {
              name: 'AZURE_SEARCH_EXCLUDE_FIELDS'
              value: azureSearchExcludeFields
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// ====================================================================
// Outputs
// ====================================================================
@description('Container App FQDN')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('Full MCP endpoint URL')
output mcpEndpoint string = 'https://${containerApp.properties.configuration.ingress.fqdn}/mcp'
