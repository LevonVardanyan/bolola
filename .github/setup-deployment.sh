#!/bin/bash

# Deployment Setup Script for GitHub Actions
# Run this once to set up automatic deployment

set -e

echo "🚀 Setting up GitHub Actions deployment for bolola.org"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if SSH key already exists
if [ -f ~/.ssh/github_actions_bolola ]; then
    echo -e "${YELLOW}⚠️  SSH key already exists at ~/.ssh/github_actions_bolola${NC}"
    read -p "Do you want to use the existing key? (y/n): " use_existing
    if [ "$use_existing" != "y" ]; then
        echo "Aborting. Please remove or rename the existing key first."
        exit 1
    fi
else
    # Generate SSH key
    echo -e "${GREEN}Step 1: Generating SSH key pair...${NC}"
    ssh-keygen -t ed25519 -C "github-actions-bolola" -f ~/.ssh/github_actions_bolola -N ""
    echo "✅ SSH key generated"
    echo ""
fi

# Display public key
echo -e "${GREEN}Step 2: Add public key to server${NC}"
echo "Copy this public key and add it to your server's authorized_keys:"
echo ""
echo "------- PUBLIC KEY (copy everything below) -------"
cat ~/.ssh/github_actions_bolola.pub
echo "------- END PUBLIC KEY -------"
echo ""
read -p "Press Enter after you've added this key to the server..."

# Test SSH connection
echo ""
echo -e "${GREEN}Step 3: Testing SSH connection...${NC}"
if ssh -i ~/.ssh/github_actions_bolola -p22 -o StrictHostKeyChecking=no root@173.249.9.31 "echo 'SSH connection successful!'" 2>/dev/null; then
    echo "✅ SSH connection successful!"
else
    echo -e "${RED}❌ SSH connection failed. Please check the key was added correctly.${NC}"
    exit 1
fi

# Display private key for GitHub Secrets
echo ""
echo -e "${GREEN}Step 4: Add private key to GitHub Secrets${NC}"
echo ""
echo "1. Go to: https://github.com/LevonVardanyan/bolola/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Name: SERVER_SSH_KEY"
echo "4. Value: Copy the ENTIRE private key below (including BEGIN and END lines)"
echo ""
echo "------- PRIVATE KEY (copy everything below) -------"
cat ~/.ssh/github_actions_bolola
echo "------- END PRIVATE KEY -------"
echo ""
read -p "Press Enter after you've added the secret to GitHub..."

# Upload deploy script to server
echo ""
echo -e "${GREEN}Step 5: Uploading deploy script to server...${NC}"
if [ ! -f "deploy-web.sh" ]; then
    echo -e "${RED}❌ deploy-web.sh not found in current directory${NC}"
    exit 1
fi

scp -i ~/.ssh/github_actions_bolola -P22 deploy-web.sh root@173.249.9.31:/root/projects/bolola/
ssh -i ~/.ssh/github_actions_bolola -p22 root@173.249.9.31 "chmod +x /root/projects/bolola/deploy-web.sh"
echo "✅ deploy-web.sh uploaded and made executable"

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Commit and push the .github directory:"
echo "   git add .github"
echo "   git commit -m 'Add GitHub Actions deployment workflow'"
echo "   git push origin development"
echo ""
echo "2. Merge to release branch to trigger deployment:"
echo "   git checkout release"
echo "   git merge development"
echo "   git push origin release"
echo ""
echo "3. Monitor deployment at: https://github.com/LevonVardanyan/bolola/actions"
echo ""
