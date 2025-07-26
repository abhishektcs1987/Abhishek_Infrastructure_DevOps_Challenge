# Static Web Application on Azure

This Terraform configuration deploys a secure, scalable static web application on Microsoft Azure with comprehensive monitoring, security, and high availability features.

## 🏗️ Architecture Overview

- **Azure Storage Account**: Hosts static website content with GRS replication
- **Azure Front Door**: Global CDN with SSL termination and WAF protection
- **Web Application Firewall (WAF)**: Protects against common web attacks and bot traffic
- **Application Insights**: Application monitoring and analytics
- **Log Analytics**: Centralized logging and monitoring
- **Network Security Groups**: Network-level security controls
- **Automated Alerts**: Email notifications for availability and performance issues
- **Health Check Endpoints**: Both HTML and JSON endpoints for monitoring

## ✅ Requirements Met

- ✅ **Static Web Application**: Serves HTML content via Azure Storage with global CDN
- ✅ **Infrastructure as Code**: Complete Terraform configuration with modular design
- ✅ **HTTPS Enforcement**: HTTP automatically redirects to HTTPS with security headers
- ✅ **SSL/TLS Certificates**: Azure-managed certificates with TLS 1.2+ minimum
- ✅ **Security**: WAF protection, network restrictions, security headers, rate limiting
- ✅ **High Availability**: Global CDN, GRS storage replication, health checks
- ✅ **Auto-scaling**: Inherent Azure platform scaling with Front Door load balancing
- ✅ **Monitoring**: Application Insights, Log Analytics, metric alerts, diagnostic logging
- ✅ **Automated Testing**: Comprehensive test script with 14 different test categories

## 📋 Prerequisites

1. **Azure CLI** installed and configured (`az --version`)
2. **Terraform** >= 1.0 installed (`terraform --version`)
3. **Azure Subscription** with Contributor or Owner permissions
4. **Bash shell** for running deployment and test scripts
5. **curl** and **openssl** for testing (usually pre-installed)

## 🚀 Quick Start

### **Option 1: Automated Deployment (Recommended)**

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the automated deployment
./deploy.sh
```

The automated script handles everything:
- Prerequisites checking
- Azure login verification
- Configuration file creation
- Infrastructure deployment
- Post-deployment testing

### **Option 2: Manual Deployment**

#### 1. **Setup Configuration**

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
nano terraform.tfvars
```

#### 2. **Deploy Infrastructure**

```bash
# Login to Azure (if not already logged in)
az login

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

#### 3. **Run Tests**

```bash
# Make test script executable
chmod +x web_test.sh

# Run comprehensive tests
./web_test.sh
```

## 📁 Project Structure

```
├── main.tf                      # Main infrastructure configuration
├── variables.tf                 # Input variables with validation
├── outputs.tf                   # Output values and monitoring URLs
├── versions.tf                  # Provider versions and backend config
├── deploy.sh                    # Automated deployment script
├── web_test.sh                  # Comprehensive test script
├── static/
│   ├── index.html              # Main webpage (Hello World)
│   └── 404.html                # Custom error page
└── README.md                   # This documentation
```

## 🔧 Configuration Options

### Required Variables

| Variable | Description | Example | Notes |
|----------|-------------|---------|-------|
| `alert_email` | Email for monitoring alerts | `admin@company.com` | Must be valid email address |

### Optional Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `project_name` | Project identifier | `staticwebhosting` | Lowercase letters/numbers only |
| `location` | Azure region | `East US` | Any valid Azure region |
| `custom_domain` | Custom domain name | `""` | Leave empty to disable |
| `enable_waf` | Enable Web Application Firewall | `true` | true/false |
| `environment` | Environment type | `prod` | dev/staging/prod |
| `retention_days` | Log retention period | `30` | 7-730 days |
| `health_check_interval` | Health check frequency | `30` | 30-300 seconds |
| `cache_duration` | Content cache duration | `24` | 1-8760 hours |

### Example terraform.tfvars

```hcl
# Required
alert_email = "admin@yourcompany.com"

# Basic Configuration
project_name = "mywebapp"
location = "East US"
environment = "prod"

# Security & Performance
enable_waf = true
retention_days = 30
health_check_interval = 30
cache_duration = 24

# Custom Domain (optional)
custom_domain = "www.yourdomain.com"  # or "" to disable

# Custom Tags (optional)
default_tags = {
  Environment = "production"
  Project     = "static-web-app"
  Owner       = "Platform Team"
  CostCenter  = "Engineering"
}
```

### Custom Domain Setup

To configure a custom domain:

1. **Set the variable**: Update `custom_domain` in `terraform.tfvars`
2. **Deploy infrastructure**: Run `terraform apply`
3. **Create DNS record**: Add CNAME pointing to Front Door endpoint
4. **Wait for SSL**: Azure automatically provisions SSL certificate (up to 24 hours)

Example DNS configuration:
```
Type: CNAME
Name: www
Value: your-endpoint.azurefd.net
TTL: 300
```

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

## 🧪 Testing & Validation

### Automated Test Suite

The `web_test.sh` script provides comprehensive testing across 14 categories:

#### **Pre-Deployment Tests (Always Run)**
1. **Terraform Validation**: Format checking, syntax validation, plan generation
2. **Configuration Validation**: Variable validation, resource dependencies

#### **Post-Deployment Tests (After `terraform apply`)**
3. **Connectivity Tests**: Basic reachability, response codes
4. **HTTPS Enforcement**: HTTP→HTTPS redirects, SSL certificate validation
5. **Security Headers**: HSTS, XSS protection, content-type options
6. **Content Delivery**: Main page content, 404 error handling
7. **Health Check Endpoints**: Both `/health` (HTML) and `/health.json` endpoints
8. **Performance Tests**: Response time measurement, compression validation
9. **WAF Protection**: Malicious request blocking (if WAF enabled)
10. **Infrastructure Validation**: Resource count, deployment completeness
11. **Monitoring Setup**: Application Insights, Log Analytics workspace
12. **SSL Certificate**: Certificate validity, expiration, chain validation
13. **DNS Resolution**: Domain resolution, CDN endpoint accessibility
14. **Load Balancing**: Origin health, failover capability

### Running Tests

```bash
# Test before deployment (validation only)
./web_test.sh
# Output: ⚠️ Infrastructure not deployed. Skipping live tests.

# Test after deployment (full test suite)
terraform apply
./web_test.sh
# Output: ✅ All tests completed successfully!
```

### Test Report Generation

The test script automatically generates detailed reports:

```bash
# Report saved as: test_report_YYYYMMDD_HHMMSS.txt
cat test_report_20250127_143022.txt
```

### Manual Testing Commands

```bash
# Test website accessibility
curl -I https://your-endpoint.azurefd.net

# Test HTTPS redirect
curl -I http://your-endpoint.azurefd.net

# Test health endpoints
curl https://your-endpoint.azurefd.net/health
curl https://your-endpoint.azurefd.net/health.json

# Test WAF protection (should return 403)
curl "https://your-endpoint.azurefd.net/?id=1' OR '1'='1"

# Test SSL certificate
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 | openssl x509 -noout -dates

# Test response time
curl -o /dev/null -s -w "Response time: %{time_total}s\n" https://your-endpoint.azurefd.net
```

## 🔄 Maintenance & Updates

### Updating Static Content

```bash
# Edit HTML files
nano static/index.html
nano static/404.html

# Deploy changes
terraform apply
# Only the changed files will be updated
```

### Infrastructure Updates

```bash
# Update configuration
nano terraform.tfvars

# Preview changes
terraform plan

# Apply updates
terraform apply
```

### Monitoring and Maintenance

```bash
# Check resource health
az resource list --resource-group $(terraform output -raw resource_group_name) --query "[].{Name:name,Type:type,Location:location}" --output table

# View Front Door metrics
az monitor metrics list \
  --resource $(terraform output -raw frontdoor_profile_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --resource-type "Microsoft.Cdn/profiles"

# Check storage account metrics
az monitor metrics list \
  --resource $(terraform output -raw storage_account_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --resource-type "Microsoft.Storage/storageAccounts"

# Review Application Insights
# Use the monitoring URLs from: terraform output monitoring_urls
```

### Scaling and Performance Optimization

The infrastructure automatically scales, but you can optimize:

```hcl
# In terraform.tfvars
cache_duration = 48              # Increase cache time for better performance
health_check_interval = 60       # Reduce health check frequency if needed
retention_days = 90             # Increase log retention for compliance
```

### Backup and Disaster Recovery

```bash
# Export Terraform state (backup)
terraform state pull > terraform-state-backup.json

# List all resources for documentation
terraform state list > resources.txt

# The infrastructure includes:
# - GRS storage replication (automatic)
# - Global CDN distribution (high availability)
# - Multi-region Front Door (disaster recovery)
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm by typing 'yes'
# This will remove all billable resources
```

### Partial Cleanup

```bash
# Disable WAF to reduce costs
echo 'enable_waf = false' >> terraform.tfvars
terraform apply

# Reduce log retention
echo 'retention_days = 7' >> terraform.tfvars
terraform apply
```

## 📊 Cost Optimization

### Estimated Monthly Costs (East US region)

- **Storage Account (Standard LRS)**: ~$0.02/GB
- **Front Door (Standard)**: ~$22.00 + data transfer
- **Application Insights**: ~$2.30/GB ingested
- **Log Analytics**: ~$2.30/GB ingested
- **WAF Policy**: ~$1.00 + request charges

**Total estimated cost**: $30-50/month for typical small website

### Cost Reduction Tips

```hcl
# In terraform.tfvars - optimize for cost
retention_days = 7           # Minimum log retention
enable_waf = false          # Disable WAF if not needed
cache_duration = 168        # 1 week cache (reduce origin requests)
```

### Monitoring Costs

```bash
# View cost analysis in Azure Portal
az consumption usage list --start-date 2025-01-01 --end-date 2025-01-31
```

## 🆘 Troubleshooting

### Common Issues and Solutions

#### **Deployment Issues**

**Error: "formatdate invalid format"**
```bash
# Fixed in latest version - ensure you have the updated main.tf
terraform validate  # Should pass without errors
```

**Error: "No outputs found"**
```bash
# This is normal before deployment
terraform apply    # Deploy first
./web_test.sh      # Then run tests
```

**Error: Custom domain SSL certificate issues**
```bash
# Check DNS configuration
nslookup your-domain.com
dig CNAME www.your-domain.com

# Wait up to 24 hours for SSL provisioning
# Check certificate status in Azure Portal
```

**Error: WAF blocking legitimate traffic**
```bash
# Review WAF logs
az monitor log-analytics query \
  --workspace $(terraform output -raw log_analytics_workspace_id) \
  --analytics-query "AzureDiagnostics | where Category == 'FrontdoorWebApplicationFirewallLog'"

# Adjust WAF rules if needed
# Consider creating exception rules for false positives
```

#### **Performance Issues**

**Slow response times**
```bash
# Check CDN cache hit ratio
# Review Front Door metrics in Azure Portal
# Consider adjusting cache duration in terraform.tfvars
cache_duration = 48  # Increase cache time
```

**Health check failures**
```bash
# Verify health endpoints
curl https://your-endpoint.azurefd.net/health
curl https://your-endpoint.azurefd.net/health.json

# Check storage account static website configuration
az storage blob show \
  --account-name $(terraform output -raw storage_account_name) \
  --container-name '$web' \
  --name 'health'
```

#### **Security Issues**

**Missing security headers**
```bash
# Security headers are applied via Front Door rules
# Check rule configuration in Azure Portal
# Headers may take a few minutes to propagate globally
```

**WAF not blocking attacks**
```bash
# Verify WAF is enabled
terraform output waf_policy_name

# Check WAF policy rules
az network front-door waf-policy show \
  --name $(terraform output -raw waf_policy_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

### Getting Help

1. **Check Terraform validation**: `terraform validate`
2. **Review Azure Portal**: Check resource status and logs
3. **Run diagnostic tests**: `./web_test.sh` for detailed diagnostics
4. **Check Application Insights**: Review application errors and performance
5. **Review test reports**: Generated automatically by test script

### Debug Commands

```bash
# Show all Terraform outputs
terraform output

# Show detailed deployment summary
terraform output deployment_summary

# Show monitoring URLs for Azure Portal
terraform output monitoring_urls

# Check resource group contents
az resource list --resource-group $(terraform output -raw resource_group_name) --output table

# View Front Door configuration
az afd profile show --profile-name $(terraform output -raw frontdoor_profile_name) --resource-group $(terraform output -raw resource_group_name)
```

## 📈 Performance & Security Characteristics

### Performance Metrics

- **Global CDN**: Sub-second response times worldwide via Azure Front Door
- **High Availability**: 99.99% uptime SLA with automatic failover
- **Auto-scaling**: Handles traffic spikes automatically (serverless architecture)
- **Caching**: Configurable cache duration (default 24 hours)
- **Compression**: Automatic gzip compression for text content
- **HTTP/2**: Enabled by default for better performance

### Security Features

#### **Network Security**
- HTTPS enforcement with automatic HTTP→HTTPS redirects
- TLS 1.2+ minimum with Azure-managed certificates
- Network Security Groups with restrictive inbound rules
- Storage account restricted to necessary access only

#### **Web Application Firewall (WAF)**
- Microsoft Default Rule Set (OWASP Core Rules)
- Bot Manager Rule Set for automated threat protection
- Custom rate limiting (100 requests/minute by default)
- Real-time threat intelligence and blocking
- DDoS protection via Azure Front Door

#### **Security Headers**
- `Strict-Transport-Security`: Forces HTTPS for 1 year
- `X-Content-Type-Options: nosniff`: Prevents MIME type sniffing
- `X-Frame-Options: DENY`: Prevents clickjacking attacks
- `X-XSS-Protection: 1; mode=block`: XSS protection for legacy browsers

#### **Data Protection**
- Storage encryption at rest (Microsoft-managed keys)
- Data replication across multiple Azure regions (GRS)
- Blob versioning enabled for accidental deletion protection
- 7-day delete retention policy for recovery

### Monitoring & Observability

#### **Application Insights**
- Real-time application performance monitoring
- User behavior analytics and session tracking
- Dependency tracking and failure analysis
- Custom telemetry and business metrics

#### **Log Analytics**
- Centralized logging for all Azure resources
- Custom queries and dashboards
- Integration with Azure Monitor alerts
- Configurable retention (7-730 days)

#### **Automated Alerts**
- Front Door availability monitoring (< 95% triggers alert)
- Response time alerts (> 2 seconds triggers alert)
- Storage availability monitoring (< 99% triggers alert)
- Custom error rate monitoring (4xx/5xx responses)

#### **Health Monitoring**
- HTML health endpoint at `/health`
- JSON health endpoint at `/health.json` with timestamp
- Automated health probes every 30 seconds (configurable)
- Multi-region health check distribution

### Compliance & Standards

- **Security**: Follows Azure Security Benchmark guidelines
- **Privacy**: No personal data collection by default
- **Availability**: Designed for 99.99% uptime SLA
- **Performance**: Optimized for Core Web Vitals metrics
- **Accessibility**: Semantic HTML structure for screen readers

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