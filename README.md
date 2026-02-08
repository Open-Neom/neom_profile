# neom_profile

User profile management and display module for the **Open Neom** ecosystem. Provides comprehensive profile viewing, editing, and content aggregation with offline caching support.

## Features

### Profile Display
- **Profile Page** - Complete profile view with tabs
- **Profile Header** - Photo, cover, name, verification badge
- **Content Tabs** - Posts, items, events, chamber presets
- **Location Display** - Geographic location with address

### Profile Editing
- **Name & Bio** - Edit with validation and rate limiting
- **Profile Photo** - Upload and update profile image
- **Cover Image** - Upload and update cover photo
- **Profile Type** - Change profile type (artist, facilitator, etc.)
- **Usage Reason** - Set usage purpose
- **Facilities & Places** - Add associated locations

### Profile Cache
- **ProfileCacheController** - Cache visited profiles for offline access
- **7-day expiration** - Automatic cache cleanup
- **50 profile limit** - LRU-style cache management
- **Recent profiles** - Quick access to recently visited

### Pull-to-Refresh
- **Refresh profile data** - Reload from Firestore
- **Clear and reload** - Full activity data refresh

## Architecture

```
lib/
├── data/
│   └── hive/
│       └── profile_cache_controller.dart  # Offline cache
├── ui/
│   ├── profile_controller.dart
│   ├── profile_page.dart
│   ├── profile_edit_page.dart
│   ├── follows/
│   │   ├── followers_list_page.dart
│   │   └── following_list_page.dart
│   ├── tabs/
│   │   ├── profile_posts.dart
│   │   ├── profile_items.dart
│   │   ├── profile_events.dart
│   │   └── profile_chamber_presets.dart
│   └── widgets/
│       └── profile_widgets.dart
├── utils/
│   └── constants/
│       ├── profile_constants.dart
│       └── profile_translation_constants.dart
├── neom_profile.dart                      # Library exports
└── profile_routes.dart
```

## Installation

```yaml
dependencies:
  neom_profile:
    git:
      url: git@github.com:Open-Neom/neom_profile.git
```

## Dependencies

| Module | Purpose |
|--------|---------|
| `neom_core` | Services, models, Firestore |
| `neom_commons` | UI components, themes |

## Quick Start

```dart
import 'package:neom_profile/neom_profile.dart';

// Navigate to profile
Sint.toNamed(ProfileRoutes.profile);

// Use ProfileCacheController
final cacheController = ProfileCacheController();
await cacheController.cacheProfile(profile);
final cached = await cacheController.getCachedProfile(profileId);
```

## ProfileCacheController

```dart
final controller = ProfileCacheController();

// Cache a visited profile
await controller.cacheProfile(profile);

// Get cached profile
final profile = await controller.getCachedProfile(profileId);

// Get recently visited
final recentIds = await controller.getRecentlyVisitedIds(limit: 10);

// Get all cached profiles
final profiles = await controller.getAllCachedProfiles();

// Check cache status
final isCached = await controller.isProfileCached(profileId);
final count = await controller.getCachedProfileCount();
final stats = await controller.getCacheStats();

// Clear cache
await controller.clearAll();
```

## ProfileController Features

```dart
// Profile data
await setProfileInfo();
await loadProfileActivity();
await refreshProfile();  // Pull-to-refresh

// Profile editing
await updateProfileData();
await handleAndUploadImage(MediaUploadDestination.profile);
await updateLocation();

// Profile type management
showUpdateProfileType(context);
showUpdateUsageReason(context);
showAddFacility(context);
showAddPlace(context);
```

## Profile Tabs

| Tab | Content |
|-----|---------|
| Posts | User's image/video posts grid |
| Items | Media items, releases, external links |
| Events | Created, playing, attending events |
| Presets | Chamber presets (Cyberneom app) |

## Memory Management

```dart
@override
void onClose() {
  // TextEditingControllers properly disposed
  nameController.dispose();
  aboutMeController.dispose();
  displayNameController.dispose();
  bioController.dispose();
  super.onClose();
}
```

## Validation Rules

| Field | Rule |
|-------|------|
| Name | Min 3 chars, unique, 7-day update limit |
| About Me | Max 150 chars |
| Profile Photo | Via MediaUploadService |

## Contributing

Contributions welcome! Focus areas:
- Profile caching improvements
- Edit form enhancements
- Content aggregation optimization
- UI/UX improvements

See [CONTRIBUTING.md](https://github.com/Open-Neom/neom_core/blob/main/CONTRIBUTING.md) for guidelines.

## License

Apache License 2.0 - See [LICENSE](LICENSE)
