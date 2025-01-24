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
import 'package:neom_commons/core/domain/model/instrument.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/profile_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_commons/core/utils/enums/usage_reason.dart';
import 'package:neom_frequencies/frequencies/data/firestore/frequency_firestore.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../domain/use_cases/profile_service.dart';

class ProfileController extends GetxController implements ProfileService {
  
  final userController = Get.find<UserController>();
  final loginController = Get.find<LoginController>();

  final Rx<AppProfile> profile = AppProfile().obs;
  final RxBool editStatus = false.obs;
  final RxString location = "".obs;
  final RxBool isLoading = true.obs;

  final RxMap<String, AppMediaItem> totalMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> totalReleaseItems = <String, AppReleaseItem>{}.obs;
  final RxMap<String, AppMediaItem>  totalMixedItems = <String, AppMediaItem>{}.obs;
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
  Map<String, Instrument> previousInstruments = {};
  String previousMainFeature = '';
  Rx<ProfileType>  newProfileType = ProfileType.general.obs;
  Rx<UsageReason>  newUsageReason = UsageReason.casual.obs;


  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("Profile Controller");

    try {
        profile.value = userController.profile;
        profileName = profile.value.name;
        profileAboutMe = profile.value.aboutMe;
        newProfileType.value = profile.value.type;
        newUsageReason.value = profile.value.usageReason;
      } catch (e) {
        AppUtilities.logger.e(e);
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
    AppUtilities.logger.t("Profile Controller Ready");
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
      AppUtilities.logger.e(e.toString());
    }

    previousInstruments = Map.from(profile.value.instruments ?? {});
    previousMainFeature = profile.value.mainFeature;
    isLoading.value = false;
    update([AppPageIdConstants.profile]);
  }


  void clear() {
    profile.value = AppProfile();
    profilePosts.clear();
  }


  @override
  Future<void> editProfile() async {
    AppUtilities.logger.d("");
  }


  void changeEditStatus(){
    AppUtilities.logger.t("Changing edit status from $editStatus");

    editStatus.value ? editStatus.value = false
        : editStatus.value = true;

    aboutMeController.text.trim();
    
    update([AppPageIdConstants.profile]);
  }

  @override
  void getItemDetails(AppMediaItem appMediaItem){
    AppUtilities.logger.d("getItemDetails for ${appMediaItem.name}");
    if(AppFlavour.appInUse != AppInUse.g) {
      Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem]);
    } else {
      ///DEPRECATED Get.to(() => MediaPlayerPage(appMediaItem: appMediaItem),transition: Transition.downToUp);
      Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
    }


  }

  Future<void> getProfilePosts() async {
    AppUtilities.logger.t("getProfilePosts");
    profilePosts.value = await PostFirestore().getProfilePosts(profile.value.id);

    for (var post in profilePosts) {
      Event event = Event();
      if(post.referenceId.isNotEmpty) {
        event = await EventFirestore().retrieve(post.referenceId);
      }
      eventPosts[post] = event;
    }

    AppUtilities.logger.d("${profilePosts.length} Total Posts for Profile");
    update([AppPageIdConstants.profile, AppPageIdConstants.profilePosts]);
  }

  @override
  Future<void> getTotalItems() async {
    AppUtilities.logger.t('getTotal ${AppFlavour.appInUse == AppInUse.c ? 'Presets': 'AppMediaItems & AppReleaseItems'}');

    if(profile.value.itemlists != null) {
      if(AppFlavour.appInUse == AppInUse.c) {
        profile.value.frequencies = await FrequencyFirestore().retrieveFrequencies(profile.value.id);
        for (var freq in profile.value.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = ChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(profile.value.chambers ?? {}));
      } else {
        totalReleaseItems.value = CoreUtilities.getTotalReleaseItems(profile.value.itemlists!);
        totalMediaItems.value = CoreUtilities.getTotalMediaItems(profile.value.itemlists!);
        for (var item in totalReleaseItems.values) {
          totalMixedItems[item.id] = AppMediaItem.fromAppReleaseItem(item);
        }
        totalMixedItems.addAll(totalMediaItems);
      }
    }

    AppUtilities.logger.d("${totalMixedItems.length} Total Items for Profile");
    update([AppPageIdConstants.profile]);
  }

  Future<void> getTotalEvents() async {
    AppUtilities.logger.t("getTotalEvents");

    if(profile.value.events != null && profile.value.events!.isNotEmpty) {
      Map<String, Event> createdEvents = await EventFirestore().getEventsById(profile.value.events!);
      AppUtilities.logger.d("${createdEvents.length} created events founds for profile ${profile.value.id}");
      events.addAll(createdEvents);
    }

    if(profile.value.playingEvents != null && profile.value.playingEvents!.isNotEmpty) {
      Map<String, Event> playingEvents = await EventFirestore().getEventsById(profile.value.playingEvents!);
      AppUtilities.logger.d("${playingEvents.length} playing events founds for profile ${profile.value.id}");
      events.addAll(playingEvents);
    }

    if(profile.value.goingEvents != null && profile.value.goingEvents!.isNotEmpty) {
      Map<String, Event> goingEvents = await EventFirestore().getEventsById(profile.value.goingEvents!);
      AppUtilities.logger.d("${goingEvents.length} going events founds for profile ${profile.value.id}");
      events.addAll(goingEvents);
    }

    AppUtilities.logger.d("${events.length} Total Events found for Profile");
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateLocation() async {
    AppUtilities.logger.t("Updating location");
    try {

      Position? newPosition =  await GeoLocatorController().getCurrentPosition();
      if(newPosition != null) {
        if(await ProfileFirestore().updatePosition(profile.value.id, newPosition)){
          profile.value.position = newPosition;
          location.value = await GeoLocatorController().getAddressSimple(profile.value.position!);
        }
        AppUtilities.logger.d("Location retrieved and updated successfully");
      } else {
        AppUtilities.logger.d("Location was not updated as access is deniedForever");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateProfileData() async {
    AppUtilities.logger.t("Updating Profile Data");

    bool nameChanged = profileName != nameController.text.trim();
    bool aboutMeChanged = profileAboutMe != aboutMeController.text.trim();
    bool profileInstrumentsChanged = !CoreUtilities.mapKeysEquals(previousInstruments, profile.value.instruments ?? {});
    bool mainFeatureChanged = previousMainFeature != profile.value.mainFeature;

    if(nameChanged || aboutMeChanged || mainFeatureChanged || profileInstrumentsChanged) {
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

      if(profileInstrumentsChanged) previousInstruments = Map.from(profile.value.instruments ?? {});
      if(mainFeatureChanged) previousMainFeature = profile.value.mainFeature;
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
    AppUtilities.logger.t("Entering handleAndUploadImage method");

    isLoading.value = true;
    update([AppPageIdConstants.profile]);

    try {
      await postUploadController.handleImage(uploadImageType: UploadImageType.profile);
      if(postUploadController.mediaFile.value.path.isNotEmpty) {
        String photoUrl = await postUploadController.handleUploadImage(
            uploadImageType);

        if(uploadImageType == UploadImageType.profile) {
          if (await ProfileFirestore().updatePhotoUrl(profile.value.id, photoUrl)) {
            if (await UserFirestore().updatePhotoUrl(userController.user.id, photoUrl)) {
              userController.user.photoUrl = photoUrl;
              userController.user.profiles.first.photoUrl = photoUrl;
              profile.value.photoUrl = photoUrl;
            }
          }
        } else if(uploadImageType == UploadImageType.cover) {
          if (await ProfileFirestore().updateCoverImgUrl(profile.value.id, photoUrl)) {
              userController.user.profiles.first.coverImgUrl = photoUrl;
              profile.value.coverImgUrl = photoUrl;
            }
          }
        }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
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

  void showUpdateProfileType(BuildContext context) {
    List<ProfileType> profileTypes = List.from(ProfileType.values);

    profileTypes.removeWhere((type) => type == ProfileType.broadcaster);
    switch(AppFlavour.appInUse) {
      case AppInUse.g:
        profileTypes.removeWhere((type) => type == ProfileType.band);
        profileTypes.removeWhere((type) => type == ProfileType.researcher);
      case AppInUse.e:
        profileTypes.removeWhere((type) => type == ProfileType.band);
        profileTypes.removeWhere((type) => type == ProfileType.researcher);
      case AppInUse.c:
        profileTypes.removeWhere((type) => type == ProfileType.band);
    }

    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: AppTranslationConstants.updateProfileType.tr,
        content: Column(
          children: <Widget>[
            AppTheme.heightSpace10,
            Text(AppTranslationConstants.updateProfileTypeMsg.tr,
              style: const TextStyle(fontSize: 15),
            ),
            Obx(() =>
                DropdownButton<ProfileType>(
                  items: profileTypes.map((ProfileType profileType) {
                    return DropdownMenuItem<ProfileType>(
                      value: profileType,
                      child: Text(profileType.name.tr.capitalize),
                    );
                  }).toList(),
                  onChanged: (ProfileType? selectedType) {
                    if (selectedType == null) return;
                    selectProfileType(selectedType);
                  },
                  value: newProfileType.value,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.main75,
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppTranslationConstants.goBack.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await updateProfileType();
            },
            child: Text(AppTranslationConstants.toUpdate.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  @override
  void selectProfileType(ProfileType type) {
    try {
      newProfileType.value = type;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateProfileType() async {
    try {
      if(newProfileType.value != profile.value.type && profile.value.id.isNotEmpty) {
        if(await ProfileFirestore().updateType(profile.value.id, newProfileType.value)) {
          Get.back();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.updateProfileType.tr,
              message: AppTranslationConstants.updateProfileTypeSuccess.tr);
          userController.profile.type = newProfileType.value;
          profile.value.type = newProfileType.value;
        }

      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateProfileType.tr,
            message: AppTranslationConstants.updateProfileTypeSame.tr);
      }


    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  void showUpdateUsageReason(BuildContext context) {
    List<UsageReason> usageReasons = List.from(UsageReason.values);

    Alert(
        context: context,
        style: AlertStyle(
          backgroundColor: AppColor.main50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: AppTranslationConstants.updateProfileType.tr,
        content: Column(
          children: <Widget>[
            AppTheme.heightSpace10,
            Text(AppTranslationConstants.updateProfileTypeMsg.tr,
              style: const TextStyle(fontSize: 15),
            ),
            Obx(() =>
                DropdownButton<UsageReason>(
                  items: usageReasons.map((UsageReason usageReason) {
                    return DropdownMenuItem<UsageReason>(
                      value: usageReason,
                      child: Text(usageReason.name.tr.capitalize),
                    );
                  }).toList(),
                  onChanged: (UsageReason? selectedReason) {
                    if (selectedReason == null) return;
                    selectUsageReason(selectedReason);
                  },
                  value: newUsageReason.value,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.main75,
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppTranslationConstants.goBack.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await updateUsageReason();
            },
            child: Text(AppTranslationConstants.toUpdate.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  @override
  void selectUsageReason(UsageReason reason) {
    try {
      newUsageReason.value = reason;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateUsageReason() async {
    try {
      if(newUsageReason.value != profile.value.usageReason && profile.value.id.isNotEmpty) {
        if(await ProfileFirestore().updateUsageReason(profile.value.id, newUsageReason.value)) {
          Get.back();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.updateProfileType.tr,
              message: AppTranslationConstants.updateProfileTypeSuccess.tr);
          userController.profile.usageReason = newUsageReason.value;
          profile.value.usageReason = newUsageReason.value;
        }
      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateProfileType.tr,
            message: AppTranslationConstants.updateProfileTypeSame.tr);
      }


    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

}
