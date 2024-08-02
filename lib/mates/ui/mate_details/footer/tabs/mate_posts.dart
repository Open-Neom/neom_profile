
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/ui/widgets/post_tile.dart';
import 'package:neom_commons/core/utils/constants/app_assets.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/post_type.dart';
import '../../mate_details_controller.dart';

class MatePosts extends StatelessWidget {
  const MatePosts({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
        id: AppPageIdConstants.mate,
        init: MateDetailsController(),
        builder: (_) {
          if (_.isLoadingPosts) {
            return const Center(child: CircularProgressIndicator());
          } else if (_.matePosts.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(top: 10, bottom: 10.0),
                  child: Text(
                    AppTranslationConstants.noPostsYet.tr,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Image.asset(AppAssets.noPostsMate, height: 175),
              ],
            );
          } else {
            List<GridTile> gridTiles = [];
            for (var post in _.matePosts) {
              Event event = _.eventPosts[post] ?? Event();
              if(post.type != PostType.caption) {
                gridTiles.add(
                    GridTile(
                        child: PostTile(post, event)
                    )
                );
              }

            }
            return GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1,
              children: gridTiles);
          }
        }
    );
  }

}
