import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/buttons/position_back_button.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_ytmusic/ui/widgets/influences_grid_view.dart';
import 'package:neom_commons/ui/widgets/images/diagonally_cut_colored_image.dart';
import 'package:neom_commons/ui/widgets/profile_completion_indicator.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/ui/widgets/web_content_wrapper.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:sint/sint.dart';

import '../utils/constants/profile_constants.dart';
import 'profile_controller.dart';
import 'web/profile_web_page.dart';
import 'widgets/profile_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (controller) {
        if (kIsWeb && MediaQuery.of(context).size.width > 900) {
          return ProfileWebPage(controller: controller);
        }
        return Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: WebContentWrapper(
        maxWidth: 900,
        padding: EdgeInsets.zero,
        child: Container(
        decoration: AppTheme.appBoxDecoration,
        child: controller.isLoading.value ? const AppCircularProgressIndicator()
            : RefreshIndicator(
          onRefresh: () => controller.refreshProfile(),
          color: AppColor.bondiBlue75,
          backgroundColor: AppColor.scaffold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                GestureDetector(
                  child: DiagonallyCutColoredImage(
                    Image(
                      image: platformImageProvider(controller.profile.value.coverImgUrl.isNotEmpty
                          ? controller.profile.value.coverImgUrl :controller.profile.value.photoUrl.isNotEmpty
                          ? controller.profile.value.photoUrl : AppProperties.getNoImageUrl(),),
                      width: AppTheme.fullWidth(context),
                      height: 225,
                      fit: BoxFit.cover,
                    ),
                    color: AppColor.cutColoredImage,
                    ),
                  onTap: () => AuthGuard.protect(context, () async {
                    await controller.showUpdateCoverImgDialog(context);
                  }),
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  heightFactor: 1.08,
                  child: Column(
                    children: <Widget>[
                      Hero(
                        tag: controller.profile.value.name,
                        child: GestureDetector(
                          child: CircleAvatar(
                            backgroundImage: platformImageProvider(controller.profile.value.photoUrl.isNotEmpty
                                ? controller.profile.value.photoUrl : AppProperties.getAppLogoUrl(),),
                            radius: 75.0,
                          ),
                          onTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
                        ),
                      ),
                      buildFollowerInfo(context, controller.profile.value),
                      // Profile completion indicator
                      ProfileCompletionIndicator(
                        profile: controller.profile.value,
                        onPhotoTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
                        onCoverTap: () => AuthGuard.protect(context, () => controller.showUpdateCoverImgDialog(context)),
                        onBioTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
                        onLocationTap: () => AuthGuard.protect(context, () => controller.updateLocation()),
                        onGenresTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
                        onSlugTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
                        compact: true,
                      ),
                      AppTheme.heightSpace20,
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.padding20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: Text(TextUtilities.capitalizeFirstLetter(controller.profile.value.name),
                                      style: Theme.of(context).textTheme.titleLarge!
                                          .copyWith(color: Colors.white
                                      ),
                                    ),
                                  ),
                                  AppTheme.widthSpace5,
                                  if(controller.profile.value.verificationLevel != VerificationLevel.none)
                                    Container(
                                      height: 30,
                                      alignment: Alignment.center,
                                      child: AppFlavour.getVerificationIcon(controller.profile.value.verificationLevel, size: 18,)
                                    ),
                                ]
                            ),
                            const Divider(),
                            (controller.profile.value.genres?.isNotEmpty ?? false) ?
                            GenresGridView(
                              controller.profile.value.genres?.keys.toList() ?? [],
                              AppColor.white,
                              alignment: Alignment.centerLeft,
                              fontSize: 12,
                            ) : const SizedBox.shrink(),
                            if (controller.profile.value.influences?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              InfluencesGridView(influences: controller.profile.value.influences!),
                            ],
                            GestureDetector(
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.place,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  AppTheme.widthSpace5,
                                  Text(controller.location.isNotEmpty ? controller.location.length > CoreConstants.maxLocationNameLength
                                      ? "${controller.location.substring(0, CoreConstants.maxLocationNameLength)}..." : controller.location
                                      : AppTranslationConstants.notSpecified.tr,
                                  ),
                                ],
                              ),
                              onTap: () => AuthGuard.protect(context, () => controller.updateLocation()),
                            ),
                            const Divider(),
                            ReadMoreContainer(
                              padding: 0,
                              text:controller.profile.value.aboutMe.isEmpty
                                  ? CommonTranslationConstants.noProfileDesc.tr
                                  : TextUtilities.capitalizeFirstLetter(controller.profile.value.aboutMe),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DefaultTabController(
                          length: AppConstants.profileTabs.length,
                          child: Obx(() => Column(
                            children: <Widget>[
                              TabBar(
                                tabs: [
                                  Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} (${controller.profile.value.posts?.length ?? 0})'),
                                  Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} (${AppConfig.instance.appInUse == AppInUse.c ?
                                  controller.totalPresets.length : (controller.totalMixedItems.length)})'),
                                  Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} (${controller.events.length})'),
                                ],
                                indicatorColor: Colors.white,
                                labelStyle: const TextStyle(fontSize: 15),
                                unselectedLabelStyle: const TextStyle(fontSize: 12),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                              ),
                              SizedBox(
                                height: kIsWeb ? 600 : AppTheme.fullHeight(context)/2.5,
                                child: TabBarView(
                                  children: (AppConfig.instance.appInUse == AppInUse.c || AppConfig.instance.appInUse == AppInUse.o)
                                      ? ProfileConstants.neomProfileTabPages : ProfileConstants.profileTabPages,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const PositionBackButton(),
              ],
            ),
          ],
          ),
        ),
        ),
      ),
      ),
      );},
    );
  }
}
