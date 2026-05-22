import 'package:neom_core/ui/deferred_loader.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'ui/follows/followers_list_page.dart' deferred as followers;
import 'ui/follows/following_list_page.dart' deferred as following;
import 'ui/profile_edit_page.dart' deferred as profileEdit;
import 'ui/profile_page.dart' deferred as profile;
import 'ui/web/saia_profiles_page.dart' deferred as saiaProfile;

class ProfileRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
        name: AppRouteConstants.profile,
        page: () => DeferredLoader(profile.loadLibrary, () => profile.ProfilePage()),
        transition: Transition.zoom
    ),
    SintPage(
        name: AppRouteConstants.profileDetails,
        page: () => DeferredLoader(profile.loadLibrary, () => profile.ProfilePage()),
        transition: Transition.zoom
    ),
    SintPage(
      name: AppRouteConstants.profileEdit,
      page: () => DeferredLoader(profileEdit.loadLibrary, () => profileEdit.ProfileEditPage()),
    ),
    SintPage(
      name: AppRouteConstants.saiaProfile,
      page: () => DeferredLoader(saiaProfile.loadLibrary, () => saiaProfile.SaiaProfilesPage()),
      transition: Transition.rightToLeftWithFade,
    ),
    SintPage(
      name: AppRouteConstants.followers,
      page: () => DeferredLoader(followers.loadLibrary, () => followers.FollowersListPage()),
    ),
    SintPage(
      name: AppRouteConstants.following,
      page: () => DeferredLoader(following.loadLibrary, () => following.FollowingListPage()),
    ),
  ];

}
