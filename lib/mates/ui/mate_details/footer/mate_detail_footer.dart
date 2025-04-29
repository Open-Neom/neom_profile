import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

// ignore: unused_import
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import '../../../utils/mate_constants.dart';
import '../mate_details_controller.dart';

class MateShowcase extends StatelessWidget {
  const MateShowcase({super.key});

  @override
  Widget build(BuildContext context) {

    late MateDetailsController controller;

    if (Get.isRegistered<MateDetailsController>()) {
      controller = Get.find<MateDetailsController>();
    } else {
      controller = Get.put(MateDetailsController());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DefaultTabController(
        length: AppConstants.profileTabs.length,
        child: Column(
          children: <Widget>[
            TabBar(
              tabs: [
                Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} ${controller.matePosts.isNotEmpty ? '(${controller.matePosts.length})':''}'),
                Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} ${controller.totalPresets.isEmpty && controller.totalMediaItems.length+controller.totalReleaseItems.length==0
                    ? '': '(${AppFlavour.appInUse == AppInUse.c ?
                controller.totalPresets.length : (controller.totalMediaItems.length + controller.totalReleaseItems.length)})'}'),
                Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} ${controller.events.isEmpty ? '' : '(${controller.events.length})'}')
              ],
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            ),
            SizedBox(
              height: AppTheme.fullHeight(context)/2.5,
              child: TabBarView(
                children: AppFlavour.appInUse == AppInUse.c
                  ? MateConstants.neomMateTabPages : MateConstants.mateTabPages,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
