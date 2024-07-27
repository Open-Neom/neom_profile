import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/core/ui/widgets/rating_heart_bar.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../profile_controller.dart';

class ProfileItems extends StatelessWidget {
  const ProfileItems({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      init: ProfileController(),
      builder: (_) => SizedBox(
        width: double.infinity,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          itemCount: _.totalMixedItems.length,
          itemBuilder: (context, index) {
            AppMediaItem appMediaItem = _.totalMixedItems.values.elementAt(index);
            return GestureDetector(
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                leading: HandledCachedNetworkImage(appMediaItem.imgUrl,
                  width: 50, enableFullScreen: false,
                ),
                title: Text(appMediaItem.name.isEmpty ? "" : appMediaItem.name),
                subtitle: Row(
                  children: [
                    Text(appMediaItem.artist.isEmpty ? ""
                    : appMediaItem.artist.length > AppConstants.maxArtistNameLength
                    ? "${appMediaItem.artist.substring(0,AppConstants.maxArtistNameLength)}..."
                    : appMediaItem.artist),
                    const SizedBox(width:5,),
                    RatingHeartBar(state: appMediaItem.state.toDouble(),),
                  ]
                ),
                onTap: () => _.getItemDetails(appMediaItem),
              ),
            );
          },
        ),
      )
    );
  }
}
