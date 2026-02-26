# Automated Deployment Setup

This document explains how to set up automatic deployment to bolola.org when pushing to the `release` branch.

## How It Works

When you push to the `release` branch:
1. GitHub Actions triggers automatically
2. Builds Flutter web app (`flutter build web --release`)
3. Uploads build files to server via rsync
4. Runs `deploy-web.sh` on server to update nginx cache and permissions
5. Your website is live at https://bolola.org

## Prerequisites

Before setting up deployment, ensure:

1. ✅ **Nginx is configured for SPA routing** - See [NGINX_SETUP.md](../NGINX_SETUP.md)
   - Required for browser back/forward buttons to work
   - Must be done once before first deployment

2. ✅ **SSH access to server** - You need root access to the server

3. ✅ **GitHub repository access** - Ability to add secrets and workflows

## Initial Setup (One-Time)

### Step 1: Generate SSH Key for GitHub Actions

On your local machine, generate a new SSH key pair for GitHub Actions:

```bash
ssh-keygen -t ed25519 -C "github-actions-bolola" -f ~/.ssh/github_actions_bolola
```

Press Enter when asked for a passphrase (leave it empty for automation).

### Step 2: Add Public Key to Server

Copy the public key to your server:

```bash
# Display the public key
cat ~/.ssh/github_actions_bolola.pub

# Add it to server's authorized_keys
ssh -lroot -p22 173.249.9.31 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/github_actions_bolola.pub
```

### Step 3: Test SSH Connection

Verify the key works:

```bash
ssh -i ~/.ssh/github_actions_bolola -p22 root@173.249.9.31 "echo 'SSH connection successful!'"
```

### Step 4: Add Private Key to GitHub Secrets

1. Copy your **private key**:
   ```bash
   cat ~/.ssh/github_actions_bolola
   ```

2. Go to your GitHub repository: `https://github.com/LevonVardanyan/bolola`

3. Navigate to: **Settings** → **Secrets and variables** → **Actions**

4. Click **"New repository secret"**

5. Create the secret:
   - **Name**: `SERVER_SSH_KEY`
   - **Value**: Paste the entire private key content (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)

6. Click **"Add secret"**

### Step 5: Upload deploy-web.sh to Server

The setup script will automatically upload the deployment script, or do it manually:

```bash
# Upload deploy script to server
scp -P22 deploy-web.sh root@173.249.9.31:/root/projects/bolola/

# Make it executable
ssh -lroot -p22 173.249.9.31 "chmod +x /root/projects/bolola/deploy-web.sh"
```

## Usage

### Deploy to Production

Simply push to the release branch:

```bash
# Switch to release branch
git checkout release

# Merge your changes (from development or main)
git merge development

# Push to trigger deployment
git push origin release
```

### Monitor Deployment

1. Go to your GitHub repository
2. Click on **"Actions"** tab
3. Watch the deployment progress in real-time
4. Check logs if anything fails

### Deployment Workflow

```
development → (test locally) → release → (GitHub Actions) → bolola.org
```

## Troubleshooting

### SSH Connection Failed

```bash
# Test SSH key manually
ssh -i ~/.ssh/github_actions_bolola -p22 root@173.249.9.31
```

### Build Failed

- Check Flutter version compatibility
- Ensure all dependencies are in `pubspec.yaml`
- Test build locally first: `flutter build web --release`

### Deploy Script Failed

- SSH to server and run manually:
  ```bash
  ssh -lroot -p22 173.249.9.31
  cd /root/projects/bolola
  ./deploy-web.sh
  ```

### Check Server Nginx

```bash
ssh -lroot -p22 173.249.9.31 "nginx -t && systemctl status nginx"
```

## Manual Deployment (Fallback)

If GitHub Actions fails, deploy manually:

```bash
# 1. Build locally
flutter build web --release

# 2. Upload to server
rsync -avz -e "ssh -p22" build/web/ root@173.249.9.31:/root/projects/bolola/build/web/

# 3. Run deploy script
ssh -lroot -p22 173.249.9.31 "cd /root/projects/bolola && ./deploy-web.sh"
```

## Security Notes

- Never commit the private SSH key to the repository
- Use GitHub Secrets for all sensitive data
- The SSH key is only used by GitHub Actions runners
- Keep your server's SSH access restricted

## Files Created

- `.github/workflows/deploy-release.yml` - GitHub Actions workflow
- `.github/DEPLOYMENT.md` - This documentation
