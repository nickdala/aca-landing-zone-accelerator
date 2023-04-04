data "azurerm_virtual_network" "vnet" {
  name                = var.vnetName
  resource_group_name = var.vnetResourceGroupName
}

module "nsg" {
  source            = "../networking/nsg"
  nsgName           = var.bastionNsgName
  location          = data.azurerm_virtual_network.vnet.location
  resourceGroupName = data.azurerm_virtual_network.vnet.resource_group_name
  securityRules     = var.securityRules
  tags              = []
}

resource "azurerm_subnet" "bastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = var.addressPrefixes
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  depends_on = [
    module.nsg,
    azurerm_subnet.bastionSubnet
  ]
  subnet_id                 = azurerm_subnet.bastionSubnet.id
  network_security_group_id = module.nsg.nsgId
}

resource "azurerm_public_ip" "bastionPip" {
  name                = var.bastionPipName
  location            = data.azurerm_virtual_network.vnet.location
  resource_group_name = data.azurerm_virtual_network.vnet.resource_group_name

  sku      = "Standard"
  sku_tier = "Regional"

  allocation_method = "Static"

  tags = var.tags
}

resource "azurerm_bastion_host" "bastionHost" {
  depends_on = [
    azurerm_public_ip.bastionPip,
    azurerm_subnet.bastionSubnet
  ]
  name                = var.bastionHostName
  location            = data.azurerm_virtual_network.vnet.location
  resource_group_name = data.azurerm_virtual_network.vnet.resource_group_name

  ip_configuration {
    name                 = "ipconf"
    subnet_id            = azurerm_subnet.bastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastionPip.id
  }
}


