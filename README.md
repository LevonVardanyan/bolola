# Bolola

A Flutter application for video content.

## Project Structure

- **Flutter App**: This repository
- **Backend Server**: Separate repository at `/Users/lyovon/Programming/ServerProjects/bolola-server`
- **Production URL**: https://bolola.org
- **Staging URL**: https://staging.bolola.org
- **Production URL**: https://production.bolola.org

## Development

### Prerequisites

- Flutter SDK (2.17.1 or higher)
- Dart SDK

### Setup

```bash
# Install dependencies
flutter pub get

# Generate code (for Retrofit, JSON serialization, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Commands

```bash
# Build APK (debug)
flutter build apk

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build Web
flutter build web --release
```

## Deployment

### Automatic Deployment (Recommended)

Deployment happens automatically via GitHub Actions when you push to the `release` branch.

**Quick Start:**
```bash
# 1. Run setup (first time only)
./.github/setup-deployment.sh

# 2. Deploy by pushing to release branch
git checkout release
git merge development
git push origin release
```

📚 **Full deployment documentation**: [.github/DEPLOYMENT.md](.github/DEPLOYMENT.md)

### Manual Deployment

```bash
# Build locally
flutter build web --release --web-renderer html

# Upload to server
rsync -avz -e "ssh -p22" build/web/ root@173.249.9.31:/root/projects/bolola/build/web/

# Deploy on server
ssh -lroot -p22 173.249.9.31 "cd /root/projects/bolola && ./deploy-web.sh"
```

## Server Access

```bash
# SSH to server
ssh -lroot -p22 173.249.9.31

# SFTP to server
sftp root@173.249.9.31
```

## Project Links

- [Deployment Documentation](.github/DEPLOYMENT.md)
- [GitHub Actions](https://github.com/LevonVardanyan/bolola/actions)