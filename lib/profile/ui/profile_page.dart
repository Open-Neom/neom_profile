import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/static/genres_format.dart';
import 'package:neom_commons/core/ui/widgets/diagonally_cut_colored_image.dart';
import 'package:neom_commons/core/ui/widgets/position_back_button.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/url_constants.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
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
                          ? _.profile.photoUrl : UrlConstants.noImageUrl),
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
                              await _.handleAndUploadImage(AppFileFrom.gallery, UploadImageType.cover);
                            }

                          ),
                          SimpleDialogOption(
                            child: Text(
                                AppTranslationConstants.cancel.tr
                            ),
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
                                ? _.profile.photoUrl : UrlConstants.noImageUrl),
                            radius: 50.0,
                          ),
                          onTap: () => Get.toNamed(AppRouteConstants.profileEdit),
                        ),
                      ),
                      buildFollowerInfo(context, _.profile),
                      AppTheme.heightSpace20,
                      Container(
                        padding: const EdgeInsets.all(AppTheme.padding25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_.profile.name.capitalize!,
                              style: Theme.of(context).textTheme.headline6!
                                  .copyWith(color: Colors.white
                              ),
                            ),
                            GenresFormat(
                              _.profile.genres?.keys.toList() ?? [],
                              AppColor.white,
                              alignment: Alignment.centerLeft,
                              fontSize: 15,
                            ),
                            Row(
                              children: <Widget>[
                                Text(_.location.isNotEmpty ? _.location : AppTranslationConstants.notSpecified.tr,
                                  style: Theme.of(context).textTheme.subtitle1,
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
                                ? AppTranslationConstants.noProfileDesc.tr : _.profile.aboutMe.capitalize!,
                                style: Theme.of(context).textTheme.bodyText2!
                                    .copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.padding20),
                        child: DefaultTabController(
                          length: AppConstants.profileTabs.length,
                          child: Obx(() => Column(
                            children: <Widget>[
                              TabBar(
                                tabs: [Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} (${_.profile.posts?.length ?? 0})'),
                                      Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} (${_.profile.appItems?.length ?? 0})'),
                                      Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} (${_.profile.events?.length ?? 0})'),],
                                indicatorColor: Colors.white,
                                labelStyle: const TextStyle(fontSize: 15),
                                unselectedLabelStyle: const TextStyle(fontSize: 12),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                              ),
                              SizedBox(
                                height: 300,
                                child: TabBarView(
                                  children: ProfileConstants.profileTabPages,
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
