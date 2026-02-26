# Web Routing Configuration

This document explains how browser back/forward buttons are supported in the Flutter web application.

## Overview

The application now uses Flutter's built-in routing with URL strategy to support proper browser history navigation. This means:

- ✅ Browser back button works correctly
- ✅ Browser forward button works correctly  
- ✅ Each page has a unique URL path
- ✅ URLs are clean (no hash `#` symbols)
- ✅ Deep linking is supported
- ✅ Browser history stack is maintained

## Implementation

### 1. URL Strategy (`main.dart`)

```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  if (kIsWeb) {
    usePathUrlStrategy(); // Enables clean URLs without hash
  }
  // ... rest of initialization
}
```

This configures Flutter to use path-based URLs (`/sources`) instead of hash-based URLs (`/#/sources`).

### 2. Route Configuration (`app_router.dart`)

The `AppRouter` class defines all application routes with unique URL paths:

| Route | URL Path | Description |
|-------|----------|-------------|
| Home | `/` | Main home page with categories |
| Sources | `/sources` | List of media sources |
| About | `/about` | About page |
| Moderation | `/moderation` | Admin moderation page |
| Media Group | `/group` | Individual media group details |
| User Messages | `/messages` | Admin user messages page |

### 3. Navigation Methods

Instead of using `Navigator.push` directly, use the provided helper methods:

```dart
// Navigate to sources page
AppRouter.navigateToSources(context);

// Navigate to about page
AppRouter.navigateToAbout(context);

// Navigate to moderation (admin only)
AppRouter.navigateToModeration(context, appBloc, "video");

// Navigate to media group
AppRouter.navigateToMediaGroup(context, appBloc, group);

// Navigate to user messages (admin only)
AppRouter.navigateToUserMessages(context, appBloc);
```

### 4. Route Observer

A `RouteObserver` is registered in the app to track navigation changes:

```dart
MaterialApp(
  navigatorObservers: [AppRouter.routeObserver],
  // ...
)
```

This enables proper browser history integration.

## Testing

### Manual Testing on Web

1. **Build for web:**
   ```bash
   flutter build web
   ```

2. **Run locally:**
   ```bash
   flutter run -d chrome
   ```

3. **Test browser navigation:**
   - Navigate to different pages (Sources, About, etc.)
   - Click browser back button - should navigate to previous page
   - Click browser forward button - should navigate forward
   - Check URL bar - URLs should be clean without `#` symbol
   - Copy a URL and paste in new tab - should navigate to that page directly

### Testing Scenarios

1. **Basic Navigation:**
   - Home → Sources → Back button → Should return to Home
   - Home → About → Back button → Should return to Home

2. **Deep Linking:**
   - Copy URL: `https://yourapp.com/sources`
   - Paste in new tab → Should open Sources page directly

3. **Multi-level Navigation:**
   - Home → Sources → About → Back (2x) → Should return to Home
   - Forward button → Should navigate to Sources

4. **Admin Routes (requires admin login):**
   - Home → Moderation → Back → Should return to Home
   - Home → User Messages → Back → Should return to Home

## Migration Guide

### Updating Existing Navigation

Replace old navigation code:

```dart
// OLD - Don't use this
Navigator.push(
  context, 
  MaterialPageRoute(builder: (_) => SourcesRoute())
);
```

With new routing methods:

```dart
// NEW - Use this instead
AppRouter.navigateToSources(context);
```

### Adding New Routes

To add a new route:

1. **Define route constant in `AppRouter`:**
   ```dart
   static const String myNewRoute = '/my-new-route';
   ```

2. **Add case in `onGenerateRoute`:**
   ```dart
   case myNewRoute:
     return MaterialPageRoute(
       builder: (_) => MyNewPage(),
       settings: settings,
     );
   ```

3. **Create navigation helper method:**
   ```dart
   static void navigateToMyNewRoute(BuildContext context) {
     Navigator.pushNamed(context, myNewRoute);
   }
   ```

4. **If route needs arguments, create args class:**
   ```dart
   class MyNewRouteArgs {
     final String param1;
     final int param2;
     
     MyNewRouteArgs({required this.param1, required this.param2});
   }
   ```

## Technical Details

### Why Path URL Strategy?

Flutter web defaults to hash-based URLs (`/#/page`) for compatibility with older servers. Path-based URLs (`/page`) are:
- More SEO-friendly
- Cleaner appearance
- Better for deep linking
- Standard for modern web apps

### Route Observer Benefits

The `RouteObserver` provides:
- Browser history synchronization
- Proper back/forward button behavior
- URL bar updates
- State restoration support

### Named Routes vs MaterialPageRoute

Named routes (`pushNamed`) are preferred over `MaterialPageRoute` for web because:
- URL changes are tracked automatically
- Browser history is maintained
- Deep linking works out of the box
- Route state can be restored

## Troubleshooting

### Issue: Back button doesn't work

**Solution:** Ensure you're using `AppRouter.navigateToX()` methods instead of direct `Navigator.push()`.

### Issue: URLs still have `#` symbol

**Solution:** Check that `usePathUrlStrategy()` is called in `main.dart` before `runApp()`.

### Issue: Deep link shows 404

**Solution:** Web server needs to redirect all paths to `index.html`. For Firebase Hosting, add to `firebase.json`:

```json
{
  "hosting": {
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Issue: Arguments not passed to route

**Solution:** Ensure you're passing arguments correctly:

```dart
Navigator.pushNamed(
  context, 
  AppRouter.myRoute,
  arguments: MyRouteArgs(param1: value1, param2: value2)
);
```

## Performance Notes

- Named routes have minimal overhead compared to direct navigation
- URL strategy is set once at app startup
- Route observer is lightweight and doesn't impact performance
- Browser history is handled natively by the browser

## Browser Compatibility

This implementation works on all modern browsers:
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox
- ✅ Safari
- ✅ Opera

Minimum browser versions:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Future Improvements

Potential enhancements:

1. **Route Guards:** Add authentication checks before navigation
2. **Query Parameters:** Support URL query parameters for filtering
3. **Route Transitions:** Custom page transition animations
4. **State Restoration:** Preserve page state across browser refresh
5. **Analytics Integration:** Track page views with URL changes

## Resources

- [Flutter Web URL Strategies](https://docs.flutter.dev/ui/navigation/url-strategies)
- [Navigator 2.0 Deep Dive](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade)
- [Web Routing Best Practices](https://docs.flutter.dev/platform-integration/web/web-routing)
