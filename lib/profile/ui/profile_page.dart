import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/ui/widgets/read_more_container.dart';
import 'package:neom_commons/neom_commons.dart';
import '../utils/profile_constants.dart';
import 'profile_controller.dart';
import 'widgets/profile_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: Container(
        height: AppTheme.fullHeight(context),
        decoration: AppTheme.appBoxDecoration,
        child: _.isLoading.value ? const AppCircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                GestureDetector(
                  child: DiagonallyCutColoredImage(
                    Image(
                      image: CachedNetworkImageProvider(_.profile.value.coverImgUrl.isNotEmpty
                          ? _.profile.value.coverImgUrl :_.profile.value.photoUrl.isNotEmpty
                          ? _.profile.value.photoUrl : AppFlavour.getNoImageUrl(),),
                      width: AppTheme.fullWidth(context),
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                    color: AppColor.cutColoredImage,
                    ),
                  onTap: () async => await _.showUpdateCoverImgDialog(context),
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  heightFactor: 1.08,
                  child: Column(
                    children: <Widget>[
                      Hero(
                        tag: _.profile.value.name,
                        child: GestureDetector(
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(_.profile.value.photoUrl.isNotEmpty
                                ? _.profile.value.photoUrl : AppFlavour.getNoImageUrl(),),
                            radius: 50.0,
                          ),
                          onTap: () => Get.toNamed(AppRouteConstants.profileEdit),
                        ),
                      ),
                      buildFollowerInfo(context, _.profile.value),
                      AppTheme.heightSpace20,
                      Container(
                        padding: const EdgeInsets.all(AppTheme.padding20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_.profile.value.name.capitalize,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(color: Colors.white
                              ),
                            ),
                            (_.profile.value.genres?.isNotEmpty ?? false) ?
                            GenresGridView(
                              _.profile.value.genres?.keys.toList() ?? [],
                              AppColor.white,
                              alignment: Alignment.centerLeft,
                              fontSize: 15,
                            ) : Container(),
                            Row(
                              children: <Widget>[
                                Text(_.location.value.isNotEmpty ? _.location.value : AppTranslationConstants.notSpecified.tr,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.place,
                                    color: Colors.white,
                                    size: 15.0,
                                  ),
                                  onPressed: ()=> _.updateLocation(),
                                ),
                              ],
                            ),
                            ReadMoreContainer(
                              text:_.profile.value.aboutMe.isEmpty
                                  ? AppTranslationConstants.noProfileDesc.tr
                                  : _.profile.value.aboutMe.capitalizeFirst,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DefaultTabController(
                          length: AppConstants.profileTabs.length,
                          child: Obx(() => Column(
                            children: <Widget>[
                              TabBar(
                                tabs: [
                                  Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} (${_.profile.value.posts?.length ?? 0})'),
                                  Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} (${AppFlavour.appInUse == AppInUse.c ?
                                  _.totalPresets.length : (_.totalMediaItems.length + _.totalReleaseItems.length)})'),
                                  Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} (${_.events.length})'),
                                ],
                                indicatorColor: Colors.white,
                                labelStyle: const TextStyle(fontSize: 15),
                                unselectedLabelStyle: const TextStyle(fontSize: 12),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                              ),
                              SizedBox(
                                height: AppTheme.fullHeight(context)/2.5,
                                child: TabBarView(
                                  children: AppFlavour.appInUse == AppInUse.c
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
