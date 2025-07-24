# main.tf - Core Infrastructure Configuration

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Generate random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-staticweb-${random_string.suffix.result}"
  location = var.location

  tags = var.default_tags
}

# Storage Account for static website hosting
resource "azurerm_storage_account" "main" {
  name                     = "stweb${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security configurations
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  tags = var.default_tags
}

resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.main.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

# Upload static content
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = file("${path.module}/static/index.html")
}

resource "azurerm_storage_blob" "error_page" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = file("${path.module}/static/404.html")
}

# CDN Profile for global distribution and HTTPS
resource "azurerm_cdn_profile" "main" {
  name                = "cdnprof-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"

  tags = var.default_tags
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "main" {
  name                = "cdnep-${random_string.suffix.result}"
  profile_name        = azurerm_cdn_profile.main.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  origin_host_header = azurerm_storage_account.main.primary_web_host
  origin {
    name      = "primary"
    host_name = azurerm_storage_account.main.primary_web_host
  }

  delivery_rule {
    name  = "httpsRedirect"
    order = 1

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }

  global_delivery_rule {
    cache_expiration_action {
      behavior = "Override"
      duration = "1.00:00:00"
    }

    cache_key_query_string_action {
      behavior = "ExcludeAll"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "StaticWebApp"
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "appi-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = var.default_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.default_tags
}

# Network Security Group for additional security
resource "azurerm_network_security_group" "main" {
  name                = "${var.project_name}-nsg-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS traffic
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Block HTTP traffic (since we're redirecting to HTTPS)
  security_rule {
    name                       = "DenyHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.default_tags
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "webappag"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }

  tags = var.default_tags
}

# Availability Alert
resource "azurerm_monitor_metric_alert" "availability" {
  name                = "availability-alert-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when availability drops below 95%"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.default_tags
}

# Response Time Alert
resource "azurerm_monitor_metric_alert" "response_time" {
  name                = "response-time-alert-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when response time exceeds 5 seconds"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.default_tags
}

# Custom SSL Certificate (Optional - uncomment if you have a custom domain)
resource "azurerm_cdn_endpoint_custom_domain" "main" {
  name            = "custom-domain"
  cdn_endpoint_id = azurerm_cdn_endpoint.main.id
  host_name       = var.custom_domain

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.project_name}-fd-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.default_tags
}

# Web Application Firewall Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                              = "${var.project_name}wafpolicy${random_string.suffix.result}"
  resource_group_name               = azurerm_resource_group.main.name
  sku_name                          = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled                           = true
  mode                              = "Prevention"
  redirect_url                      = "https://www.microsoft.com"
  custom_block_response_status_code = 403
  custom_block_response_body        = base64encode("Access denied by WAF policy")

  # Default rule set for common attacks
  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.0"
    action  = "Block"
  }

  # Bot protection
  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.default_tags
}

# Health check endpoint
resource "azurerm_storage_blob" "health_check" {
  name                   = "health"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/json"
  source_content = jsonencode({
    status    = "healthy"
    timestamp = timestamp()
    version   = "1.0.0"
  })

  depends_on = [azurerm_storage_account_static_website.static_site]
}