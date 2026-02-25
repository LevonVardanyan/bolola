#!/bin/bash

# Flutter Web App Deployment Script for bolola.org

WEB_PROJECT_PATH="/root/projects/bolola"
BUILD_PATH="$WEB_PROJECT_PATH/build/web"

echo "🚀 Deploying Flutter Web App..."

# Check if Flutter web build exists
if [ ! -d "$BUILD_PATH" ]; then
    echo "❌ Flutter web build not found at $BUILD_PATH"
    exit 1
fi

# Stop nginx temporarily for aggressive cache clearing
echo "⏸️  Temporarily stopping nginx..."
systemctl stop nginx

# Clear all possible nginx caches
echo "🧹 Clearing all nginx caches..."
rm -rf /var/cache/nginx/* 2>/dev/null || true
rm -rf /tmp/nginx/* 2>/dev/null || true
rm -rf /var/lib/nginx/cache/* 2>/dev/null || true

# Remove any ETag files that might exist
echo "🏷️  Removing ETag files..."
find "$BUILD_PATH" -name "*.etag" -delete 2>/dev/null || true

# Set file permissions
echo "🔐 Setting file permissions..."
chown -R www-data:www-data "$BUILD_PATH"
chmod -R 755 "$BUILD_PATH"

# Force update all file timestamps with current time + random seconds
echo "🔄 Force updating all file timestamps..."
current_time=$(date +%s)
find "$BUILD_PATH" -type f -exec touch -t $(date -d "@$((current_time + RANDOM % 60))" +%Y%m%d%H%M.%S) {} \;

# Add cache-busting query parameter to index.html
echo "💥 Adding cache-busting to index.html..."
if [ -f "$BUILD_PATH/index.html" ]; then
    # Add a timestamp query parameter to all asset references
    timestamp=$(date +%s)
    sed -i "s/\(href=\"[^\"]*\.\(css\|js\)\)/\1?v=$timestamp/g" "$BUILD_PATH/index.html"
    sed -i "s/\(src=\"[^\"]*\.\(js\|css\)\)/\1?v=$timestamp/g" "$BUILD_PATH/index.html"
fi

# Create a deployment timestamp file
echo "📅 Creating deployment timestamp..."
echo "$(date)" > "$BUILD_PATH/deployment.txt"
echo "Deployment ID: $(date +%s)-$(whoami)" >> "$BUILD_PATH/deployment.txt"

# Start nginx
echo "▶️  Starting nginx..."
if nginx -t; then
    systemctl start nginx
    echo "✅ Nginx started"
else
    echo "❌ Nginx config error"
    exit 1
fi

# Wait a moment for nginx to fully start
sleep 2

echo "✅ Deployment finished!"
echo "🌐 Visit: https://bolola.org"
echo "🆔 Deployment ID: $(date +%s)-$(whoami)"
echo "💡 Changes should be visible immediately. If not:"
echo "   1. Open in Incognito/Private mode"
echo "   2. Hard refresh (Ctrl+F5 / Cmd+Shift+R)"
echo "   3. Check deployment.txt at https://bolola.org/deployment.txt"
