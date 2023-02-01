import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import '../profile_controller.dart';

class ProfileItems extends StatelessWidget {
  const ProfileItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (_) => SizedBox(
        width: double.infinity,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          itemCount: _.totalItems.length,
          itemBuilder: (context, index) {
            String itemKey = _.totalItems.keys.elementAt(index);
            AppItem appItem = _.totalItems[itemKey]!;
            return GestureDetector(
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                title: Text(appItem.name.isEmpty ? "" : appItem.name),
                subtitle: Row(children: [Text(appItem.artist.isEmpty ? ""
                    : appItem.artist.length > AppConstants.maxArtistNameLength ? "${appItem.artist.substring(0,AppConstants.maxArtistNameLength)}...": appItem.artist),
                  const SizedBox(width:5,),
                  RatingBar(
                    initialRating: appItem.state.toDouble(),
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
                onTap: () => _.getItemDetails(appItem),
                leading: Hero(
                  tag: CoreUtilities.getAppItemHeroTag(index),
                  child: Image.network(appItem.albumImgUrl.isNotEmpty ? appItem.albumImgUrl
                    : AppFlavour.getNoImageUrl(), width: 50.0)
                ),
              ),
            );
          },
        ),
      )
    );
  }
}
