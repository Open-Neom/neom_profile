// ignore_for_file: unused_import, use_build_context_synchronously

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/menu_three_dots.dart';
import 'package:neom_commons/core/ui/reports/report_controller.dart';
import 'package:neom_commons/core/ui/widgets/custom_image.dart';
import 'package:neom_commons/core/ui/widgets/diagonally_cut_colored_image.dart';
import 'package:neom_commons/core/ui/widgets/position_back_button.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/url_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/reference_type.dart';
import 'package:neom_commons/core/utils/enums/report_type.dart';
import 'package:neom_commons/core/utils/enums/user_role.dart';
import 'package:neom_timeline/timeline/ui/widgets/timeline_widgets.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../mate_details_controller.dart';

class MateDetailHeader extends StatelessWidget {
  const MateDetailHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (_) => Stack(
      children: <Widget>[
        FutureBuilder(
          future: CoreUtilities().isAvailableMediaUrl(_.mate.coverImgUrl.isNotEmpty ?
            _.mate.coverImgUrl : _.mate.photoUrl.isNotEmpty
            ? _.mate.photoUrl : AppFlavour.getNoImageUrl()),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
                return DiagonallyCutColoredImage(
                  Image(
                      image: NetworkImage(
                          (snapshot.data == true) ?
                          (_.mate.coverImgUrl.isNotEmpty ?
                      _.mate.coverImgUrl : _.mate.photoUrl.isNotEmpty
                          ? _.mate.photoUrl : AppFlavour.getNoImageUrl()) : AppFlavour.getNoImageUrl(),),
                      width: MediaQuery.of(context).size.width,
                      height: 250.0,
                      fit: BoxFit.cover,
                      errorBuilder:  (context, object, error) => Image.network(AppFlavour.getNoImageUrl())
                  ),
                  color: AppColor.cutColoredImage,);
            } else {
              return Container();
            }
          },
        ),
        Align(
          alignment: FractionalOffset.bottomCenter,
          heightFactor: 1.25,
          child: Column(
            children: <Widget>[
              Hero(
                tag: _.mate.name,
                child: FutureBuilder(
                  future: CoreUtilities().isAvailableMediaUrl(_.mate.photoUrl.isNotEmpty
                      ? _.mate.photoUrl : AppFlavour.getNoImageUrl(),),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage((snapshot.data == true) ?
                        (_.mate.photoUrl.isNotEmpty ? _.mate.photoUrl : AppFlavour.getNoImageUrl())
                            : AppFlavour.getNoImageUrl(),),
                        radius: 60.0,
                        onBackgroundImageError: (object, error) => CachedNetworkImageProvider(_.mate.photoUrl.isNotEmpty ? _.mate.photoUrl
                            : AppFlavour.getNoImageUrl(),),
                      );
                    } else {
                      return const CircleAvatar(
                        radius: 60.0,
                        child: Center(child: CircularProgressIndicator()),
                      );

                    }
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(children: const [
                  // TODO VERIFY IF SHOWING FOLLOWERS FOLLOWING
                  Divider()
                ]),
              ),
              AppTheme.heightSpace10,
              AppFlavour.appInUse != AppInUse.emxi || _.mateBlogEntries.isEmpty
                  ? Container() : TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    padding: EdgeInsets.zero
                ),
                child: AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [
                    FlickerAnimatedText(">> Ver Blog <<",
                        textStyle: const TextStyle(
                            fontSize: 18,
                            decoration: TextDecoration.underline
                        )
                    ),
                  ],
                  onTap: () {
                    Get.toNamed(AppRouteConstants.mateBlog, arguments: [_.mate]);
                  },
                ),
                onPressed: () => {

                },
              ),
              Container(
                padding: EdgeInsets.only(
                  top: _.mateBlogEntries.isEmpty ? 40.0 : 20.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: AppTheme.appBoxDecorationBlueGrey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.0),
                        child: MaterialButton(
                          minWidth: 140.0,
                          color: Colors.transparent,
                          child: _.following ? Text(AppTranslationConstants.unfollow.tr.toUpperCase()) :
                          Text(AppTranslationConstants.follow.tr.toUpperCase()),
                          onPressed: () {
                            _.following ? _.unfollow() : _.follow();
                          },
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: AppTheme.appBoxDecorationBlueGrey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.0),
                        child: MaterialButton(
                          minWidth: 140.0,
                          color: Colors.transparent,
                          child: Text(AppTranslationConstants.message.tr.toUpperCase()),
                          onPressed: () {
                            _.sendMessage();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 25, right: 10, left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BackButton(color: Colors.white),
              IconButton(
                  onPressed: () => showModalBottomSheet(
                      backgroundColor: AppTheme.canvasColor75(context),
                      context: context,
                      builder: (context) {
                        return _buildDotsMenu(context, _.mate, _.userController.user!.userRole);
                      }
                  ),
                  icon: const Icon(FontAwesomeIcons.ellipsisVertical, size: 20)
              ),
            ]
        ),),
      ],
    ));
  }
}

Widget _buildDotsMenu(BuildContext context, AppProfile itemmate, UserRole userRole) {

  List<Menu3DotsModel> listMore = [];
  listMore.add(Menu3DotsModel(AppTranslationConstants.reportProfile.tr, AppTranslationConstants.reportPostMsg,
      Icons.info, AppTranslationConstants.reportProfile));
  listMore.add(Menu3DotsModel(AppTranslationConstants.blockProfile.tr, AppTranslationConstants.blockProfileMsg,
      Icons.block, AppTranslationConstants.blockProfile));

  if(userRole != UserRole.subscriber) {
    //TODO
    // listMore.add(Menu3DotsModel(GigTranslationConstants.removeProfile.tr, GigTranslationConstants.removeProfileMsg,
    //     Icons.delete, GigTranslationConstants.removeProfile));
  }

  return Container(
      height: userRole == UserRole.subscriber ? 160 : 220,
      decoration: BoxDecoration(
        color: AppColor.main50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: ListView.builder(
          itemCount: listMore.length,
          itemBuilder: (BuildContext context, int index){
            return ListTile(
              title: Text(listMore[index].title.tr, style: const TextStyle(fontSize: 18)),
              subtitle: Text(listMore[index].subtitle.tr),
              leading: Icon(listMore[index].icons, size: 20, color: Colors.white),
              onTap: () async {
                switch (listMore[index].action) {
                  case AppTranslationConstants.reportProfile:
                    ReportController reportController = Get.put(ReportController());
                    //_.alreadySent ? {} :
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.sendReport.tr,
                        content: Column(
                          children: <Widget>[
                            Obx(()=>
                                DropdownButton<String>(
                                  items: ReportType.values.map((ReportType reportType) {
                                    return DropdownMenuItem<String>(
                                      value: reportType.name,
                                      child: Text(reportType.name.tr),
                                    );
                                  }).toList(),
                                  onChanged: (String? reportType) {
                                    reportController.setReportType(reportType ?? "");
                                  },
                                  value: reportController.reportType,
                                  alignment: Alignment.center,
                                  icon: const Icon(Icons.arrow_downward),
                                  iconSize: 20,
                                  elevation: 16,
                                  style: const TextStyle(color: Colors.white),
                                  dropdownColor: AppColor.main75,
                                  underline: Container(
                                    height: 1,
                                    color: Colors.grey,
                                  ),
                                ),
                            ),
                            TextField(
                              onChanged: (text) {
                                reportController.setMessage(text);
                              },
                              decoration: InputDecoration(
                                  labelText: AppTranslationConstants.message.tr
                              ),
                            ),
                          ],
                        ),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              if(!reportController.isButtonDisabled) {
                                await reportController.sendReport(ReferenceType.profile, itemmate.id);
                                AppUtilities.showAlert(context, AppTranslationConstants.report.tr, AppTranslationConstants.hasSentReport.tr);
                              }
                            },
                            child: Text(AppTranslationConstants.send.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                    break;
                  case AppTranslationConstants.blockProfile:
                    MateDetailsController itemmateDetailsController = Get.put(MateDetailsController());
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.blockProfile.tr,
                        content: Column(
                          children: [
                            Text(AppTranslationConstants.blockProfileMsg.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                            AppTheme.heightSpace10,
                            Text(AppTranslationConstants.blockProfileMsg2.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                        ],),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              Get.back();
                            },
                            child: Text(AppTranslationConstants.goBack.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              if(!itemmateDetailsController.isButtonDisabled) {
                                await itemmateDetailsController.blockProfile();
                                AppUtilities.showAlert(context, AppTranslationConstants.blockProfile.tr, AppTranslationConstants.blockedProfileMsg.tr);
                              }
                            },
                            child: Text(AppTranslationConstants.toBlock.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                    break;
                  case AppTranslationConstants.removeProfile:
                    Get.snackbar(AppTranslationConstants.underConstruction.tr,
                        AppTranslationConstants.underConstructionMsg.tr,
                        snackPosition: SnackPosition.bottom
                    );
                    break;
                }
                //Get.back();
              },
            );
          })
  );
}
