import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/widgets/post_tile.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/utils/enums/post_type.dart';

import '../profile_controller.dart';

class ProfilePosts extends StatelessWidget {
  const ProfilePosts({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profilePosts,
      // init: ProfileController(),
      builder: (_) {
        if (_.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (_.profilePosts.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10.0),
                child: Text(
                  CommonTranslationConstants.noPostsYet.tr,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              Image.asset(AppAssets.noPosts, height: 175),
            ],
          );
        } else {
          List<GridTile> gridTiles = [];
          for (var post in _.profilePosts) {
            if(post.type != PostType.caption && post.type != PostType.blogEntry) {
              Event event = _.eventPosts[post] ?? Event();
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
            children: gridTiles
          );
        }
      }
    );
  }
}
