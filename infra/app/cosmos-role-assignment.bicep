param cosmosAccountName string
param apiPrincipalId string
param developerPrincipalId string = ''

resource apiCosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: '${cosmosAccountName}/${guid(apiPrincipalId, cosmosAccountName, '00000000-0000-0000-0000-000000000002')}'
  properties: {
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: apiPrincipalId
    scope: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}'
  }
}

// Grant the signed-in developer data plane access for local migration scripts
resource developerCosmosRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = if (!empty(developerPrincipalId)) {
  name: '${cosmosAccountName}/${guid(developerPrincipalId, cosmosAccountName, '00000000-0000-0000-0000-000000000002')}'
  properties: {
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: developerPrincipalId
    scope: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}'
  }
}
