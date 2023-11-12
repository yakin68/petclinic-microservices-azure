resource "azurerm_resource_group" "kube" {
  name     = "project-kube-claster-worker"
  location = var.region # Azure bölgesini Terraform değişkenine bağlı olarak kullanın
}

resource "azurerm_network_security_group" "petclinic-mutual-sg" {
  name                = "sec-gr-mutual-ports"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  security_rule {
    name                       = "udp"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "8472"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowMutualPorts"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["2379", "2380", "10250"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "petclinic-kube-worker-sg" {
  name                = "sec-gr-k8s-worker"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWorkerCustomPorts"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["30000-32767"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "kube-worker-secgroup"
  }
}

resource "azurerm_network_security_group" "petclinic-kube-master-sg" {
  name                = "sec-gr-k8s-master"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMasterCustomPorts"
    priority                   = 1060
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6443", "10257", "10259", "30000-32767"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "kube-master-secgroup"
  }
}

resource "azurerm_virtual_network" "dev" {
  name                = "dev-vnet"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "dev" {
  name                 = "dev-subnet"
  resource_group_name  = azurerm_resource_group.kube.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.10.1.0/24"]
}

