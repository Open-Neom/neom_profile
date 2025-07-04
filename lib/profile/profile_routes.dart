import 'package:get/get.dart';

import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'ui/follows/followers_list_page.dart';
import 'ui/follows/following_list_page.dart';
import 'ui/profile_edit_page.dart';
import 'ui/profile_page.dart';

class ProfileRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.profile,
        page: () => const ProfilePage(),
        transition: Transition.zoom
    ),
    GetPage(
        name: AppRouteConstants.profileDetails,
        page: () => const ProfilePage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.profileEdit,
      page: () => const ProfileEditPage(),
    ),
    GetPage(
      name: AppRouteConstants.followers,
      page: () => const FollowersListPage(),
    ),
    GetPage(
      name: AppRouteConstants.following,
      page: () => const FollowingListPage(),
    ),
  ];

}
