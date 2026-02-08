# Changelog

All notable changes to neom_profile will be documented in this file.

## [2.0.0] - 2025-02-08

### Added
- **ProfileCacheController** - Complete offline cache for visited profiles
  - 7-day cache expiration
  - 50 profile maximum with LRU cleanup
  - Recent profiles tracking
  - Cache statistics
- **Pull-to-refresh** - `refreshProfile()` method for data reload
- **Library exports** - `neom_profile.dart` for clean imports
- **Memory management** - TextEditingController disposal in `onClose()`

### Changed
- **SINT framework migration** - Replaced deprecated GetX API
- **Profile loading** - Optimized activity data loading
- **Service decoupling** - All controllers use service interfaces
- **Removed hive_flutter** - Using neom_core's Hive integration

### Fixed
- **Memory leaks** - Proper disposal of TextEditingControllers
- **Profile refresh** - Clear and reload all activity data
- **Location updates** - Improved geolocation handling

### Architecture
```
Cache System:
- ProfileCacheController (singleton)
- Hive-based storage
- 7-day expiration per profile
- 50 profile LRU limit
- Timestamp tracking for recency
```

### Dependencies
- `neom_core` - Core services and Firestore
- `neom_commons` - Shared UI components

---

## [1.5.2] - Previous Release

### Fixed
- Minor bug fixes and improvements

---

## [1.4.0] - Earlier Release

### Added
- ProfileTranslationConstants for localization
- Profile type management dialogs
- Facility and place addition

### Changed
- Service decoupling via interfaces
- UserService and GeoLocatorService integration
- Profile image handling via MediaUploadService

### Architecture
- Dependency Inversion Principle implementation
- Clean Architecture adherence
- Improved testability

---

## [1.3.0] - Earlier Release

### Added
- Followers/following list pages
- Profile tabs (posts, items, events)
- Chamber presets tab (Cyberneom)

### Changed
- Profile editing improvements
- Content aggregation optimization

---

## [1.2.0] - Initial Features

### Added
- Profile page display
- Profile editing
- Photo and cover upload
- Location management
