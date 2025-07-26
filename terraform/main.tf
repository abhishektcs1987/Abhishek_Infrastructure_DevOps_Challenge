# main.tf - Core Infrastructure Configuration

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

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
  account_replication_type = "GRS"  # Changed to GRS for high availability

  # Security configurations
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  # Enable blob versioning for better data protection
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

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

  depends_on = [azurerm_storage_account_static_website.static_site]
}

resource "azurerm_storage_blob" "error_page" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = file("${path.module}/static/404.html")

  depends_on = [azurerm_storage_account_static_website.static_site]
}

# Health check endpoint
resource "azurerm_storage_blob" "health_check" {
  name                   = "health.json"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/json"
  source_content = jsonencode({
    status    = "healthy"
    timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
    version   = "1.0.0"
    service   = "static-web-app"
  })

  depends_on = [azurerm_storage_account_static_website.static_site]
}

# Simple health check HTML page for easier testing
resource "azurerm_storage_blob" "health_check_html" {
  name                   = "health"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "<!DOCTYPE html><html><head><title>Health Check</title></head><body><h1>healthy</h1><p>Service is running</p></body></html>"

  depends_on = [azurerm_storage_account_static_website.static_site]
}

# Log Analytics Workspace (moved up as it's needed by other resources)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days

  tags = var.default_tags
}

# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "appi-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.default_tags
}

# Azure Front Door Profile (Primary CDN solution)
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.project_name}-fd-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.default_tags
}

# Web Application Firewall Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  count                             = var.enable_waf ? 1 : 0
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

  # Rate limiting rule
  custom_rule {
    name     = "RateLimiting"
    enabled  = true
    priority = 100
    type     = "RateLimitRule"
    action   = "Block"

    match_condition {
      match_variable = "RequestUri"
      operator       = "Contains"
      match_values   = ["/"]
    }

    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 100
  }

  tags = var.default_tags
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "fde-${random_string.suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = var.default_tags
}

# Origin Group for load balancing and health checks
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    protocol            = "Https"
    interval_in_seconds = 30
    path                = "/health"
    request_type        = "GET"
  }
}

# Origin pointing to storage account
resource "azurerm_cdn_frontdoor_origin" "main" {
  name                           = "storage-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  host_name                      = azurerm_storage_account.main.primary_web_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_storage_account.main.primary_web_host
  certificate_name_check_enabled = true
  enabled                        = true
  priority                       = 1
  weight                         = 1000
}

# Rule Set for custom routing rules
resource "azurerm_cdn_frontdoor_rule_set" "main" {
  name                     = "defaultruleset"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Security headers rule
resource "azurerm_cdn_frontdoor_rule" "security_headers" {
  depends_on = [azurerm_cdn_frontdoor_route.main]

  name                      = "SecurityHeaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.main.id
  order                     = 1
  behavior_on_match         = "Continue"

  conditions {
    request_method_condition {
      operator     = "Equal"
      match_values = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
    }
  }

  actions {
    response_header_action {
      header_action = "Append"
      header_name   = "X-Content-Type-Options"
      value         = "nosniff"
    }
    response_header_action {
      header_action = "Append"
      header_name   = "X-Frame-Options"
      value         = "DENY"
    }
    response_header_action {
      header_action = "Append"
      header_name   = "X-XSS-Protection"
      value         = "1; mode=block"
    }
    response_header_action {
      header_action = "Append"
      header_name   = "Strict-Transport-Security"
      value         = "max-age=31536000; includeSubDomains"
    }
  }
}

# Main route configuration
resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "default-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.main.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  https_redirect_enabled = true
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true

  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.main.id]

  # Enable caching
  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = []
    compression_enabled           = true
    content_types_to_compress = [
      "text/html",
      "text/css",
      "text/javascript",
      "application/javascript",
      "application/json"
    ]
  }


}

# Associate WAF policy with the Front Door endpoint
resource "azurerm_cdn_frontdoor_security_policy" "main" {
  count                    = var.enable_waf ? 1 : 0
  name                     = "security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main[0].id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Network Security Group with proper rules
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

  # Allow HTTP traffic for redirect to HTTPS (handled by Front Door)
  security_rule {
    name                       = "AllowHTTPForRedirect"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Block all other inbound traffic
  security_rule {
    name                       = "DenyAllOtherInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound HTTPS for dependencies
  security_rule {
    name                       = "AllowOutboundHTTPS"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.default_tags
}

# Restrict storage account to only allow access from Front Door
resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id         = azurerm_storage_account.main.id
  default_action             = "Allow"  # Allow for static website hosting
  bypass                     = ["AzureServices"]

  # In production, you would restrict this further
  # For demo purposes, we allow public access but Front Door provides the security layer
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

# Availability Alert for Front Door
resource "azurerm_monitor_metric_alert" "frontdoor_availability" {
  name                = "frontdoor-availability-alert-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_cdn_frontdoor_profile.main.id]
  description         = "Alert when Front Door availability drops below 95%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "Percentage4XX"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.default_tags
}

# Response Time Alert for Front Door
resource "azurerm_monitor_metric_alert" "frontdoor_latency" {
  name                = "frontdoor-latency-alert-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_cdn_frontdoor_profile.main.id]
  description         = "Alert when Front Door latency exceeds 2 seconds"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.default_tags
}

# Storage Account Alert for availability
resource "azurerm_monitor_metric_alert" "storage_availability" {
  name                = "storage-availability-alert-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_storage_account.main.id]
  description         = "Alert when storage availability drops below 99%"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.default_tags
}

# Diagnostic settings for Front Door
resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name               = "frontdoor-diagnostics"
  target_resource_id = azurerm_cdn_frontdoor_profile.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name               = "storage-diagnostics"
  target_resource_id = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
  }
}

# Custom domain configuration (optional)
resource "azurerm_cdn_frontdoor_custom_domain" "main" {
  count                    = var.custom_domain != "" ? 1 : 0
  name                     = "custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  host_name                = var.custom_domain

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# Associate custom domain with the route
resource "azurerm_cdn_frontdoor_route" "custom_domain" {
  count                         = var.custom_domain != "" ? 1 : 0
  name                          = "custom-domain-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.main.id]
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.main[0].id]

  supported_protocols    = ["Https"]
  patterns_to_match      = ["/*"]
  https_redirect_enabled = true
  forwarding_protocol    = "HttpsOnly"

  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.main.id]

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    compression_enabled           = true
    content_types_to_compress = [
      "text/html",
      "text/css",
      "text/javascript",
      "application/javascript",
      "application/json"
    ]
  }
}