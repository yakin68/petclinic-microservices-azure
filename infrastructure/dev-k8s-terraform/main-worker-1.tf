resource "azurerm_linux_virtual_machine" "worker-1" {
  name                  = "worker-1"
  location              = azurerm_resource_group.kube.location
  resource_group_name   = azurerm_resource_group.kube.name
  network_interface_ids = [azurerm_network_interface.worker-1-nic.id]
  size                  = var.instance_type # Sanal makine boyutunu Terraform değişkenine bağlı olarak kullanın
  admin_username        = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./azurkeytest.pub") # SSH anahtarınızın dosya yolunu güncelleyin
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS"
    version   = "latest"
  }

  disable_password_authentication = true

  tags = {
    Name        = "worker-1"
    Project     = "tera-kube-ans"
    Role        = "master"
    Id          = "1"
    environment = "dev"
  }
}

resource "azurerm_network_interface" "worker-1-nic" {
  name                = "worker-1"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  ip_configuration {
    name                          = "internal-worker-1"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker-1-public-ip.id
  }
}

resource "azurerm_public_ip" "worker-1-public-ip" {
  name                    = "public_ip-worker-1"
  location                = azurerm_resource_group.kube.location
  resource_group_name     = azurerm_resource_group.kube.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}
