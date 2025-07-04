import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:neom_commons/commons/app_flavour.dart';
import 'package:neom_commons/commons/ui/theme/app_color.dart';
import 'package:neom_commons/commons/ui/theme/app_theme.dart';
import 'package:neom_commons/commons/utils/app_utilities.dart';
import 'package:neom_commons/commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/commons/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/commons/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/commons/utils/mappers/app_media_item_mapper.dart';
import 'package:neom_core/core/app_config.dart';
import 'package:neom_core/core/data/firestore/event_firestore.dart';
import 'package:neom_core/core/data/firestore/facility_firestore.dart';
import 'package:neom_core/core/data/firestore/frequency_firestore.dart';
import 'package:neom_core/core/data/firestore/place_firestore.dart';
import 'package:neom_core/core/data/firestore/post_firestore.dart';
import 'package:neom_core/core/data/firestore/profile_firestore.dart';
import 'package:neom_core/core/data/firestore/user_firestore.dart';
import 'package:neom_core/core/data/implementations/geolocator_controller.dart';
import 'package:neom_core/core/data/implementations/user_controller.dart';
import 'package:neom_core/core/domain/model/app_media_item.dart';
import 'package:neom_core/core/domain/model/app_profile.dart';
import 'package:neom_core/core/domain/model/app_release_item.dart';
import 'package:neom_core/core/domain/model/event.dart';
import 'package:neom_core/core/domain/model/facility.dart';
import 'package:neom_core/core/domain/model/instrument.dart';
import 'package:neom_core/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_core/core/domain/model/place.dart';
import 'package:neom_core/core/domain/model/post.dart';
import 'package:neom_core/core/domain/use_cases/post_upload_service.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:neom_core/core/utils/core_utilities.dart';
import 'package:neom_core/core/utils/enums/app_in_use.dart';
import 'package:neom_core/core/utils/enums/facilitator_type.dart';
import 'package:neom_core/core/utils/enums/place_type.dart';
import 'package:neom_core/core/utils/enums/profile_type.dart';
import 'package:neom_core/core/utils/enums/upload_image_type.dart';
import 'package:neom_core/core/utils/enums/usage_reason.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../domain/use_cases/profile_service.dart';

class ProfileController extends GetxController implements ProfileService {
  
  final userController = Get.find<UserController>();

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

  PostUploadService postUploadController = Get.find<PostUploadService>();

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
  Rx<FacilityType>  facilityType = FacilityType.general.obs;
  Rx<PlaceType>  placeType = PlaceType.general.obs;

  @override
  void onInit() {
    super.onInit();
    AppConfig.logger.t("Profile Controller");

    try {
        setProfileInfo();
      } catch (e) {
        AppConfig.logger.e(e);
    }
  }

  Future<void> setProfileInfo() async {
    profile.value = userController.profile;
    profileName = profile.value.name;
    profileAboutMe = profile.value.aboutMe;
    newProfileType.value = profile.value.type;
    newUsageReason.value = profile.value.usageReason;
    if(profile.value.position != null) {
      location.value = await GeoLocatorController().getAddressSimple(profile.value.position!);
    }
    aboutMeController.text = profile.value.aboutMe;
    nameController.text = profile.value.name;
  }


  @override
  void onReady() {
    super.onReady();
    AppConfig.logger.t("Profile Controller Ready");
    if(!userController.isNewUser) {
      loadProfileActivity();
    } else {
      AppConfig.logger.t("User is new, skipping profile activity load");
      isLoading.value = false;
    }

  }

  Future<void> loadProfileActivity() async {
    AppConfig.logger.t("Loading Profile Activity");
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
      AppConfig.logger.e(e.toString());
    }

    previousInstruments = Map.from(profile.value.instruments ?? {});
    previousMainFeature = profile.value.mainFeature;
    isLoading.value = false;
  }


  void clear() {
    profile.value = AppProfile();
    profilePosts.clear();
  }


  @override
  Future<void> editProfile() async {
    AppConfig.logger.d("");
  }


  void changeEditStatus(){
    AppConfig.logger.t("Changing edit status from $editStatus");

    editStatus.value ? editStatus.value = false
        : editStatus.value = true;

    aboutMeController.text.trim();
    
    update([AppPageIdConstants.profile]);
  }

  @override
  void getItemDetails(AppMediaItem appMediaItem) {
    AppConfig.logger.d("getItemDetails for ${appMediaItem.name}");
    if(AppFlavour.appInUse != AppInUse.g) {
      Get.toNamed(AppFlavour.getMainItemDetailsRoute(), arguments: [appMediaItem]);
    } else {
      ///DEPRECATED Get.to(() => MediaPlayerPage(appMediaItem: appMediaItem),transition: Transition.downToUp);
      Get.toNamed(AppRouteConstants.audioPlayerMedia, arguments: [appMediaItem]);
    }
  }

  Future<void> getProfilePosts() async {
    AppConfig.logger.d("getProfilePosts");
    profilePosts.value = await PostFirestore().getProfilePosts(profile.value.id);

    for (var post in profilePosts) {
      Event event = Event();
      if(post.referenceId.isNotEmpty) {
        event = await EventFirestore().retrieve(post.referenceId);
      }
      eventPosts[post] = event;
    }

    AppConfig.logger.d("${profilePosts.length} Total Posts for Profile");
    update([AppPageIdConstants.profile, AppPageIdConstants.profilePosts]);
  }

  @override
  Future<void> getTotalItems() async {
    AppConfig.logger.t('getTotal ${AppFlavour.appInUse == AppInUse.c ? 'Presets': 'AppMediaItems & AppReleaseItems'}');

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
          totalMixedItems[item.id] = AppMediaItemMapper.fromAppReleaseItem(item);
        }
        totalMixedItems.addAll(totalMediaItems);
      }
    }

    AppConfig.logger.d("${totalMixedItems.length} Total Items for Profile");
    update([AppPageIdConstants.profile]);
  }

  Future<void> getTotalEvents() async {
    AppConfig.logger.t("getTotalEvents");

    if(profile.value.events != null && profile.value.events!.isNotEmpty) {
      Map<String, Event> createdEvents = await EventFirestore().getEventsById(profile.value.events!);
      AppConfig.logger.d("${createdEvents.length} created events founds for profile ${profile.value.id}");
      events.addAll(createdEvents);
    }

    if(profile.value.playingEvents != null && profile.value.playingEvents!.isNotEmpty) {
      Map<String, Event> playingEvents = await EventFirestore().getEventsById(profile.value.playingEvents!);
      AppConfig.logger.d("${playingEvents.length} playing events founds for profile ${profile.value.id}");
      events.addAll(playingEvents);
    }

    if(profile.value.goingEvents != null && profile.value.goingEvents!.isNotEmpty) {
      Map<String, Event> goingEvents = await EventFirestore().getEventsById(profile.value.goingEvents!);
      AppConfig.logger.d("${goingEvents.length} going events founds for profile ${profile.value.id}");
      events.addAll(goingEvents);
    }

    AppConfig.logger.d("${events.length} Total Events found for Profile");
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateLocation() async {
    AppConfig.logger.t("Updating location");
    try {

      Position? newPosition =  await GeoLocatorController().getCurrentPosition();
      if(newPosition != null) {
        if(await ProfileFirestore().updatePosition(profile.value.id, newPosition)){
          profile.value.position = newPosition;
          location.value = await GeoLocatorController().getAddressSimple(profile.value.position!);
        }
        AppConfig.logger.d("Location retrieved and updated successfully for ${location.value}");
      } else {
        AppConfig.logger.d("Location was not updated as access is deniedForever");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateProfileData() async {
    AppConfig.logger.t("Updating Profile Data");

    bool nameChanged = profileName != nameController.text.trim();
    bool aboutMeChanged = profileAboutMe != aboutMeController.text.trim();
    bool profileInstrumentsChanged = !AppUtilities.mapKeysEquals(previousInstruments, profile.value.instruments ?? {});
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
  Future<void> handleAndUploadImage(UploadImageType uploadImageType) async {
    AppConfig.logger.t("Entering handleAndUploadImage method");

    isLoading.value = true;
    update([AppPageIdConstants.profile]);

    try {
      await postUploadController.handleImage(imageType: UploadImageType.profile);
      if(postUploadController.getMediaFile().path.isNotEmpty) {
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
      AppConfig.logger.e(e.toString());
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
      default:
        break;
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
                      child: Text(profileType.value.tr.capitalize),
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

  void selectProfileType(ProfileType type) {
    try {
      newProfileType.value = type;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

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
      AppConfig.logger.e(e.toString());
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

  void selectUsageReason(UsageReason reason) {
    try {
      newUsageReason.value = reason;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

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
      AppConfig.logger.e(e.toString());
    }
  }

  void showAddFacility(BuildContext context) {
    List<FacilityType> facilityTypes = List.from(FacilityType.values);
    if(AppFlavour.appInUse != AppInUse.g) {
      facilityTypes.removeWhere((type)=> type == FacilityType.recordStudio
          || type == FacilityType.rehearsalRoom
          || type == FacilityType.soundRental
      );
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
            Text(AppTranslationConstants.introFacilitatorType.tr,
              style: const TextStyle(fontSize: 15),
            ),
            Obx(() =>
                DropdownButton<FacilityType>(
                  items: facilityTypes.map((FacilityType type) {
                    return DropdownMenuItem<FacilityType>(
                      value: type,
                      child: Text(type.name.tr.capitalize),
                    );
                  }).toList(),
                  onChanged: (FacilityType? selectedFacility) {
                    if (selectedFacility == null) return;
                    selectFacilityType(selectedFacility);
                  },
                  value: facilityType.value,
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
              await updateFacilityType();
            },
            child: Text(AppTranslationConstants.toUpdate.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  void selectFacilityType(FacilityType type) {
    try {
      facilityType.value = type;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  Future<void> updateFacilityType() async {
    try {
      if(profile.value.id.isNotEmpty) {
        if(await FacilityFirestore().addFacility(profileId: profile.value.id, facilityType: facilityType.value)) {
          Get.back();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.updateProfile.tr,
              message: AppTranslationConstants.facilityAdded.tr);
          userController.profile.facilities = {};
          userController.profile.facilities![facilityType.value.name] = Facility(type: facilityType.value);
        }
      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateProfileType.tr,
            message: AppTranslationConstants.updateProfileTypeSame.tr);
      }


    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  void showAddPlace(BuildContext context) {
    List<PlaceType> placeTypes = List.from(PlaceType.values);
    if(AppFlavour.appInUse != AppInUse.g) {
      // placeTypes.removeWhere((type)=> type == PlaceType.recordStudio
      //     || type == FacilityType.rehearsalRoom
      //     || type == FacilityType.soundRental
      // );
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
            Text(AppTranslationConstants.introFacilitatorType.tr,
              style: const TextStyle(fontSize: 15),
            ),
            Obx(() =>
                DropdownButton<PlaceType>(
                  items: placeTypes.map((PlaceType type) {
                    return DropdownMenuItem<PlaceType>(
                      value: type,
                      child: Text(type.name.tr.capitalize),
                    );
                  }).toList(),
                  onChanged: (PlaceType? selectedPlace) {
                    if (selectedPlace == null) return;
                    selectPlaceType(selectedPlace);
                  },
                  value: placeType.value,
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
              await updatePlaceType();
            },
            child: Text(AppTranslationConstants.toUpdate.tr,
              style: const TextStyle(fontSize: 15),
            ),
          )
        ]
    ).show();
  }

  void selectPlaceType(PlaceType type) {
    try {
      placeType.value = type;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  Future<void> updatePlaceType() async {
    try {
      if(profile.value.id.isNotEmpty) {
        if(await PlaceFirestore().addPlace(placeType: placeType.value, profileId: profile.value.id)) {
          Get.back();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.updateProfile.tr,
              message: AppTranslationConstants.placeAdded.tr);
          userController.profile.places = {};
          userController.profile.places![placeType.value.name] = Place(type: placeType.value);
        }
      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateProfileType.tr,
            message: AppTranslationConstants.updateProfileTypeSame.tr);
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

}
