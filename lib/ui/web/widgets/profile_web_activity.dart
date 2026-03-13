import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/widgets/web/web_theme_constants.dart';
import 'package:neom_commons/utils/constants/app_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/profile_constants.dart';
import '../../profile_controller.dart';

class ProfileWebActivity extends StatelessWidget {

  final ProfileController controller;

  const ProfileWebActivity({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: WebThemeConstants.glassCard,
      child: DefaultTabController(
        length: AppConstants.profileTabs.length,
        child: Obx(() => Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: '${AppConstants.profileTabs.elementAt(0).tr} (${controller.profile.value.posts?.length ?? 0})'),
                Tab(text: '${AppConstants.profileTabs.elementAt(1).tr} (${AppConfig.instance.appInUse == AppInUse.c ?
                    controller.totalPresets.length : controller.totalMixedItems.length})'),
                Tab(text: '${AppConstants.profileTabs.elementAt(2).tr} (${controller.events.length})'),
              ],
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: EdgeInsets.zero,
              dividerColor: AppColor.borderSubtle,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: TabBarView(
                children: (AppConfig.instance.appInUse == AppInUse.c || AppConfig.instance.appInUse == AppInUse.o)
                    ? ProfileConstants.neomProfileTabPages
                    : ProfileConstants.profileTabPages,
              ),
            ),
          ],
        )),
      ),
    );
  }
}
