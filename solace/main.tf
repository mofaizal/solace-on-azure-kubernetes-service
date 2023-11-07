resource "random_id" "prefix" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 1 : 0

  location = var.location
  name     = coalesce(var.resource_group_name, "${random_id.prefix.hex}-rg")
}

locals {
  resource_group = {
    name     = var.create_resource_group ? azurerm_resource_group.main[0].name : var.resource_group_name
    location = var.location
  }
}

resource "azurerm_virtual_network" "test" {
  address_space       = ["10.52.0.0/16"]
  location            = local.resource_group.location
  name                = "${random_id.prefix.hex}-vn"
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "test" {
  address_prefixes                               = ["10.52.0.0/24"]
  name                                           = "${random_id.prefix.hex}-sn"
  resource_group_name                            = local.resource_group.name
  virtual_network_name                           = azurerm_virtual_network.test.name
 // enforce_private_link_endpoint_network_policies = true
}

locals {
#   nodes = {
#     for i in range(3) : "worker${i}" => {
#       name           = substr("worker${i}${random_id.prefix.hex}", 0, 8)
      
#       vm_size        = "Standard_D2s_v3"
#       node_count     = 3
#       vnet_subnet_id = azurerm_subnet.test.id
#       zone          = i > 3 ? 3 : i
#     }
#   }

  nodes = {
    for i in range(1, 4) : "worker${i}" => {
      name = i == 1 ? "primary" : i == 2 ? "backup" : i == 3 ? "monitor" : "default"
      vm_size        = "Standard_E4s_v3"
      node_count     = 2
      vnet_subnet_id = azurerm_subnet.test.id
      zones          = i == 0 ? ["1"] : i == 1 ? ["2"] : i == 2 ? ["3"] : ["1"]
    }
  }

}

module "aks" {
#   source = "../.."
 source = "/home/faizal/solace-on-azure-kubernetes-service"
depends_on = [ azurerm_resource_group.main, azurerm_subnet.test, azurerm_virtual_network.test ]
  prefix                        = "prefix-${random_id.prefix.hex}"
  resource_group_name           = local.resource_group.name
  os_disk_size_gb               = 60
  public_network_access_enabled = false
  sku_tier                      = "Standard"
  rbac_aad                      = false
  vnet_subnet_id                = azurerm_subnet.test.id
  agents_availability_zones = ["1", "2", "3"]
  node_pools                    = local.nodes
#   kubernetes_version            = "1.26.0"
}

# # Enable the Kubernetes provider
# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# # Install Helm to manage Kubernetes applications
# resource "null_resource" "install_helm" {
#   provisioner "local-exec" {
#     command = "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3"
#   }

#   provisioner "local-exec" {
#     command = "chmod 700 get_helm.sh"
#   }

#   provisioner "local-exec" {
#     command = "./get_helm.sh"
#   }

# depends_on = [ module.aks ]
# }

# # Deploy Solace PubSub+ using Helm
# resource "null_resource" "deploy_solace" {
#   provisioner "local-exec" {
#     command = "helm repo add solacecharts https://solaceproducts.github.io/pubsubplus-kubernetes-helm-quickstart/helm-charts"
#   }

#   provisioner "local-exec" {
#     command = "helm repo update solacecharts"
#   }

#   provisioner "local-exec" {
#     command = "helm install my-release solacecharts/pubsubplus"
#   }

#   depends_on = [null_resource.install_helm]
# }