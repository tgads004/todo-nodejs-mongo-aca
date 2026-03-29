param accountName string
param location string = resourceGroup().location
param tags object = {}
param cosmosDatabaseName string = ''
param containers array = [
  {
    name: 'TodoList'
    id: 'TodoList'
    paths: [
      '/Hash'
    ]
  }
  {
    name: 'TodoItem'
    id: 'TodoItem'
    paths: [
      '/Hash'
    ]
  }
]

var defaultDatabaseName = 'Todo'
var actualDatabaseName = !empty(cosmosDatabaseName) ? cosmosDatabaseName : defaultDatabaseName

module cosmos 'br/public:avm/res/document-db/database-account:0.6.0' = {
  name: 'cosmos-sql'
  params: {
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: location
      }
    ]
    name: accountName
    location: location
    disableLocalAuth: true
    sqlDatabases: [
      {
        name: actualDatabaseName
        tags: tags
        containers: containers
      }
    ]
  }
}

output databaseName string = actualDatabaseName
output endpoint string = cosmos.outputs.endpoint
output accountName string = cosmos.outputs.name
