param cosmosAccountName string
param apiPrincipalId string

resource apiCosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: '${cosmosAccountName}/${guid(apiPrincipalId, cosmosAccountName, '00000000-0000-0000-0000-000000000002')}'
  properties: {
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: apiPrincipalId
    scope: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}'
  }
}