# variables.tf - Input Variables

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = "admin@fmc.com"
}

variable "custom_domain" {
  description = "Custom domain name (optional)"
  type        = string
  default     = "pdx-fmc.test.com"
}

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
  default     = "staticwebhosting"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters and numbers."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "East US"

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "West Central US", "Canada Central", "Canada East",
      "Brazil South", "North Europe", "West Europe", "UK South",
      "UK West", "France Central", "Germany West Central",
      "Norway East", "Switzerland North", "Sweden Central",
      "Australia East", "Australia Southeast", "East Asia",
      "Southeast Asia", "Japan East", "Japan West", "Korea Central",
      "Korea South", "India Central", "India South", "India West"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "staticwebhosting"
    ManagedBy   = "abhishekchatterjeex87@gmail.com"
    Owner       = "Abhishek"
    CostCenter  = "Engineering"
  }
}

variable "cdn_locations" {
  description = "CDN edge locations for content distribution"
  type        = list(string)
  default = [
    "North America",
    "Europe",
    "Asia Pacific"
  ]
}

variable "retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 7 && var.retention_days <= 730
    error_message = "Retention days must be between 7 and 730."
  }
}

variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = true
}