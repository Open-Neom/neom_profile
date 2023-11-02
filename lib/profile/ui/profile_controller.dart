import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/firestore/event_firestore.dart';
import 'package:neom_commons/core/data/firestore/post_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/firestore/user_firestore.dart';
import 'package:neom_commons/core/data/implementations/geolocator_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_frequencies/frequencies/data/firestore/frequency_firestore.dart';
import 'package:neom_music_player/ui/player/media_player_page.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';

import '../domain/use_cases/profile_service.dart';

class ProfileController extends GetxController implements ProfileService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final loginController = Get.find<LoginController>();

  final Rx<AppProfile> profile = AppProfile().obs;
  final RxBool editStatus = false.obs;
  final RxString location = "".obs;
  final RxBool isLoading = true.obs;

  final RxMap<String, AppMediaItem> totalMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> totalReleaseItems = <String, AppReleaseItem>{}.obs;
  final RxMap<String, ChamberPreset> totalPresets = <String, ChamberPreset>{}.obs;

  final RxList<Post> profilePosts = <Post>[].obs;
  final RxMap<String, Event> events = <String, Event>{}.obs;
  final RxMap<Post, Event> eventPosts = <Post, Event>{}.obs;

  int postCount = 0;
  bool isFollowing = false;

  final postUploadController = Get.put(PostUploadController());

  TextEditingController nameController = TextEditingController();
  TextEditingController aboutMeController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  String profileName = "";
  String profileAboutMe = "";
  bool aboutMeValid = true;
  bool isValidName = true;



  @override
  void onInit() async {
    super.onInit();
    logger.t("Profile Controller");

    try {
        profile.value = userController.profile;
        profileName = profile.value.name;
        profileAboutMe = profile.value.aboutMe;
      } catch (e) {
        logger.e(e);
    }

    if(profile.value.position != null) {
      location.value = await GeoLocatorController().getAddressSimple(profile.value.position!);
    }

    aboutMeController.text = profile.value.aboutMe;
    nameController.text = profile.value.name;
  }


  @override
  void onReady() async {
    super.onReady();
    logger.t("Profile Controller Ready");
    try {
      if(profile.value.posts?.isNotEmpty ?? false) {
        await getProfilePosts();
      }

      if((profile.value.events?.isNotEmpty ?? false)
          || (profile.value.goingEvents?.isNotEmpty ?? false)
          || (profile.value.playingEvents?.isNotEmpty ?? false)) {
        await getTotalEvents();
      }

      await getTotalItems();
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.profile]);
  }


  void clear() {
    profile.value = AppProfile();
    profilePosts.clear();
  }


  @override
  Future<void> editProfile() async {
    logger.d("");
  }


  void changeEditStatus(){
    logger.t("Changing edit status from $editStatus");

    editStatus.value ? editStatus.value = false
        : editStatus.value = true;

    update([AppPageIdConstants.profile]);
  }

  @override
  void getItemDetails(AppMediaItem appMediaItem){
    logger.d("getItemDetails for ${appMediaItem.name}");
    if(AppFlavour.appInUse != AppInUse.g) {
      Get.toNamed(AppFlavour.getItemDetailsRoute(),
          arguments: [appMediaItem]
      );
    } else {
      Get.to(() => MediaPlayerPage(appMediaItem: appMediaItem),transition: Transition.downToUp);
    }


  }

  Future<void> getProfilePosts() async {
    logger.d("getProfilePosts");
    profilePosts.value = await PostFirestore().getProfilePosts(profile.value.id);

    for (var post in profilePosts) {
      Event event = Event();
      if(post.referenceId.isNotEmpty) {
        event = await EventFirestore().retrieve(post.referenceId);
      }
      eventPosts[post] = event;
    }

    logger.d("${profilePosts.length} Total Posts for Profile");
    update([AppPageIdConstants.profile, AppPageIdConstants.profilePosts]);
  }

  @override
  Future<void> getTotalItems() async {
    logger.t('getTotal ${AppFlavour.appInUse == AppInUse.c ? 'Presets': 'AppMediaItems & AppReleaseItems'}');

    if(profile.value.itemlists != null) {
      if(AppFlavour.appInUse == AppInUse.c) {
        profile.value.frequencies = await FrequencyFirestore().retrieveFrequencies(profile.value.id);
        for (var freq in profile.value.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = ChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(profile.value.itemlists!));
      } else {
        totalMediaItems.value = CoreUtilities.getTotalMediaItems(profile.value.itemlists!);
        totalReleaseItems.value = CoreUtilities.getTotalReleaseItems(profile.value.itemlists!);
      }

    }

    logger.t("${(totalMediaItems.length + totalReleaseItems.length)} Total Items for Profile");
    update([AppPageIdConstants.profile]);
  }

  Future<void> getTotalEvents() async {
    logger.t("getTotalEvents");

    if(profile.value.events != null && profile.value.events!.isNotEmpty) {
      Map<String, Event> createdEvents = await EventFirestore().getEventsById(profile.value.events!);
      logger.d("${createdEvents.length} created events founds for profile ${profile.value.id}");
      events.addAll(createdEvents);
    }

    if(profile.value.playingEvents != null && profile.value.playingEvents!.isNotEmpty) {
      Map<String, Event> playingEvents = await EventFirestore().getEventsById(profile.value.playingEvents!);
      logger.d("${playingEvents.length} playing events founds for profile ${profile.value.id}");
      events.addAll(playingEvents);
    }

    if(profile.value.goingEvents != null && profile.value.goingEvents!.isNotEmpty) {
      Map<String, Event> goingEvents = await EventFirestore().getEventsById(profile.value.goingEvents!);
      logger.d("${goingEvents.length} going events founds for profile ${profile.value.id}");
      events.addAll(goingEvents);
    }

    logger.d("${events.length} Total Events found for Profile");
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateLocation() async {
    logger.d("Updating location");
    try {

      Position newPosition =  await GeoLocatorController().getCurrentPosition();

      if(await ProfileFirestore().updatePosition(profile.value.id, newPosition)){
        profile.value.position = newPosition;
        location.value = await GeoLocatorController().getAddressSimple(profile.value.position!);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Location retrieved and updated successfully");
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateProfileData() async {
    logger.t("Updating Profile Data");
    bool nameChanged = false;
    bool aboutMeChanged = false;

    if(profileName != nameController.text.trim()) nameChanged = true;
    if(profileAboutMe != aboutMeController.text.trim()) aboutMeChanged = true;

    if(nameChanged || aboutMeChanged) {
      if(nameChanged) {
        profileName = nameController.text.trim();

        if(!AppUtilities.isWithinLastSevenDays(profile.value.lastNameUpdate)) {
          if(profileName.length > 3 && profileName.isNotEmpty) {
            isValidName = await ProfileFirestore().isAvailableName(profileName);
            if(isValidName) {
              if(await ProfileFirestore().updateName(profile.value.id, profileName)) {
                userController.profile.name = profileName;
                profile.value.name = profileName;
                profile.value.lastNameUpdate = DateTime.now().millisecondsSinceEpoch;
                AppUtilities.showSnackBar(
                  title: AppTranslationConstants.profileDetails.tr,
                  message: MessageTranslationConstants.profileNameUpdated.tr,
                );

              }
            } else {
              AppUtilities.showSnackBar(
                title: AppTranslationConstants.profileDetails.tr,
                message: MessageTranslationConstants.profileNameUsed.tr,
              );
              return;
            }
          }
        } else {
          profileName = profile.value.name;
          nameController.text = profile.value.name;
          AppUtilities.showSnackBar(
            title: AppTranslationConstants.profileDetails.tr,
            message: MessageTranslationConstants.nameRecentlyUpdate.tr,
            duration: const Duration(seconds: 5)
          );
        }

      }

      if(aboutMeChanged) {
        profileAboutMe = aboutMeController.text.trim();
        aboutMeValid = profileAboutMe.length > 150 ? false : true;
        if (aboutMeValid) {
          if(await ProfileFirestore().updateAboutMe(profile.value.id, profileAboutMe)) {
            userController.profile.aboutMe = profileAboutMe;
            profile.value.aboutMe = profileAboutMe;
            AppUtilities.showSnackBar(
              title: AppTranslationConstants.profileDetails.tr,
              message: MessageTranslationConstants.profileAboutMeUpdated.tr,
            );
          }
        } else {
          AppUtilities.showSnackBar(
            title: AppTranslationConstants.profileDetails.tr,
            message: MessageTranslationConstants.descriptionTooLong.tr,
          );
          return;
        }
      }


    } else {
      AppUtilities.showSnackBar(
        title: AppTranslationConstants.profileDetails.tr,
        message: AppTranslationConstants.thereWasNoChanges.tr,
      );
      return;
    }

    editStatus.value = false;
    update([AppPageIdConstants.profile, AppPageIdConstants.appDrawer]);
  }


  @override
  void addFollowing(String followingId) {
    userController.profile.following!.add(followingId);
    update([AppPageIdConstants.profile]);
  }


  @override
  void removeFollowing(String followingId) {
    userController.profile.following!.remove(followingId);
    update([AppPageIdConstants.profile]);
  }


  @override
  void addBlockTo(String itemmateId) {
    userController.profile.blockTo!.add(itemmateId);
    update([AppPageIdConstants.profile]);
  }


  @override
  Future<void> handleAndUploadImage(UploadImageType uploadImageType) async {

    logger.d("Entering handleAndUploadImage method");

    isLoading.value = true;
    update([AppPageIdConstants.profile]);

    try {
      await postUploadController.handleImage(uploadImageType: UploadImageType.profile);
      if(postUploadController.mediaFile.value.path.isNotEmpty) {
        String photoUrl = await postUploadController.handleUploadImage(
            uploadImageType);

        if(uploadImageType == UploadImageType.profile) {
          if (await ProfileFirestore().updatePhotoUrl(profile.value.id, photoUrl)) {
            if (await UserFirestore().updatePhotoUrl(userController.user!.id, photoUrl)) {
              userController.user!.photoUrl = photoUrl;
              userController.user!.profiles.first.photoUrl = photoUrl;
              profile.value.photoUrl = photoUrl;
            }
          }
        } else if(uploadImageType == UploadImageType.cover) {
          if (await ProfileFirestore().updateCoverImgUrl(profile.value.id, photoUrl)) {
              userController.user!.profiles.first.coverImgUrl = photoUrl;
              profile.value.coverImgUrl = photoUrl;
            }
          }
        }
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> showUpdatePhotoDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context){
          return SimpleDialog(
            backgroundColor: AppColor.getMain(),
            title: Text(AppTranslationConstants.updateProfilePicture.tr),
            children: <Widget>[
              SimpleDialogOption(
                  child: Text(
                      AppTranslationConstants.uploadImage.tr
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await handleAndUploadImage(UploadImageType.profile);
                  }
              ),
              SimpleDialogOption(
                  child: Text(AppTranslationConstants.cancel.tr),
                  onPressed: () => Navigator.pop(context)
              ),
            ],
          );
        }
    );
  }

  @override
  Future<void> showUpdateCoverImgDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context){
          return SimpleDialog(
            backgroundColor: AppColor.getMain(),
            title: Text(AppTranslationConstants.updateCoverImage.tr),
            children: <Widget>[
              SimpleDialogOption(
                  child: Text(AppTranslationConstants.uploadImage.tr),
                  onPressed: () async {
                    Navigator.pop(context);
                    await handleAndUploadImage(UploadImageType.cover);
                  }
              ),
              SimpleDialogOption(
                  child: Text(AppTranslationConstants.cancel.tr),
                  onPressed: () => Navigator.pop(context)
              ),
            ],
          );
        }
    );
  }



}
