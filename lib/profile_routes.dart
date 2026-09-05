import 'package:flutter/material.dart';
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
      page: () =>
          DeferredLoader(profile.loadLibrary, () => profile.ProfilePage()),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.profileDetails,
      page: () => const _PublicProfileRedirect(),
      transition: Transition.zoom,
    ),
    SintPage(
      name: AppRouteConstants.profileEdit,
      page: () => DeferredLoader(
        profileEdit.loadLibrary,
        () => profileEdit.ProfileEditPage(),
      ),
    ),
    SintPage(
      name: AppRouteConstants.saiaProfile,
      page: () => DeferredLoader(
        saiaProfile.loadLibrary,
        () => saiaProfile.SaiaProfilesPage(),
      ),
      transition: Transition.rightToLeftWithFade,
    ),
    SintPage(
      name: AppRouteConstants.followers,
      page: () => DeferredLoader(
        followers.loadLibrary,
        () => followers.FollowersListPage(),
      ),
    ),
    SintPage(
      name: AppRouteConstants.following,
      page: () => DeferredLoader(
        following.loadLibrary,
        () => following.FollowingListPage(),
      ),
    ),
  ];
}

/// `/profile/:id` is a legacy public address. [ProfilePage] represents the
/// signed-in account and ignores that route parameter, so rendering it here
/// showed an empty/current profile to guests. Keep old links working by
/// forwarding them to the public mate-details flow.
class _PublicProfileRedirect extends StatefulWidget {
  const _PublicProfileRedirect();

  @override
  State<_PublicProfileRedirect> createState() => _PublicProfileRedirectState();
}

class _PublicProfileRedirectState extends State<_PublicProfileRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileId = Sint.routeParam ?? '';
      final target = profileId.isEmpty
          ? AppRouteConstants.root
          : AppRouteConstants.matePath(profileId);
      Sint.offNamed(target, arguments: Sint.arguments);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
