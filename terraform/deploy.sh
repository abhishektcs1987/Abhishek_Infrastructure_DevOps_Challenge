#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ $message${NC}"
        exit 1
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${BLUE}ℹ️  $message${NC}"
    fi
}

print_status "INFO" "Starting Azure Static Web App deployment..."

# Check prerequisites
print_status "INFO" "Checking prerequisites..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_status "FAIL" "Azure CLI is not installed. Please install it first."
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_status "FAIL" "Terraform is not installed. Please install it first."
fi

# Check if user is logged into Azure
if ! az account show &> /dev/null; then
    print_status "WARN" "Not logged into Azure. Please run 'az login' first."
    print_status "INFO" "Running az login..."
    az login
fi

print_status "PASS" "Prerequisites check completed"

# Show current Azure subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
print_status "INFO" "Using Azure subscription: $SUBSCRIPTION_NAME"

# Initialize Terraform
print_status "INFO" "Initializing Terraform..."
if terraform init; then
    print_status "PASS" "Terraform initialized successfully"
else
    print_status "FAIL" "Terraform initialization failed"
fi

# Format Terraform files
print_status "INFO" "Formatting Terraform files..."
terraform fmt

# Validate configuration
print_status "INFO" "Validating Terraform configuration..."
if terraform validate; then
    print_status "PASS" "Terraform configuration is valid"
else
    print_status "FAIL" "Terraform configuration validation failed"
fi

# Create and review plan
print_status "INFO" "Creating deployment plan..."
if terraform plan -out=tfplan.out; then
    print_status "PASS" "Terraform plan created successfully"
else
    print_status "FAIL" "Terraform plan creation failed"
fi

# Ask for confirmation before applying
print_status "INFO" "Ready to deploy infrastructure to Azure"
print_status "WARN" "This will create billable resources in your Azure subscription"
echo "Do you want to proceed with the deployment? (yes/no)"
read -r response

if [ "$response" != "yes" ]; then
    print_status "INFO" "Deployment cancelled by user"
    exit 0
fi

# Apply the plan
print_status "INFO" "Deploying infrastructure to Azure..."
if terraform apply tfplan.out; then
    print_status "PASS" "Infrastructure deployed successfully!"
else
    print_status "FAIL" "Infrastructure deployment failed"
fi

# Show deployment summary
print_status "INFO" "Deployment Summary:"
echo "==========================================="
terraform output deployment_summary
echo "==========================================="

# Get the website URL
WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")
if [ -n "$WEBSITE_URL" ]; then
    print_status "INFO" "Your website is available at: $WEBSITE_URL"
fi

# Run tests
print_status "INFO" "Running post-deployment tests..."
if [ -f "web_test.sh" ]; then
    chmod +x web_test.sh
    if ./web_test.sh; then
        print_status "PASS" "All tests passed successfully!"
    else
        print_status "WARN" "Some tests failed. Check the output above."
    fi
else
    print_status "WARN" "Test script not found. Skipping tests."
fi

# Final instructions
print_status "INFO" "Deployment completed!"
echo ""
echo "Next steps:"
echo "1. Visit your website: ${WEBSITE_URL:-'Check terraform output website_url'}"
echo "2. Monitor your application in Azure Portal"
echo "3. Review monitoring and alerts in Application Insights"
echo ""
echo "To update the website content:"
echo "1. Edit files in the static/ directory"
echo "2. Run: terraform apply"
echo ""
echo "To destroy the infrastructure:"
echo "1. Run: terraform destroy"

print_status "PASS" "Deployment script completed successfully!"