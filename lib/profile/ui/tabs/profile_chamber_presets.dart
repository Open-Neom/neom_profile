import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import '../profile_controller.dart';

class ProfileChamberPresets extends StatelessWidget {
  const ProfileChamberPresets({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (_) => SizedBox(
        width: double.infinity,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          itemCount: _.totalPresets.length,
          itemBuilder: (context, index) {
            String presetKey = _.totalPresets.keys.elementAt(index);
            ChamberPreset chamberPreset = _.totalPresets[presetKey]!;
            return GestureDetector(
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                title: Text(chamberPreset.name.isEmpty ? "${AppTranslationConstants.frequency.tr} ${chamberPreset.neomFrequency?.frequency} Hz" : chamberPreset.name),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      chamberPreset.neomParameter != null ?
                      Text("Vol: ${chamberPreset.neomParameter!.volume.toStringAsFixed(1)} | "
                          "X: ${chamberPreset.neomParameter!.x.toStringAsFixed(1)} | "
                          "Y:${chamberPreset.neomParameter!.y.toStringAsFixed(1)} | "
                          "Z:${chamberPreset.neomParameter!.z.toStringAsFixed(1)}")
                          : Text(AppTranslationConstants.rootFrequency.tr),
                  RatingBar(
                    initialRating: chamberPreset.state.toDouble(),
                    minRating: 1,
                    ignoreGestures: true,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    ratingWidget: RatingWidget(
                      full: CoreUtilities.ratingImage(AppAssets.heart),
                      half: CoreUtilities.ratingImage(AppAssets.heartHalf),
                      empty: CoreUtilities.ratingImage(AppAssets.heartBorder),
                    ),
                    itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                    itemSize: 15,
                    onRatingUpdate: (rating) {
                      _.logger.d("New Rating set to $rating");
                      },
                  ),]),
                leading: Hero(
                  tag: CoreUtilities.getAppItemHeroTag(index),
                  child: Image.network(chamberPreset.imgUrl.isNotEmpty ? chamberPreset.imgUrl
                    : AppFlavour.getNoImageUrl(), width: 50.0)
                ),
                onTap: () {
                  Get.toNamed(AppRouteConstants.generator,  arguments: [chamberPreset.clone()]);
                },
              ),
            );
          },
        ),
      )
    );
  }
}
