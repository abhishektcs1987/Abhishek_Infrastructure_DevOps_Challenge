#!/bin/bash
set -e

echo "Running Terraform validation and security checks..."

# Validate Terraform
terraform fmt -check
terraform validate
terraform plan -out=tfplan.out

# Check for HTTPS enforcement
URL=$(terraform output -raw website_url)
curl -s -I "$URL" | grep -q "Location: https://" && echo "✅ HTTPS redirection OK" || echo "❌ No HTTPS redirection"

# Health check
HEALTH_URL=$(terraform output -raw health_check_url)
curl -s "$HEALTH_URL" | grep -q "healthy" && echo "✅ Health check OK" || echo "❌ Health check failed"