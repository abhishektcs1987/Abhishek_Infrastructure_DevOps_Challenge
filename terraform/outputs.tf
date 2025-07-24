# outputs.tf - Output Values

output "website_url" {
  description = "URL of the deployed website"
  value       = "https://${azurerm_cdn_endpoint.main.fqdn}"
}

output "static_website_url" {
  description = "Direct URL of the static website (without CDN)"
  value       = "https://${azurerm_storage_account.main.primary_web_host}"
  sensitive   = false
}

output "cdn_endpoint_url" {
  description = "CDN endpoint URL"
  value       = "https://${azurerm_cdn_endpoint.main.fqdn}"
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
  value       = azurerm_cdn_frontdoor_firewall_policy.main.name
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "https://${azurerm_cdn_endpoint.main.fqdn}/health"
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    website_url        = "https://${azurerm_cdn_endpoint.main.fqdn}"
    resource_group     = azurerm_resource_group.main.name
    location           = azurerm_resource_group.main.location
    storage_account    = azurerm_storage_account.main.name
    cdn_endpoint       = azurerm_cdn_endpoint.main.name
    monitoring_enabled = true
    waf_enabled        = var.enable_waf
    https_only         = true
  }
}