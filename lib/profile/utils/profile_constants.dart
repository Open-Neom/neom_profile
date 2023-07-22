import '../ui/tabs/profile_chamber_presets.dart';
import '../ui/tabs/profile_events.dart';
import '../ui/tabs/profile_items.dart';
import '../ui/tabs/profile_posts.dart';

class ProfileConstants {

  static final neomProfileTabPages = [const ProfilePosts(), const ProfileChamberPresets(), const ProfileEvents()];
  static final profileTabPages = [const ProfilePosts(), const ProfileItems(), const ProfileEvents()];

}
