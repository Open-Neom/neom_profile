## 1.4.0 - Architectural Enhancements & Service Decoupling

This release for `neom_profile` introduces significant architectural refinements, primarily focusing on enhancing decoupling, testability, and clarity of service interactions, in line with the broader Open Neom refactoring efforts.

**Key Architectural & Feature Improvements:**

* **Service Decoupling for Core Dependencies:**
    * **User Service Integration:** The `ProfileController` now interacts with user data and profile management through the `UserService` interface (instead of directly with `UserController`). This promotes the Dependency Inversion Principle (DIP), making the module more robust and testable.
    * **Geolocation Service Integration:** Location functionalities (like updating profile location) are now handled via the `GeoLocatorService` interface (instead of `GeoLocatorController`), further abstracting external dependencies from the module's core logic.

* **Module-Specific Translations:**
    * Introduced `ProfileTranslationConstants` to centralize and manage all module-specific translation keys. This ensures that `neom_profile`'s UI text is easily localizable and maintainable, aligning with Open Neom's comprehensive internationalization strategy.
    * Examples of new translation keys include: `followingMsg`, `followersMsg`, `unfollowMsg`, `updateProfilePicture`, `profileDetails`, `profileInformation`, `aboutMe`, `following`, `followers`, `updateProfile`, `editProfile`, `profileUpdatedMsg`, `thereWasNoChanges`, `updateProfileType`, `updateProfileTypeMsg`, `updateProfileTypeSuccess`, `updateProfileTypeSame`, `facilityType`, `facilityAdded`, `placeType`, `placeAdded`.

* **Enhanced Profile Management & Display:**
    * Improved logic for updating profile data (name, about me), including validation for name availability and update frequency.
    * Refined handling of profile image and cover image updates, leveraging `neom_media_upload` services.
    * Streamlined the process for updating profile types (e.g., `appArtist`, `facilitator`, `host`), and adding associated facility or place types.
    * Optimized loading and display of aggregated content (posts, items, events, chamber presets) on the profile page for better performance.

* **Integration with Global Architectural Changes:**
    * Adopts the updated service injection patterns established in `neom_core`'s recent refactor, ensuring consistent dependency management.
    * Benefits from the consolidated `CoreConstants` and other global utilities from `neom_commons`.

**Overall Benefits of this Release:**

* **Increased Testability:** Decoupling from concrete controllers allows for easier mocking and unit testing of `ProfileController`'s business logic.
* **Improved Maintainability:** Clearer separation of concerns makes the module easier to understand, debug, and extend.
* **Enhanced Flexibility:** The module is now more adaptable to changes in underlying service implementations without requiring modifications to `neom_profile` itself.
* **Richer User Experience:** Refinements in profile editing and display contribute to a more intuitive and comprehensive user interaction.