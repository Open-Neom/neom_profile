import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/web/web_breadcrumb.dart';
import 'package:neom_commons/ui/widgets/web/web_keyboard_manager.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_home/ui/web/left_sidebar.dart';
import 'package:sint/sint.dart';

import '../profile_controller.dart';
import 'widgets/profile_web_activity.dart';
import 'widgets/profile_web_card.dart';

class ProfileWebPage extends StatelessWidget {

  final ProfileController controller;

  const ProfileWebPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarExpanded = screenWidth > 1400;

    return WebKeyboardManager(
      pageId: 'profile',
      pageShortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyE): () =>
            Sint.toNamed(AppRouteConstants.profileEdit),
        const SingleActivator(LogicalKeyboardKey.escape): () => Sint.back(),
      },
      child: Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Row(
          children: [
            // Left sidebar (Instagram-style navigation)
            LeftSidebar(
              expanded: sidebarExpanded,
              currentTabIndex: -1,
              onTabSelected: (_) => Sint.offAllNamed(AppRouteConstants.home),
            ),

            // Main content
            Expanded(
              child: Container(
                decoration: AppTheme.appBoxDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: WebBreadcrumb(items: [
                        BreadcrumbItem(
                          label: AppTranslationConstants.home.tr,
                          icon: Icons.home_outlined,
                          onTap: () => Sint.back(),
                        ),
                        BreadcrumbItem(label: AppTranslationConstants.profile.tr),
                      ]),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileWebCard(controller: controller),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ProfileWebActivity(controller: controller),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
