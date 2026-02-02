import 'package:sint/sint.dart';

import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/follows/followers_list_page.dart';
import 'ui/follows/following_list_page.dart';
import 'ui/profile_edit_page.dart';
import 'ui/profile_page.dart';

class ProfileRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
        name: AppRouteConstants.profile,
        page: () => const ProfilePage(),
        transition: Transition.zoom
    ),
    SintPage(
        name: AppRouteConstants.profileDetails,
        page: () => const ProfilePage(),
        transition: Transition.zoom
    ),
    SintPage(
      name: AppRouteConstants.profileEdit,
      page: () => const ProfileEditPage(),
    ),
    SintPage(
      name: AppRouteConstants.followers,
      page: () => const FollowersListPage(),
    ),
    SintPage(
      name: AppRouteConstants.following,
      page: () => const FollowingListPage(),
    ),
  ];

}
