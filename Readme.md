# Static Web Application on Azure

This Terraform configuration deploys a secure, scalable static web application on Microsoft Azure with comprehensive monitoring, security, and high availability features.

## 🏗️ Architecture Overview

- **Azure Storage Account**: Hosts static website content
- **Azure Front Door**: Global CDN with SSL termination and WAF protection
- **Web Application Firewall (WAF)**: Protects against common web attacks
- **Application Insights**: Application monitoring and analytics
- **Log Analytics**: Centralized logging and monitoring
- **Network Security Groups**: Network-level security controls
- **Automated Alerts**: Email notifications for issues

## ✅ Requirements Met

- ✅ **Static Web Application**: Serves HTML content via Azure Storage
- ✅ **Infrastructure as Code**: Complete Terraform configuration
- ✅ **HTTPS Enforcement**: HTTP automatically redirects to HTTPS
- ✅ **SSL/TLS Certificates**: Azure-managed certificates with TLS 1.2+
- ✅ **Security**: Network restrictions, WAF, security headers
- ✅ **High Availability**: Global CDN, GRS storage replication
- ✅ **Auto-scaling**: Inherent Azure platform scaling
- ✅ **Monitoring**: Application Insights, Log Analytics, alerts
- ✅ **Automated Testing**: Comprehensive test script

## 📋 Prerequisites

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **Azure Subscription** with appropriate permissions
4. **Bash shell** for running test scripts

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd static-web-azure

# Login to Azure
az login

# Set your subscription (optional)
az account set --subscription "your-subscription-id"
```

### 2. Configure Variables

Edit `terraform.tfvars` (create if doesn't exist):

```hcl
# Required variables
alert_email = "your-email@domain.com"
project_name = "mywebapp"
location = "East US"

# Optional variables
custom_domain = "www.yourdomain.com"  # Leave empty if no custom domain
enable_waf = true
environment = "prod"
retention_days = 30
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Run Tests

```bash
# Make the test script executable
chmod +x web_test.sh

# Run comprehensive tests
./web_test.sh
```

## 📁 Project Structure

```
├── main.tf                 # Main infrastructure configuration
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── versions.tf            # Provider versions
├── web_test.sh            # Automated test script
├── static/
│   ├── index.html         # Main webpage
│   └── 404.html          # Error page
└── README.md             # This file
```

## 🔧 Configuration Options

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `alert_email` | Email for alerts | admin@fmc.com | Yes |
| `project_name` | Project name | staticwebhosting | No |
| `location` | Azure region | East US | No |
| `custom_domain` | Custom domain | "" | No |
| `enable_waf` | Enable WAF | true | No |
| `environment` | Environment | prod | No |
| `retention_days` | Log retention | 30 | No |

### Custom Domain Setup

To use a custom domain:

1. Set `custom_domain` variable to your domain
2. Deploy the infrastructure
3. Create a CNAME record pointing to the Front Door endpoint
4. Azure will automatically provision SSL certificate

## 🔍 Monitoring and Alerts

### Built-in Monitoring

- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging
- **Health Checks**: Automated endpoint monitoring
- **Metric Alerts**: Availability and performance alerts

### Alert Conditions

- Front Door availability < 95%
- Response time > 2 seconds
- Storage availability < 99%
- High error rates (4xx/5xx responses)

### Accessing Logs

```bash
# View deployment outputs
terraform output

# Access monitoring URLs
terraform output monitoring_urls
```

## 🛡️ Security Features

### Network Security
- HTTPS enforcement (HTTP → HTTPS redirect)
- TLS 1.2+ only
- Network Security Groups with restrictive rules

### Web Application Firewall
- Microsoft Default Rule Set (OWASP Core Rules)
- Bot protection
- Rate limiting (100 requests/minute)
- Custom blocking rules

### Security Headers
- Strict-Transport-Security (HSTS)
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block

## 🧪 Testing

### Automated Tests

The `web_test.sh` script performs comprehensive testing:

- Terraform validation
- HTTPS enforcement
- SSL certificate validation
- Security headers check
- Content delivery
- Health check endpoints
- Performance testing
- WAF functionality
- Infrastructure validation

### Manual Testing

```bash
# Test the website
curl -I https://your-endpoint.azurefd.net

# Test health check
curl https://your-endpoint.azurefd.net/health

# Test WAF (should be blocked)
curl "https://your-endpoint.azurefd.net/?id=1' OR '1'='1"
```

## 🔄 Maintenance

### Updates

```bash
# Update Terraform configuration
terraform plan
terraform apply

# Update static content
# Edit files in static/ directory, then:
terraform apply
```

### Monitoring

```bash
# Check resource status
az resource list --resource-group $(terraform output -raw resource_group_name)

# View Front Door metrics
az monitor metrics list --resource $(terraform output -raw frontdoor_profile_name)
```

## 🗑️ Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm destruction
# Type 'yes' when prompted
```

## 📊 Cost Optimization

- **Storage**: Standard LRS for cost efficiency
- **Front Door**: Standard tier for basic features
- **Logs**: 30-day retention (configurable)
- **Alerts**: Email-only notifications

## 🆘 Troubleshooting

### Common Issues

1. **Custom Domain SSL Issues**
    - Ensure CNAME record is properly configured
    - Allow up to 24 hours for SSL certificate provisioning

2. **WAF Blocking Legitimate Traffic**
    - Review WAF logs in Log Analytics
    - Adjust rules or create exceptions

3. **Health Check Failures**
    - Verify storage account static website is enabled
    - Check network security group rules

### Getting Help

1. Check Terraform plan output for errors
2. Review Azure Portal for resource status
3. Run the test script for detailed diagnostics
4. Check Application Insights for application errors

## 📈 Performance Characteristics

- **Global CDN**: Sub-second response times worldwide
- **High Availability**: 99.99% uptime SLA
- **Auto-scaling**: Handles traffic spikes automatically
- **Security**: Enterprise-grade protection

## 🔗 Useful Links

- [Azure Front Door Documentation](https://docs.microsoft.com/azure/frontdoor/)
- [Azure Storage Static Websites](https://docs.microsoft.com/azure/storage/blobs/storage-blob-static-website)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)

---

## 📝 Notes

- This configuration is production-ready with security best practices
- All resources include proper tagging for cost management
- Monitoring and alerting are configured for operational excellence
- The infrastructure follows Azure Well-Architected Framework principles