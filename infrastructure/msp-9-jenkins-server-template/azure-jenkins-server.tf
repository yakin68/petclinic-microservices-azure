# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "dev" {
  name     = "Azure-jenkins-server-project"
  location = var.region # Azure bölgesini Terraform değişkenine bağlı olarak kullanın
}

resource "azurerm_network_security_group" "dev-server-nsg" {
  name                = "azure-proje-sg"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  # security_rule {
  #   name                       = "SSH"
  #   priority                   = 1001
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  dynamic "security_rule" {
    for_each = var.dev-server-ports
    content {
      name                       = "CustomRule${security_rule.key}"
      priority                   = 1000 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_virtual_network" "dev" {
  name                = "dev-vnet"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "dev" {
  name                 = "dev-subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "dev-server-nic" {
  name                = "dev-server-nic"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "dev-server" {
  name                  = "Azure-Development-Server"
  location              = azurerm_resource_group.dev.location
  resource_group_name   = azurerm_resource_group.dev.name
  network_interface_ids = [azurerm_network_interface.dev-server-nic.id]
  size                  = var.instance_type # Sanal makine boyutunu Terraform değişkenine bağlı olarak kullanın
  admin_username        = "azureuser"
  identity {
    type = "SystemAssigned" # sistem tarafından oluşturulur ve vw silinince silinir.
  }
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azurkey.pub") # SSH anahtarınızın dosya yolunu güncelleyin
  }
  # dizin yolunu değiştirin.
  custom_data = base64encode(file("/home/yakin/Desktop/Myrepo/azure/505-microservices-ci-cd-pipeline/msp-9-jenkins-server-template/jenkinsdata.sh"))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS"
    version   = "latest"
  }

  disable_password_authentication = true
}

resource "azurerm_public_ip" "example" {
  name                    = "public_ip"
  location                = azurerm_resource_group.dev.location
  resource_group_name     = azurerm_resource_group.dev.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_role_definition" "full_access_role" {
  name        = "FullAccessRole"
  description = "IAM role for full access to all resources"
  scope       = "/subscriptions/88bbc84a-2800-40f2-b985-be5418274086"
  permissions {
    actions     = ["*"]
    not_actions = []
  }
  assignable_scopes = ["/subscriptions/88bbc84a-2800-40f2-b985-be5418274086"]
}

resource "azurerm_role_assignment" "full_access_assignment" {
  principal_id         = azurerm_linux_virtual_machine.dev-server.identity[0].principal_id
  role_definition_name = azurerm_role_definition.full_access_role.name
  scope                = "/subscriptions/88bbc84a-2800-40f2-b985-be5418274086"
}


output "public_ip_address" {
  value = azurerm_public_ip.example.ip_address
}
output "JenkinsDNS" {
  value = azurerm_linux_virtual_machine.dev-server.public_ip_address
}
output "JenkinsURL" {
  value = "http://${azurerm_linux_virtual_machine.dev-server.public_ip_address}:8080"
}
