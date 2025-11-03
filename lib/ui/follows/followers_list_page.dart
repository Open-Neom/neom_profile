import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/data/implementations/mate_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';

class FollowersListPage extends StatelessWidget {
  const FollowersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateController>(
      id: AppPageIdConstants.followers,
      init: MateController(),
      builder: (controller) => Scaffold(
          backgroundColor: AppColor.main50,
      appBar: AppBarChild(title: AppTranslationConstants.followers.tr),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: Obx(() =>controller.isLoading.value ?
          const Center(child: CircularProgressIndicator(),)
            : ListView.builder(
          itemCount: controller.mates.length,
          itemBuilder: (context, index) {
            AppProfile mate = controller.mates.values.elementAt(index);
            return mate.name.isNotEmpty ? GestureDetector(
              child: ListTile(
                onTap: () => controller.getMateDetails(mate),
                leading: Hero(
                  tag: mate.photoUrl,
                    child: FutureBuilder<CachedNetworkImageProvider>(
                      future: AppUtilities.handleCachedImageProvider(mate.photoUrl),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return CircleAvatar(backgroundImage: snapshot.data);
                        } else {
                          return const CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: CircularProgressIndicator()
                          );
                        }
                      },
                    )
                ),
                title: Text(mate.name),
                subtitle: Row(
                  children: [
                    if(mate.favoriteItems?.isNotEmpty ?? false) Text(mate.favoriteItems!.length.toString()),
                    Icon(AppFlavour.getAppItemIcon(),
                      color: Colors.blueGrey, size: 20,),
                    Text(mate.mainFeature.tr.capitalize),
                  ]),
                ),
              onLongPress: () => {},
            ) : const SizedBox.shrink();
          },
        ),),
      )
    ));
  }
}
