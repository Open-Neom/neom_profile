# neom_profile
neom_profile is a core module within the Open Neom ecosystem, dedicated to presenting
and managing user profile details. It provides a comprehensive view of a user's identity,
activities, and connections within the platform, serving as a central hub for personal
expression and interaction. This module encompasses functionalities for displaying profile information, 
editing personal details, managing followers/following, and showcasing user-generated content (posts, items, events).

Designed to be both informative and highly customizable, neom_profile aligns with Open Neom's vision
of empowering users to curate their digital presence and connect meaningfully. It strictly adheres
to Clean Architecture principles, ensuring its logic is robust, testable, and decoupled.

It seamlessly integrates with neom_core for core user data and services, and neom_commons
for shared UI components, providing a cohesive and intuitive profile experience.

🌟 Features & Responsibilities
neom_profile provides a rich set of functionalities for profile management and display:
•	Profile Display: Presents a detailed view of a user's profile, including photo, cover image, name,
    "about me" description, location, and verification level.
•	Profile Editing: Allows users to edit their personal information, update profile and cover images,
    and manage their profile type (e.g., artist, facilitator, host, researcher) and associated details
    (e.g., instruments, facilities, places).
•	Follower & Following Management: Displays lists of users that the current profile follows and who
    follow the current profile, with navigation to their respective profiles.
•	Content Aggregation: Integrates and displays various types of user-generated content associated with the profile, including:
    o	Posts: A grid view of the user's posts.
    o	Items: A list of media items (e.g., songs, books, releases) associated with the user's profile.
    o	Chamber Presets (Cyberneom specific): For Cyberneom app flavors, displays personalized frequency presets.
    o	Events: A list of events created, attended, or participated in by the user.
•	Location Management: Allows users to update their location, leveraging neom_core's geolocation services.
•	Data Persistence & Updates: Handles updating profile data (name, about me, images, types, locations)
    to the backend via neom_core services.
•	Dynamic UI Adaptation: Adjusts UI elements and displayed content based on the AppInUse configuration
    (e.g., specific tabs for Cyberneom vs. general app).

📦Technical Highlights / Why it Matters (for developers)
For developers, neom_profile serves as an excellent case study for:
•	Complex UI Composition: Demonstrates how to build a rich and interactive profile UI using a combination of Stack, SingleChildScrollView, TabBarView, GridView, and custom widgets.
•	GetX for Reactive State: Utilizes GetX's ProfileController for managing complex reactive state (e.g., Rx<AppProfile>, RxBool for edit status, RxMap for content lists) and orchestrating UI updates.
•	Service Layer Interaction: Shows seamless interaction with various core services (UserService, MediaUploadService, ProfileFirestore, PostFirestore, EventFirestore, FrequencyFirestore, FacilityFirestore, PlaceFirestore) through their defined interfaces, maintaining strong architectural separation.
•	Image Handling & Caching: Integrates CachedNetworkImageProvider and DiagonallyCutColoredImage for efficient and aesthetically pleasing image display, including profile and cover photos.
•	Dynamic Content Loading: Manages asynchronous data loading for posts, items, and events, ensuring a smooth user experience even with large datasets.
•	Conditional UI Logic: Implements logic to display different UI elements or content based on user roles, app flavor, and data availability.
•	Modular Content Display: Showcases how content from other modules (e.g., posts, items, events) can be aggregated and displayed within a single profile view, reinforcing the modular nature of Open Neom.

How it Supports the Open Neom Initiative
neom_profile is vital to the Open Neom ecosystem and the broader Tecnozenism vision by:
•	Fostering Personal Expression: It provides users with a dedicated space to express their identity, interests, and contributions, empowering their digital presence.
•	Building Community: By showcasing connections (followers/following) and shared activities, it strengthens the sense of community and facilitates meaningful interactions.
•	Supporting Research & Biofeedback: For researchers, profiles can serve as a hub for displaying research contributions or for users to track their personal biofeedback journey (e.g., Chamber Presets in Cyberneom).
•	Ensuring Data Transparency & Control: It allows users to manage their own data and privacy settings, aligning with the principles of decentralization and user autonomy.
•	Showcasing Architectural Excellence: As a comprehensive feature module, it exemplifies how complex user-facing functionalities can be built and maintained within Open Neom's modular and decoupled architectural framework.

🚀 Usage
This module provides the ProfilePage for displaying user profiles and ProfileEditPage for modifying them. It is typically accessed from the main navigation (neom_home) or directly via routes with a user ID. It also includes sub-pages for managing followers and following.

🛠️ Dependencies
neom_profile relies on neom_core for core services, models, and routing constants, and on neom_commons for reusable UI components, themes, and utility functions.

🤝 Contributing
We welcome contributions to the neom_profile module! If you're passionate about user profiles, social connections, or enhancing personal expression within digital platforms, your contributions can significantly impact how users interact with Open Neom.
To understand the broader architectural context of Open Neom and how neom_profile fits into the overall vision of Tecnozenism, please refer to the main project's MANIFEST.md.
For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
