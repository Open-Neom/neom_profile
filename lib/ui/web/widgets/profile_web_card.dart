import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_ytmusic/ui/widgets/influences_grid_view.dart';
import 'package:neom_commons/ui/widgets/profile_completion_indicator.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/ui/widgets/web/web_theme_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:sint/sint.dart';

import '../../profile_controller.dart';
import '../../widgets/profile_widgets.dart';

class ProfileWebCard extends StatelessWidget {

  final ProfileController controller;

  const ProfileWebCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile.value;

    return Container(
      width: 320,
      decoration: WebThemeConstants.glassCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => AuthGuard.protect(context, () async {
                  await controller.showUpdateCoverImgDialog(context);
                }),
                child: HandledCachedNetworkImage(
                  profile.coverImgUrl.isNotEmpty
                      ? profile.coverImgUrl
                      : profile.photoUrl.isNotEmpty
                          ? profile.photoUrl
                          : AppProperties.getNoImageUrl(),
                  width: 280,
                  height: 160,
                  fit: BoxFit.cover,
                  enableFullScreen: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Avatar
            GestureDetector(
              onTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
              child: ClipOval(
                child: HandledCachedNetworkImage(
                  profile.photoUrl.isNotEmpty
                      ? profile.photoUrl
                      : AppProperties.getAppLogoUrl(),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  enableFullScreen: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name + verification
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    TextUtilities.capitalizeFirstLetter(profile.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (profile.verificationLevel != VerificationLevel.none) ...[
                  AppTheme.widthSpace5,
                  AppFlavour.getVerificationIcon(profile.verificationLevel, size: 16),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Location
            GestureDetector(
              onTap: () => AuthGuard.protect(context, () => controller.updateLocation()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    controller.location.isNotEmpty
                        ? controller.location.length > CoreConstants.maxLocationNameLength
                            ? '${controller.location.substring(0, CoreConstants.maxLocationNameLength)}...'
                            : controller.location
                        : AppTranslationConstants.notSpecified.tr,
                    style: TextStyle(color: AppColor.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Followers
            buildFollowerInfo(context, profile),
            const SizedBox(height: 16),
            // Bio
            ReadMoreContainer(
              padding: 0,
              text: profile.aboutMe.isEmpty
                  ? CommonTranslationConstants.noProfileDesc.tr
                  : TextUtilities.capitalizeFirstLetter(profile.aboutMe),
            ),
            const SizedBox(height: 12),
            // Genres
            if (profile.genres?.isNotEmpty ?? false)
              GenresGridView(
                profile.genres?.keys.toList() ?? [],
                AppColor.white,
                alignment: Alignment.center,
                fontSize: 11,
              ),
            // Influences
            if (profile.influences?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              InfluencesGridView(influences: profile.influences!),
            ],
            const SizedBox(height: 16),
            // Edit button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Sint.toNamed(AppRouteConstants.profileEdit),
                icon: const Icon(Icons.edit, size: 16),
                label: Text(AppTranslationConstants.edit.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppColor.borderMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Profile completion
            ProfileCompletionIndicator(
              profile: profile,
              onPhotoTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
              onCoverTap: () => AuthGuard.protect(context, () => controller.showUpdateCoverImgDialog(context)),
              onBioTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
              onLocationTap: () => AuthGuard.protect(context, () => controller.updateLocation()),
              onGenresTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
              onSlugTap: () => Sint.toNamed(AppRouteConstants.profileEdit),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
