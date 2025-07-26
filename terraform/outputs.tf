# outputs.tf - Output Values

output "website_url" {
  description = "URL of the deployed website (Front Door endpoint)"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

output "frontdoor_endpoint_url" {
  description = "Azure Front Door endpoint URL"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

output "static_website_url" {
  description = "Direct URL of the static website (without CDN)"
  value       = "https://${azurerm_storage_account.main.primary_web_host}"
  sensitive   = false
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "application_insights_app_id" {
  description = "Application Insights Application ID"
  value       = azurerm_application_insights.main.app_id
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "frontdoor_profile_name" {
  description = "Front Door Profile Name"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "waf_policy_name" {
  description = "Web Application Firewall Policy Name"
  value       = var.enable_waf ? azurerm_cdn_frontdoor_firewall_policy.main[0].name : "WAF not enabled"
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}/health"
}

output "health_check_json_url" {
  description = "Health check JSON endpoint URL"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}/health.json"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "No custom domain configured"
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    website_url        = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
    resource_group     = azurerm_resource_group.main.name
    location           = azurerm_resource_group.main.location
    storage_account    = azurerm_storage_account.main.name
    frontdoor_endpoint = azurerm_cdn_frontdoor_endpoint.main.name
    frontdoor_profile  = azurerm_cdn_frontdoor_profile.main.name
    monitoring_enabled = true
    waf_enabled        = var.enable_waf
    https_only         = true
    custom_domain      = var.custom_domain != "" ? var.custom_domain : "Not configured"
  }
}

output "monitoring_urls" {
  description = "URLs for monitoring and management"
  value = {
    azure_portal_rg   = "https://portal.azure.com/#@/resource/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}"
    storage_account   = "https://portal.azure.com/#@/resource${azurerm_storage_account.main.id}"
    frontdoor_profile = "https://portal.azure.com/#@/resource${azurerm_cdn_frontdoor_profile.main.id}"
    log_analytics     = "https://portal.azure.com/#@/resource${azurerm_log_analytics_workspace.main.id}"
  }
}

output "security_info" {
  description = "Security configuration details"
  value = {
    https_enforced     = true
    waf_enabled        = var.enable_waf
    tls_version        = "TLS 1.2+"
    security_headers   = "Enabled via Front Door rules"
    storage_encryption = "Enabled (Microsoft-managed keys)"
  }
}