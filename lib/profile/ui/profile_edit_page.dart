import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'profile_controller.dart';

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.profileDetails.tr),
        body: SingleChildScrollView(
          child: Container(
            decoration: AppTheme.appBoxDecoration,
            height: AppTheme.fullHeight(context),
            child: Column(
              children: <Widget>[
                SizedBox(
                    height: AppTheme.fullHeight(context)/4,
                    child: Stack(
                        fit: StackFit.loose,
                        alignment: Alignment.center,
                        children: <Widget>[
                          _.profile.photoUrl.isEmpty ? const Icon(
                              Icons.account_circle,
                              size: 150.0,
                              color: Colors.grey
                          ) : GestureDetector(
                            child: Container(
                              width: 125.0,
                              height: 125.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(_.profile.photoUrl)
                                ),
                              ),
                            ),
                            onTap: () {
                              Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [_.profile.photoUrl]);
                            }
                          ),
                          _.isLoading ? const Center(child: CircularProgressIndicator())
                            : Positioned(
                              bottom: AppTheme.padding20,
                              left: 0,
                              child: FloatingActionButton(
                                heroTag: AppHeroTagConstants.floatingButton1,
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context){
                                    return SimpleDialog(
                                      backgroundColor: AppColor.getMain(),
                                      title: Text(AppTranslationConstants.updateProfilePicture.tr),
                                      children: <Widget>[
                                        SimpleDialogOption(
                                          child: Text(
                                            AppTranslationConstants.uploadImage.tr
                                          ),
                                          onPressed: () async {
                                            await _.handleAndUploadImage(UploadImageType.profile);
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
                                mini: true,
                                child: const Icon(Icons.camera_alt),
                              )
                          ),
                        ]
                    )
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          padding: const EdgeInsets.only(
                              left: AppTheme.padding25,
                              right: AppTheme.padding25
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                AppTranslationConstants.profileInformation.tr,
                                style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              Obx(()=> _.editStatus ? Container()
                              : FloatingActionButton(
                                heroTag: AppHeroTagConstants.floatingButton2,
                                onPressed: () => {
                                  _.changeEditStatus()
                                },
                                mini: true,
                                child: const Icon(Icons.edit,
                                  size: 20,
                                ),
                              ),),
                            ],
                          )
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: AppTheme.padding25,
                            right: AppTheme.padding25,
                            top: AppTheme.padding10),
                        child: Text(
                          AppTranslationConstants.name.tr,
                          style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                          padding: const EdgeInsets.only(
                              left: AppTheme.padding25,
                              right: AppTheme.padding25),
                          child: Obx(()=> TextField(
                            controller: _.nameController,
                            enabled: _.editStatus,
                            autofocus: _.editStatus,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: AppTheme.padding25,
                            right: AppTheme.padding25,
                            top: AppTheme.padding10),
                        child: Text(
                          AppTranslationConstants.aboutMe.tr,
                          style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: AppTheme.padding25,
                            right: AppTheme.padding25
                        ),
                        child: TextField(
                          maxLines: 4,
                          controller: _.aboutMeController,
                          enabled: _.editStatus,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: AppTheme.padding25,
                            right: AppTheme.padding25,
                            top: AppTheme.padding10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Text(
                                AppTranslationConstants.eventReason.tr,
                                style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                                ),
                              Text(
                                AppTranslationConstants.profileType.tr,
                                style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]
                          ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: AppTheme.padding25,
                            right: AppTheme.padding25,
                            top: AppTheme.padding10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(_.profile.reason.name.tr),
                            Text(_.profile.type.value.tr.capitalize ?? ""),
                          ],
                        ),
                      ),
                      Obx(()=> !_.editStatus ? Container() :
                      Container(
                        padding: const EdgeInsets.only(
                            left: AppTheme.padding25,
                            right: AppTheme.padding25,
                            top: AppTheme.padding20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.bondiBlue75,
                                padding: const EdgeInsets.symmetric(horizontal: 50),
                                textStyle: const TextStyle(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                              ),
                              onPressed: () async {
                                await _.updateProfileData();
                              },
                              child: Text(AppTranslationConstants.save.tr),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.getMain(),
                                padding: const EdgeInsets.symmetric(horizontal: 50),
                                textStyle: const TextStyle(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                              ),
                              onPressed: () {
                                _.changeEditStatus();
                              },
                              child: Text(AppTranslationConstants.cancel.tr),
                            ),
                          ],
                        ),
                      )
                      ),
                    ],
                  )
                ],
              ),
          ),
        ),
      ),
    );
  }
}
