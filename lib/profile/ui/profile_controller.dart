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
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/domain/model/post.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/constants/message_translation_constants.dart';
import 'package:neom_commons/core/utils/core_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_frequencies/frequencies/data/firestore/frequency_firestore.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';

import '../domain/use_cases/profile_service.dart';

class ProfileController extends GetxController implements ProfileService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final loginController = Get.find<LoginController>();

  final RxBool _editStatus = false.obs;
  bool get editStatus => _editStatus.value;
  set editStatus(bool editStatus) => _editStatus.value = editStatus;

  final RxString _location = "".obs;
  String get location => _location.value;
  set location(String location) => _location.value = location;

  final Rx<AppProfile> _profile = AppProfile().obs;
  AppProfile get profile => _profile.value;
  set profile(AppProfile profile) => _profile.value = profile;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxMap<String, AppItem> _totalItems = <String, AppItem>{}.obs;
  Map<String, AppItem> get totalItems => _totalItems;
  set totalItems(Map<String, AppItem> totalItems) => _totalItems.value = totalItems;

  final RxMap<String, ChamberPreset> _totalPresets = <String, ChamberPreset>{}.obs;
  Map<String, ChamberPreset> get totalPresets => _totalPresets;
  set totalPresets(Map<String, ChamberPreset> totalPresets) => _totalPresets.value = totalPresets;

  int postCount = 0;
  bool isFollowing= false;

  final RxList<Post> _profilePosts = <Post>[].obs;
  List<Post> get profilePosts => _profilePosts;
  set profilePosts(List<Post> profilePosts) => _profilePosts.value = profilePosts;

  final RxMap<String, Event> _events = <String, Event>{}.obs;
  Map<String, Event> get events => _events;
  set events(Map<String, Event> events) => _events.value = events;

  final RxMap<Post, Event> _eventPosts = <Post, Event>{}.obs;
  Map<Post, Event> get eventPosts => _eventPosts;
  set eventPosts(Map<Post, Event> eventPosts) => _eventPosts.value = eventPosts;

  final postUploadController = Get.put(PostUploadController());

  TextEditingController nameController = TextEditingController();
  TextEditingController aboutMeController = TextEditingController();

  String _profileName = "";
  String _profileAboutMe = "";
  bool _aboutMeValid=true;
  bool _isValidName = true;

  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    logger.d("Profile Controller");

    try {
        profile = userController.profile;
      } catch (e) {
        logger.e(e);
    }

    if(profile.position != null) {
      location = await GeoLocatorController().getAddressSimple(profile.position!);
    }

    aboutMeController.text = profile.aboutMe;
    nameController.text = profile.name;
  }


  @override
  void onReady() async {
    super.onReady();
    logger.d("Profile Controller Ready");
    try {
      if(profile.posts?.isNotEmpty ?? false) {
        await getProfilePosts();
      }

      if((profile.events?.isNotEmpty ?? false)
          || (profile.goingEvents?.isNotEmpty ?? false)
          || (profile.playingEvents?.isNotEmpty ?? false)) {
        await getTotalEvents();
      }

      await getTotalItems();

    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.profile]);
  }


  void clear() {
    _profile.value = AppProfile();
    _profilePosts.clear();
  }


  @override
  Future<void> editProfile() async {
    logger.d("");
  }


  void changeEditStatus(){
    logger.d("Changing edit status from $editStatus");

    editStatus ? _editStatus.value = false
        : _editStatus.value = true;

    update([AppPageIdConstants.profile]);
  }

  @override
  void getItemDetails(AppItem appItem){
    logger.d("getItemDetails for ${appItem.name}");
    Get.toNamed(AppFlavour.getItemDetailsRoute(),
        arguments: [appItem]
    );
  }

  Future<void> getProfilePosts() async {
    logger.d("");
    _profilePosts.value = await PostFirestore().getProfilePosts(profile.id);

    for (var post in _profilePosts) {
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
    logger.d("");

    if(profile.itemlists != null) {
      if(AppFlavour.appInUse == AppInUse.cyberneom) {
        profile.frequencies = await FrequencyFirestore().retrieveFrequencies(profile.id);
        for (var freq in profile.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = ChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(profile.itemlists!));
      } else {
        totalItems = CoreUtilities.getTotalItems(profile.itemlists!);
      }

    }

    logger.d("${totalItems.length} Total Items for Profile");
    update([AppPageIdConstants.profile]);
  }

  Future<void> getTotalEvents() async {
    logger.d("");

    if(profile.events != null && profile.events!.isNotEmpty) {
      events = await EventFirestore().getEventsById(profile.events!);
    }

    if(profile.playingEvents != null && profile.playingEvents!.isNotEmpty) {
      events.addAll(await EventFirestore().getEventsById(profile.playingEvents!));
    }

    if(profile.goingEvents != null && profile.goingEvents!.isNotEmpty) {
      events.addAll(await EventFirestore().getEventsById(profile.goingEvents!));
    }

    logger.d("${events.length} Total Events for Profile");
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateLocation() async {
    logger.d("Updating location");
    try {

      Position newPosition =  await GeoLocatorController().getCurrentPosition();

      if(await ProfileFirestore().updatePosition(profile.id, newPosition)){
        profile.position = newPosition;
        location = await GeoLocatorController().getAddressSimple(profile.position!);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Location retrieved and updated successfully");
    update([AppPageIdConstants.profile]);
  }

  @override
  Future<void> updateProfileData() async {
    logger.d("Updating Profile Data");
    _profileName = nameController.text;
    _profileAboutMe = aboutMeController.text;
    bool wasUpdated = false;

    _isValidName = _profileName.trim().length < 3 || _profileName.isEmpty ? false : true;

    if(_isValidName) {
      _isValidName = await ProfileFirestore().isAvailableName(_profileName);
    }

    if (_isValidName) {
      if(await ProfileFirestore().updateName(profile.id, _profileName)) {
        userController.profile.name = _profileName;
        profile.name = _profileName;
        wasUpdated = true;
      }
    } else {
      Get.snackbar(AppTranslationConstants.profileDetails.tr,
          MessageTranslationConstants.profileNameUsed.tr,
          snackPosition: SnackPosition.bottom
      );
      return;
    }

    _aboutMeValid = _profileAboutMe.trim().length > 150 ? false : true;

    if (_aboutMeValid) {
      if(await ProfileFirestore().updateAboutMe(profile.id, _profileAboutMe)) {
        userController.profile.aboutMe = _profileAboutMe;
        profile.aboutMe = _profileAboutMe;
        wasUpdated = true;
      }
    }

    if(wasUpdated) {
      Get.snackbar(AppTranslationConstants.profileDetails.tr,
          AppTranslationConstants.profileUpdatedMsg.tr,
          snackPosition: SnackPosition.bottom
      );
    }

    editStatus = false;
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

    isLoading = true;
    Get.back();
    update([AppPageIdConstants.profile]);

    try {
      await postUploadController.handleImage(uploadImageType: UploadImageType.profile);
      if(postUploadController.imageFile.path.isNotEmpty) {
        String photoUrl = await postUploadController.handleUploadImage(
            uploadImageType);

        if(uploadImageType == UploadImageType.profile) {
          if (await ProfileFirestore().updatePhotoUrl(profile.id, photoUrl)) {
            if (await UserFirestore().updatePhotoUrl(userController.user!.id, photoUrl)) {
              userController.user!.photoUrl = photoUrl;
              userController.user!.profiles.first.photoUrl = photoUrl;
              profile.photoUrl = photoUrl;
            }
          }
        } else if(uploadImageType == UploadImageType.cover) {
          if (await ProfileFirestore().updateCoverImgUrl(profile.id, photoUrl)) {
              userController.user!.profiles.first.coverImgUrl = photoUrl;
              profile.coverImgUrl = photoUrl;
            }
          }
        }
    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.profile]);
  }


}
