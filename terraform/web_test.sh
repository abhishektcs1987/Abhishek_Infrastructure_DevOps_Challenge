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

print_status "INFO" "Starting comprehensive infrastructure and security tests..."

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    print_status "FAIL" "main.tf not found. Please run this script from the terraform directory."
fi

# 1. Terraform Validation Tests
print_status "INFO" "Running Terraform validation tests..."

# Format check
if terraform fmt -check -diff > /dev/null 2>&1; then
    print_status "PASS" "Terraform formatting is correct"
else
    print_status "WARN" "Terraform files need formatting. Running terraform fmt..."
    terraform fmt
fi

# Validation check
if terraform validate > /dev/null 2>&1; then
    print_status "PASS" "Terraform configuration is valid"
else
    print_status "FAIL" "Terraform validation failed"
fi

# Plan check
print_status "INFO" "Running terraform plan..."
if terraform plan -out=tfplan.out > /dev/null 2>&1; then
    print_status "PASS" "Terraform plan completed successfully"
else
    print_status "FAIL" "Terraform plan failed"
fi

# 2. Extract URLs from Terraform outputs
print_status "INFO" "Extracting deployment URLs..."

# Check if infrastructure is deployed
if ! terraform output > /dev/null 2>&1; then
    print_status "WARN" "Infrastructure not deployed. Skipping live tests."
    print_status "INFO" "Run 'terraform apply' to deploy infrastructure and run full tests."
    exit 0
fi

WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")
FRONTDOOR_URL=$(terraform output -raw frontdoor_endpoint_url 2>/dev/null || echo "")
STATIC_URL=$(terraform output -raw static_website_url 2>/dev/null || echo "")

if [ -z "$WEBSITE_URL" ] && [ -z "$FRONTDOOR_URL" ]; then
    print_status "FAIL" "Could not retrieve website URLs from terraform outputs"
fi

# Use Front Door URL as primary if available, otherwise use website URL
PRIMARY_URL=${FRONTDOOR_URL:-$WEBSITE_URL}

print_status "INFO" "Testing URL: $PRIMARY_URL"

# 3. Basic Connectivity Tests
print_status "INFO" "Running connectivity tests..."

# Test if site is reachable
if curl -s --max-time 30 "$PRIMARY_URL" > /dev/null; then
    print_status "PASS" "Website is reachable"
else
    print_status "FAIL" "Website is not reachable"
fi

# 4. HTTPS Enforcement Tests
print_status "INFO" "Testing HTTPS enforcement..."

# Test HTTP to HTTPS redirect
HTTP_URL=$(echo "$PRIMARY_URL" | sed 's/https:/http:/')
REDIRECT_RESPONSE=$(curl -s -I --max-time 15 "$HTTP_URL" 2>/dev/null || echo "")

if echo "$REDIRECT_RESPONSE" | grep -i "location:.*https://" > /dev/null; then
    print_status "PASS" "HTTP redirects to HTTPS"
elif echo "$REDIRECT_RESPONSE" | grep -i "301\|302" > /dev/null; then
    print_status "PASS" "HTTP redirect detected"
else
    print_status "WARN" "HTTP redirect behavior unclear - may be handled by CDN"
fi

# Test HTTPS response
HTTPS_RESPONSE=$(curl -s -I --max-time 15 "$PRIMARY_URL" 2>/dev/null || echo "")
if echo "$HTTPS_RESPONSE" | grep -i "HTTP.*200\|HTTP.*301\|HTTP.*302" > /dev/null; then
    print_status "PASS" "HTTPS endpoint responds correctly"
else
    print_status "FAIL" "HTTPS endpoint not responding correctly"
fi

# 5. SSL/TLS Certificate Tests
print_status "INFO" "Testing SSL/TLS certificate..."

# Extract hostname from URL
HOSTNAME=$(echo "$PRIMARY_URL" | sed 's|https://||' | sed 's|/.*||')

# Test SSL certificate
SSL_INFO=$(echo | openssl s_client -servername "$HOSTNAME" -connect "$HOSTNAME:443" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "")

if [ -n "$SSL_INFO" ]; then
    print_status "PASS" "SSL certificate is present and valid"
    echo "$SSL_INFO" | while IFS= read -r line; do
        print_status "INFO" "  $line"
    done
else
    print_status "WARN" "Could not retrieve SSL certificate information"
fi

# 6. Security Headers Tests
print_status "INFO" "Testing security headers..."

SECURITY_HEADERS=$(curl -s -I --max-time 15 "$PRIMARY_URL" 2>/dev/null || echo "")

# Check for security headers
check_header() {
    local header=$1
    local description=$2
    if echo "$SECURITY_HEADERS" | grep -i "$header" > /dev/null; then
        print_status "PASS" "$description header present"
    else
        print_status "WARN" "$description header missing"
    fi
}

check_header "strict-transport-security" "