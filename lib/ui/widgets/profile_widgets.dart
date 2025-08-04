import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';



Widget buildTitleLabel(BuildContext context, String title, String msg){
  return Padding(
      padding: const EdgeInsets.only(
          left: 25.0, right: 25.0, top: 15.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppTranslationConstants.username.tr,
                style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      )
  );
}

Widget buildFollowerInfo(context, AppProfile profile) {
  return Padding(
    padding: const EdgeInsets.only(top: AppTheme.padding10),
    child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            child: Text('${profile.following!.length.toString()} ${AppTranslationConstants.following.tr}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColor.white80)
            ),
            onTap: () => profile.following!.isNotEmpty
                ? Get.toNamed(AppRouteConstants.following, arguments: profile.following)
                : AppAlerts.showAlert(context, title: AppTranslationConstants.following.tr,
                message: MessageTranslationConstants.followingMsg.tr),
          ),
          Text(' | ', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColor.white80)
          ),
          GestureDetector(
            child: Text('${profile.followers!.length.toString()} ${AppTranslationConstants.followers.tr}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColor.white80)),
            onTap: () => profile.followers!.isNotEmpty
                ? Get.toNamed(AppRouteConstants.followers, arguments: profile.followers)
                : AppAlerts.showAlert(context, title: AppTranslationConstants.followers.tr,
                message: MessageTranslationConstants.followersMsg.tr),
          ),
        ],
      ),
      // Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       GestureDetector(
      //         child: Text('${profile.itemmates!.length.toString()} ${AppTranslationConstants.itemmates.tr}',
      //             style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColor.white80)),
      //         onTap: () => profile.itemmates!.isNotEmpty
      //             ? Get.toNamed(AppRouteConstants.mates, arguments: profile.itemmates)
      //             : AppUtilities.showAlert(context, AppTranslationConstants.itemmates.tr, AppTranslationConstants.itemmatesMsg.tr), //Get.toNamed(GigRouteConstants.SONGMATES, arguments: songmate.songmates),
      //       ),
      //       Text(' | ', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColor.white80)
      //       ),
      //       GestureDetector(
      //         child: Text('${profile.eventmates!.length.toString()} ${AppTranslationConstants.eventmates.tr}',
      //             style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColor.white80)),
      //         onTap: () => profile.eventmates!.isNotEmpty
      //             ? Get.toNamed(AppRouteConstants.mates, arguments: profile.eventmates)
      //             : AppUtilities.showAlert(context, AppTranslationConstants.eventmates.tr, AppTranslationConstants.eventmatesMsg.tr), //Get.toNamed(GigRouteConstants.SONGMATES, arguments: songmate.songmates),
      //       ),
      //     ]),
      const Divider()
    ]),
  );
}
