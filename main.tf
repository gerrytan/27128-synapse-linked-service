provider "azurerm" {
  # Set ARM_SUBSCRIPTION_ID env var to avoid having to hardcode it here
  features {
  }
}

variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "sql_administrator_login_password" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_kind             = "BlobStorage"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
  name               = "${var.prefix}-fs"
  storage_account_id = azurerm_storage_account.example.id
}

resource "azurerm_synapse_workspace" "example" {
  name                                 = "${var.prefix}-ws"
  resource_group_name                  = azurerm_resource_group.example.name
  location                             = azurerm_resource_group.example.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.example.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = var.sql_administrator_login_password
  managed_virtual_network_enabled      = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_firewall_rule" "example" {
  name                 = "allowAll"
  synapse_workspace_id = azurerm_synapse_workspace.example.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

resource "azurerm_synapse_integration_runtime_azure" "example" {
  name                 = "example98186519845"
  synapse_workspace_id = azurerm_synapse_workspace.example.id
  location             = azurerm_resource_group.example.location
}


resource "azurerm_synapse_linked_service" "example" {
  name                 = "example98186519845"
  synapse_workspace_id = azurerm_synapse_workspace.example.id
  type                 = "AzureSqlDatabase"
  # SecretName needs to match the secret placed in the Key Vault
  type_properties_json = <<JSON
{
    "server": "db-apps-dev.database.windows.net",
    "database": "dbOfInterest",
    "encrypt": "mandatory",
    "trustServerCertificate": false,
    "authenticationType": "SystemAssignedManagedIdentity"}
JSON

  depends_on = [
    azurerm_synapse_firewall_rule.example,
  ]
}
