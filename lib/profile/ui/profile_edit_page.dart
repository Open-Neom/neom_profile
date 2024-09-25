import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_hero_tag_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'profile_controller.dart';

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.profileDetails.tr),
        backgroundColor: AppColor.main50,
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
                          _.profile.value.photoUrl.isEmpty ? const Icon(
                              Icons.account_circle,
                              size: 150.0,
                              color: Colors.grey
                          ) : GestureDetector(
                            child: Container(
                              width: 150.0,
                              height: 150.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(_.profile.value.photoUrl)
                                ),
                              ),
                            ),
                            onTap: () async {
                              await _.showUpdatePhotoDialog(context);
                              ///DEPRECATED
                              // Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [_.profile.value.photoUrl]);
                            }
                          ),
                          _.isLoading.value ? const Center(child: CircularProgressIndicator())
                            : Positioned(
                              bottom: AppTheme.padding20,
                              left: 0,
                              child: FloatingActionButton(
                                onPressed: () async => await _.showUpdatePhotoDialog(context),
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
                      Padding(
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
                              Obx(()=> _.editStatus.value ? const SizedBox.shrink()
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
                      AppTheme.heightSpace10,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding25),
                        child: Text(
                          AppTranslationConstants.name.tr,
                          style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding25),
                          child: Obx(()=> TextField(
                            controller: _.nameController,
                            enabled: _.editStatus.value,
                            autofocus: _.editStatus.value,
                          ),
                        ),
                      ),
                      AppTheme.heightSpace10,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding25),
                        child: Text(AppTranslationConstants.aboutMe.tr,
                          style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding25),
                        child: TextField(
                          minLines: 2,
                          maxLines: 5,
                          controller: _.aboutMeController,
                          enabled: _.editStatus.value,
                        ),
                      ),
                      AppTheme.heightSpace20,
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding25),
                          child: Column(
                            children: [
                              !_.editStatus.value ?
                              Column(
                                children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(AppTranslationConstants.profileType.tr,
                                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                        ),
                                        Text(_.profile.value.type.value.tr.capitalize,
                                            style: const TextStyle(
                                                fontSize: 16.0, decoration: TextDecoration.underline
                                            )
                                        ),
                                      ]
                                  ),
                                  AppTheme.heightSpace20,
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          AppTranslationConstants.preferenceToPlay.tr,
                                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                        ),
                                        Text(_.profile.value.reason.name.tr,
                                            style: const TextStyle(
                                                fontSize: 16.0, decoration: TextDecoration.underline
                                            )
                                        ),
                                      ]
                                  ),
                                  AppTheme.heightSpace20,
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(AppTranslationConstants.instruments.tr,
                                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          width: AppTheme.fullWidth(context)*0.5,
                                          child: Text(_.profile.value.instruments != null ?  _.profile.value.instruments!.keys.where((instr) => instr != AppTranslationConstants.moderator && instr != AppTranslationConstants.moderator.tr)
                                              .map((instr) => instr.tr)
                                              .join(', ').capitalizeFirst : '',
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                  fontSize: 16.0, decoration: TextDecoration.underline,
                                              )
                                          ),
                                        )

                                      ]
                                  ),

                                  AppTheme.heightSpace20,
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          AppTranslationConstants.mainInstrument.tr,
                                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                        ),
                                        Text(_.profile.value.mainFeature.tr.capitalize,
                                            style: const TextStyle(
                                                fontSize: 16.0, decoration: TextDecoration.underline
                                            )
                                        ),
                                      ]
                                  ),
                                ],
                              ) : Center(child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.main50,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  textStyle: const TextStyle(color: Colors.white),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(width: 1, color: Colors.white54), // Borde blanco
                                      borderRadius: BorderRadius.circular(20.0)),
                                ),
                                onPressed: () {
                                  Get.toNamed(AppRouteConstants.instrumentsFav);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(AppFlavour.getInstrumentIcon(), size: 16,),
                                    AppTheme.widthSpace10,
                                    Text(AppTranslationConstants.instrumentsPreferences.tr, style: const TextStyle(fontSize: 16.0)),
                                  ],
                                )
                              ),),
                            ],
                          )
                      ),
                      Obx(()=> !_.editStatus.value ? const SizedBox.shrink() :
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppTheme.padding25,
                          right: AppTheme.padding25,
                          top: AppTheme.padding20
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.bondiBlue75,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                textStyle: const TextStyle(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                              ),
                              onPressed: () async {
                                await _.updateProfileData();
                              },
                              child: Text(AppTranslationConstants.save.tr, style: const TextStyle(fontSize: 16.0)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.main75,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                textStyle: const TextStyle(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0)),
                              ),
                              onPressed: () {
                                _.changeEditStatus();
                              },
                              child: Text(AppTranslationConstants.cancel.tr, style: const TextStyle(fontSize: 16.0)),
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
