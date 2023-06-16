import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import '../../../utils/mate_constants.dart';
import '../mate_details_controller.dart';

class MateShowcase extends StatelessWidget {
  const MateShowcase({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DefaultTabController(
            length: AppConstants.profileTabs.length,
            child: Obx(() => Column(
              children: <Widget>[
                TabBar(
                  tabs: [
                    Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} (${_.matePosts.length})'),
                    Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} (${_.totalItems.length})'),
                    Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} (${_.events.length})')
                  ],
                  indicatorColor: Colors.white,
                  labelStyle: const TextStyle(fontSize: 15),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                ),
                SizedBox.fromSize(
                  size: const Size.fromHeight(300.0),
                  child: TabBarView(
                    children: MateConstants.mateTabPages,
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      }
    );
  }
}
