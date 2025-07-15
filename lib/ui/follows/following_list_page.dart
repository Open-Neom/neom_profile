import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/data/implementations/mate_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';



class FollowingListPage extends StatelessWidget {
  const FollowingListPage({super.key});


  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateController>(
      id: AppPageIdConstants.following,
      init: MateController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        appBar:AppBarChild(title: AppTranslationConstants.following.tr),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: _.mates.isEmpty ?
          const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _.mates.length,
          itemBuilder: (context, index) {
            AppProfile mate = _.mates.values.elementAt(index);
            return mate.name.isNotEmpty ? GestureDetector(
              child: ListTile(
                onTap: () => _.getMateDetails(mate),
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
                    Text(mate.favoriteItems?.length.toString() ?? ""),
                     Icon(AppFlavour.getAppItemIcon(),
                      color: Colors.blueGrey, size: 20,),
                    Text(mate.mainFeature.tr.capitalize),
                  ]),
                ),
              onLongPress: () => {},
            ) : const SizedBox.shrink();
          },
        ),
      )
    ));
  }
}
