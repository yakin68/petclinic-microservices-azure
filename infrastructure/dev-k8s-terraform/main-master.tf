resource "azurerm_linux_virtual_machine" "kube-master" {
  name                  = "kube-master"
  location              = azurerm_resource_group.kube.location
  resource_group_name   = azurerm_resource_group.kube.name
  network_interface_ids = [azurerm_network_interface.kube-master-nic.id]
  size                  = var.instance_type # Sanal makine boyutunu Terraform değişkenine bağlı olarak kullanın
  admin_username        = "azureuser"

  identity {
    type = "SystemAssigned" # sistem tarafından oluşturulur ve vw silinince silinir.
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/petclinic-nightly/azurkeytest.pub") # SSH anahtarınızın dosya yolunu güncelleyin
  }
/home/azureuser/petclinic-microservices-azure/infrastructure/dev-k8s-terraform
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
    Name        = "kube-master"
    Project     = "tera-kube-ans"
    Role        = "master"
    Id          = "1"
    environment = "dev"
  }
}

resource "azurerm_role_definition" "proje_kube_full_access_role" {
  name        = "VM-FullAccessRole"
  description = "IAM role for full access to all resources"
  scope       = "/subscriptions/88bbc84a-2800-40f2-b985-be5418274086"
  permissions {
    actions     = ["*"]
    not_actions = []
  }
  assignable_scopes = ["/subscriptions/88bbc84a-2800-40f2-b985-be5418274086"]
}

resource "azurerm_role_assignment" "proje_kube_full_access_assignment" {
  principal_id         = azurerm_linux_virtual_machine.kube-master.identity[0].principal_id
  role_definition_name = azurerm_role_definition.proje_kube_full_access_role.name
  scope                = "/subscriptions/88bbc84a-2800-40f2-b985-be5418274086"

}

resource "azurerm_network_interface" "kube-master-nic" {
  name                = "kube-master"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  ip_configuration {
    name                          = "internal-kube-master"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.kube-master-public-ip.id
  }
}

resource "azurerm_public_ip" "kube-master-public-ip" {
  name                    = "public_ip-kube-master"
  location                = azurerm_resource_group.kube.location
  resource_group_name     = azurerm_resource_group.kube.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}
