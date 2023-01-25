import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

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
  return Container(
    padding: const EdgeInsets.only(top: AppTheme.padding10),
    child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            child: Text('${profile.following!.length.toString()} ${AppTranslationConstants.following.tr}',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: AppColor.white80)
            ),
            onTap: () => profile.following!.isNotEmpty
                ? Get.toNamed(AppRouteConstants.following, arguments: profile.following)
                : AppUtilities.showAlert(context, AppTranslationConstants.following.tr, AppTranslationConstants.followingMsg.tr),
          ),
          Text(' | ', style: Theme.of(context).textTheme.subtitle1!.copyWith(color: AppColor.white80)
          ),
          GestureDetector(
            child: Text('${profile.followers!.length.toString()} ${AppTranslationConstants.followers.tr}',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: AppColor.white80)),
            onTap: () => profile.followers!.isNotEmpty
                ? Get.toNamed(AppRouteConstants.followers, arguments: profile.followers)
                : AppUtilities.showAlert(context, AppTranslationConstants.followers.tr, AppTranslationConstants.followersMsg.tr),
          ),
        ],
      ),
      const Divider()
    ]),
  );
}
