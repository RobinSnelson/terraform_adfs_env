data "azurerm_key_vault" "key_vault" {
  name                = "azrgskv"
  resource_group_name = "RGSAZPerm"
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "adfsadminpass"
  key_vault_id = data.azurerm_key_vault.key_vault.id

}