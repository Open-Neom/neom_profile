import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        body: Container(
        height: AppTheme.fullHeight(context),
        decoration: AppTheme.appBoxDecoration,
        child: _.isLoading ? const Center(child: CircularProgressIndicator())
       : SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                GestureDetector(
                  child: DiagonallyCutColoredImage(
                    Image(
                      image: CachedNetworkImageProvider(_.profile.coverImgUrl.isNotEmpty
                          ? _.profile.coverImgUrl :_.profile.photoUrl.isNotEmpty
                          ? _.profile.photoUrl : AppFlavour.getNoImageUrl(),),
                      width: AppTheme.fullWidth(context),
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                    color: AppColor.cutColoredImage,
                    ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context){
                      return SimpleDialog(
                        backgroundColor: AppColor.getMain(),
                        title: Text(AppTranslationConstants.updateCoverImage.tr),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text(
                                AppTranslationConstants.uploadImage.tr
                            ),
                            onPressed: () async {
                              await _.handleAndUploadImage(UploadImageType.cover);
                            }
                          ),
                          SimpleDialogOption(
                            child: Text(AppTranslationConstants.cancel.tr),
                            onPressed: () => Get.back()
                          ),
                        ],
                      );
                    }
                  ),
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  heightFactor: 1.08,
                  child: Column(
                    children: <Widget>[
                      Hero(
                        tag: _.profile.name,
                        child: GestureDetector(
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(_.profile.photoUrl.isNotEmpty
                                ? _.profile.photoUrl : AppFlavour.getNoImageUrl(),),
                            radius: 50.0,
                          ),
                          onTap: () => Get.toNamed(AppRouteConstants.profileEdit),
                        ),
                      ),
                      buildFollowerInfo(context, _.profile),
                      AppTheme.heightSpace20,
                      Container(
                        padding: const EdgeInsets.all(AppTheme.padding20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_.profile.name.capitalize!,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(color: Colors.white
                              ),
                            ),
                            (_.profile.genres?.isNotEmpty ?? false) ?
                            GenresGridView(
                              _.profile.genres?.keys.toList() ?? [],
                              AppColor.white,
                              alignment: Alignment.centerLeft,
                              fontSize: 15,
                            ) : Container(),
                            Row(
                              children: <Widget>[
                                Text(_.location.isNotEmpty ? _.location : AppTranslationConstants.notSpecified.tr,
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
                            Text(_.profile.aboutMe.isEmpty
                                ? AppTranslationConstants.noProfileDesc.tr : _.profile.aboutMe.capitalizeFirst!,
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(fontSize: 16),
                              textAlign: TextAlign.justify,
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
                                  Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} (${_.profile.posts?.length ?? 0})'),
                                  Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} (${AppFlavour.appInUse == AppInUse.cyberneom ?
                                  _.totalPresets.length : _.totalItems.length})'),
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
                                  children: AppFlavour.appInUse == AppInUse.cyberneom
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
