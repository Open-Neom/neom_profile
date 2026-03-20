import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_commons/ui/widgets/profile_completion_indicator.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/ui/widgets/web/web_theme_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/media_upload_destination.dart';
import 'package:neom_achievements/data/implementations/achievement_controller.dart';
import 'package:neom_achievements/ui/widgets/profile_badges_row.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_profile/utils/constants/profile_translation_constants.dart';
import 'package:sint/sint.dart';

import '../../profile_controller.dart';
import '../../widgets/profile_widgets.dart';

class ProfileWebCard extends StatelessWidget {

  final ProfileController controller;

  const ProfileWebCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile.value;
    final isEditing = controller.editStatus.value;

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
            // Avatar with camera overlay
            GestureDetector(
              onTap: () => AuthGuard.protect(context, () async {
                await controller.handleAndUploadImage(MediaUploadDestination.profile);
              }),
              child: Stack(
                children: [
                  // CachedCircleAvatar uses Image.network on web (Flutter-
                  // rendered), which ClipOval can actually clip — unlike
                  // HtmlElementView platform views that float above the canvas.
                  CachedCircleAvatar(
                    imageUrl: profile.photoUrl.isNotEmpty
                        ? profile.photoUrl
                        : AppProperties.getAppLogoUrl(),
                    radius: 50,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.bondiBlue75,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.scaffold, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Name + verification
            if (isEditing) ...[
              TextField(
                controller: controller.nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: ProfileTranslationConstants.profileDetails.tr,
                  hintStyle: TextStyle(color: AppColor.textSecondary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.borderMedium),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.borderMedium),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.bondiBlue75),
                  ),
                ),
              ),
            ] else ...[
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
            ],
            // Achievement badges
            Builder(builder: (_) {
              try {
                final ac = Sint.find<AchievementController>();
                final badgeIds = ac.unlockedAchievements
                    .map((p) => p.achievementId)
                    .toList();
                if (badgeIds.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ProfileBadgesRow(badgeIds: badgeIds),
                  );
                }
              } catch (_) {}
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 8),
            // Slug (only in edit mode)
            if (isEditing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('@', style: TextStyle(color: AppColor.textSecondary, fontSize: 14)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller.slugController,
                      style: TextStyle(color: AppColor.textSecondary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'username',
                        hintStyle: TextStyle(color: AppColor.textSecondary.withValues(alpha: 0.5)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColor.borderMedium),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColor.borderMedium),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColor.bondiBlue75),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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
            // Bio — editable or read-only
            if (isEditing) ...[
              TextField(
                controller: controller.aboutMeController,
                maxLines: 4,
                minLines: 2,
                maxLength: 150,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: CommonTranslationConstants.noProfileDesc.tr,
                  hintStyle: TextStyle(color: AppColor.textSecondary.withValues(alpha: 0.5)),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.borderMedium),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.borderMedium),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColor.bondiBlue75),
                  ),
                ),
              ),
            ] else ...[
              ReadMoreContainer(
                padding: 0,
                text: profile.aboutMe.isEmpty
                    ? CommonTranslationConstants.noProfileDesc.tr
                    : TextUtilities.capitalizeFirstLetter(profile.aboutMe),
              ),
            ],
            const SizedBox(height: 12),
            // Genres
            if (profile.genres?.isNotEmpty ?? false)
              GenresGridView(
                profile.genres?.keys.toList() ?? [],
                AppColor.white,
                alignment: Alignment.center,
                fontSize: 11,
              ),
            // Instruments (literary genres)
            if (profile.instruments?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: profile.instruments!.keys
                    .where((k) => k != 'moderator' && k != 'Moderador')
                    .map((instr) => Chip(
                          label: Text(instr.tr, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColor.surfaceBright,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ))
                    .toList(),
              ),
            ],
            // Influences
            if (AppConfig.instance.appInUse == AppInUse.g && (profile.influences?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Sint.toNamed(AppRouteConstants.influences, arguments: profile.influences),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Influences".tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Edit instruments/genres buttons (in edit mode)
            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Sint.toNamed(AppRouteConstants.instrumentsFav),
                  icon: Icon(AppFlavour.getInstrumentIcon(), size: 16),
                  label: Text(AppTranslationConstants.instrumentsPreferences.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: AppColor.borderMedium),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Edit / Save / Cancel buttons
            if (isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await controller.updateProfileData();
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(AppTranslationConstants.save.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.bondiBlue75,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.changeEditStatus(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppColor.borderMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(AppTranslationConstants.cancel.tr),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.changeEditStatus(),
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
            ],
            const SizedBox(height: 12),
            // Profile completion
            ProfileCompletionIndicator(
              profile: profile,
              onPhotoTap: () => AuthGuard.protect(context, () async {
                await controller.handleAndUploadImage(MediaUploadDestination.profile);
              }),
              onCoverTap: () => AuthGuard.protect(context, () => controller.showUpdateCoverImgDialog(context)),
              onBioTap: () => controller.changeEditStatus(),
              onLocationTap: () => AuthGuard.protect(context, () => controller.updateLocation()),
              onGenresTap: () => controller.changeEditStatus(),
              onSlugTap: () => controller.changeEditStatus(),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
