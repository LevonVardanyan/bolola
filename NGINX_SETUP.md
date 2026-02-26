# Nginx Configuration for Web Routing

This document explains how to configure nginx to support Flutter web routing with browser back/forward buttons.

## Why This Is Needed

Flutter web uses client-side routing. When a user navigates to `/sources` or `/about`, the browser needs to:
1. Load `index.html` for ALL routes (not just `/`)
2. Let Flutter handle the routing internally

Without proper nginx configuration:
- ❌ Refreshing `/sources` shows 404 error
- ❌ Direct links to `/about` don't work
- ❌ Browser back button may break the app

With proper configuration:
- ✅ All routes load correctly
- ✅ Browser back/forward buttons work
- ✅ Deep linking works
- ✅ URL sharing works

## Setup Instructions

### Option 1: Update Existing Configuration

If you already have an nginx configuration for bolola.org:

1. **SSH into the server:**
   ```bash
   ssh -lroot -p22 173.249.9.31
   ```

2. **Backup current configuration:**
   ```bash
   cp /etc/nginx/sites-available/bolola.org /etc/nginx/sites-available/bolola.org.backup
   ```

3. **Edit the configuration:**
   ```bash
   nano /etc/nginx/sites-available/bolola.org
   ```

4. **Find the `location /` block and update it:**
   ```nginx
   location / {
       # CRITICAL: This enables SPA routing
       try_files $uri $uri/ /index.html;
       
       # Security headers
       add_header X-Frame-Options "SAMEORIGIN" always;
       add_header X-Content-Type-Options "nosniff" always;
       add_header X-XSS-Protection "1; mode=block" always;
   }
   ```

5. **Also add cache-busting for index.html:**
   ```nginx
   location = /index.html {
       add_header Cache-Control "no-cache, no-store, must-revalidate";
       add_header Pragma "no-cache";
       add_header Expires "0";
       try_files $uri =404;
   }
   ```

6. **Test the configuration:**
   ```bash
   nginx -t
   ```

7. **Reload nginx:**
   ```bash
   systemctl reload nginx
   ```

### Option 2: Use the Provided Configuration

If you're setting up from scratch:

1. **Copy the configuration file to the server:**
   ```bash
   scp -P22 nginx-spa.conf root@173.249.9.31:/etc/nginx/sites-available/bolola.org
   ```

2. **Create symbolic link:**
   ```bash
   ssh -lroot -p22 173.249.9.31 "ln -sf /etc/nginx/sites-available/bolola.org /etc/nginx/sites-enabled/bolola.org"
   ```

3. **Test and reload:**
   ```bash
   ssh -lroot -p22 173.249.9.31 "nginx -t && systemctl reload nginx"
   ```

## Verification

After updating the configuration, test that routing works:

### Test 1: Direct Route Access

```bash
# Should return index.html content (not 404)
curl -I https://bolola.org/sources
curl -I https://bolola.org/about
curl -I https://bolola.org/group
curl -I https://bolola.org/messages
```

Expected response:
```
HTTP/2 200 
content-type: text/html
```

### Test 2: Browser Testing

1. Open https://bolola.org
2. Navigate to different pages (Sources, About)
3. Copy the URL (e.g., `https://bolola.org/sources`)
4. Open in new tab - should load the page correctly
5. Test browser back/forward buttons - should work correctly

### Test 3: Refresh Test

1. Navigate to https://bolola.org/sources
2. Press F5 to refresh
3. Page should reload correctly (not show 404)

## Troubleshooting

### Issue: 404 on page refresh

**Cause:** The `try_files` directive is not configured correctly.

**Solution:** Ensure the location block has:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### Issue: Changes not visible after deployment

**Cause:** Browser or nginx is caching index.html.

**Solution:** 
1. Check nginx cache control for index.html:
   ```nginx
   location = /index.html {
       add_header Cache-Control "no-cache, no-store, must-revalidate";
   }
   ```

2. Clear nginx cache:
   ```bash
   rm -rf /var/cache/nginx/*
   systemctl reload nginx
   ```

3. Test in incognito mode or hard refresh (Ctrl+F5)

### Issue: SSL certificate errors

**Cause:** Certificate paths in nginx config are incorrect.

**Solution:**
1. Find correct certificate paths:
   ```bash
   certbot certificates
   ```

2. Update in nginx config:
   ```nginx
   ssl_certificate /etc/letsencrypt/live/bolola.org/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/bolola.org/privkey.pem;
   ```

### Issue: "413 Request Entity Too Large" on uploads

**Cause:** Default nginx upload size limit is too small.

**Solution:** Add to server block:
```nginx
client_max_body_size 100M;
```

## Configuration Breakdown

### Key Nginx Directives

| Directive | Purpose |
|-----------|---------|
| `try_files $uri $uri/ /index.html` | SPA routing - serve index.html for all routes |
| `add_header Cache-Control "no-cache"` | Prevent caching of index.html |
| `location ~* \.(js\|css)$` | Cache static assets for performance |
| `gzip on` | Compress responses for faster loading |
| `error_page 404 /index.html` | Fallback for 404 errors |

### Cache Strategy

| File Type | Cache Duration | Reason |
|-----------|----------------|--------|
| `index.html` | No cache | Must always load latest routing code |
| `*.js`, `*.css` | 1 year | Immutable - versioned by build hash |
| `*.png`, `*.jpg` | 1 year | Static assets don't change |
| Service worker | No cache | Must update for offline functionality |

## Performance Optimization

### Enable HTTP/2

Already enabled in the config:
```nginx
listen 443 ssl http2;
```

Benefits:
- Multiplexing (parallel requests)
- Header compression
- Server push capability

### Enable Gzip Compression

Already enabled in the config:
```nginx
gzip on;
gzip_types text/plain text/css application/javascript;
```

Typical compression results:
- `main.dart.js`: 2.5MB → 600KB (76% reduction)
- `index.html`: 15KB → 4KB (73% reduction)

### Browser Caching

Static assets cached for 1 year:
```nginx
location ~* \.(js|css|png|jpg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

Benefits:
- Faster subsequent page loads
- Reduced server bandwidth
- Better user experience

## Security Headers

The configuration includes security headers:

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### What These Do

| Header | Protection |
|--------|------------|
| `X-Frame-Options` | Prevents clickjacking attacks |
| `X-Content-Type-Options` | Prevents MIME type sniffing |
| `X-XSS-Protection` | Enables browser XSS filtering |

## Monitoring

### Check nginx logs

```bash
# Access logs
tail -f /var/log/nginx/access.log

# Error logs
tail -f /var/log/nginx/error.log
```

### Monitor nginx status

```bash
# Check if nginx is running
systemctl status nginx

# Check configuration is valid
nginx -t

# View loaded configuration
nginx -T
```

### Test performance

```bash
# Check response times
curl -w "@curl-format.txt" -o /dev/null -s https://bolola.org

# Where curl-format.txt contains:
# time_namelookup:  %{time_namelookup}\n
# time_connect:  %{time_connect}\n
# time_starttransfer:  %{time_starttransfer}\n
# time_total:  %{time_total}\n
```

## Automated Deployment Integration

The deployment script (`deploy-web.sh`) automatically handles:
- ✅ Stopping/starting nginx
- ✅ Clearing nginx caches
- ✅ Setting file permissions
- ✅ Cache-busting timestamps

No manual nginx intervention needed after initial setup!

## References

- [Nginx try_files directive](https://nginx.org/en/docs/http/ngx_http_core_module.html#try_files)
- [SPA routing with nginx](https://www.nginx.com/blog/creating-nginx-rewrite-rules/)
- [Flutter web URL strategies](https://docs.flutter.dev/ui/navigation/url-strategies)
