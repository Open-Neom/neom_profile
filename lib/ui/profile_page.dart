import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/buttons/position_back_button.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/images/diagonally_cut_colored_image.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
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

import '../utils/constants/profile_constants.dart';
import 'profile_controller.dart';
import 'widgets/profile_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Container(
        height: AppTheme.fullHeight(context),
        decoration: AppTheme.appBoxDecoration,
        child: controller.isLoading.value ? const AppCircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                GestureDetector(
                  child: DiagonallyCutColoredImage(
                    Image(
                      image: CachedNetworkImageProvider(controller.profile.value.coverImgUrl.isNotEmpty
                          ? controller.profile.value.coverImgUrl :controller.profile.value.photoUrl.isNotEmpty
                          ? controller.profile.value.photoUrl : AppProperties.getNoImageUrl(),),
                      width: AppTheme.fullWidth(context),
                      height: 225,
                      fit: BoxFit.cover,
                    ),
                    color: AppColor.cutColoredImage,
                    ),
                  onTap: () async => await controller.showUpdateCoverImgDialog(context),
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
                            backgroundImage: CachedNetworkImageProvider(controller.profile.value.photoUrl.isNotEmpty
                                ? controller.profile.value.photoUrl : AppProperties.getAppLogoUrl(),),
                            radius: 75.0,
                          ),
                          onTap: () => Get.toNamed(AppRouteConstants.profileEdit),
                        ),
                      ),
                      buildFollowerInfo(context, controller.profile.value),
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
                              onTap: ()=> controller.updateLocation(),
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
                                height: AppTheme.fullHeight(context)/2.5,
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
      ),),
    );
  }
}
