resource "azurerm_public_ip" "natip" {
  name                = "natip-${var.suffix}"
  location            = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_nat_gateway" "natgw" {
  name                = "ng-${var.suffix}"
  location            = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "natgwpip" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.natip.id
}
resource "azurerm_subnet_nat_gateway_association" "natgwsubnet" {
  subnet_id      = azurerm_subnet.webappsubnet.id
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}