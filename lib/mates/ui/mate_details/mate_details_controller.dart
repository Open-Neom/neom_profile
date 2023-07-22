import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_frequencies/frequencies/data/firestore/frequency_firestore.dart';

import '../../../profile/ui/profile_controller.dart';
import '../../domain/use_cases/mate_details_service.dart';

class MateDetailsController extends GetxController implements MateDetailsService {

  var logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  final RxMap<String, AppProfile> _mates = <String, AppProfile>{}.obs;
  Map<String, AppProfile> get mates => _mates;
  set mates(Map<String, AppProfile> mates) => _mates.value = mates;

  final Rx<AppProfile> _mate = AppProfile().obs;
  AppProfile get mate => _mate.value;
  set mate(AppProfile mate) => _mate.value = mate;

  AppProfile profile = AppProfile();

  final RxString _address = "".obs;
  String get address => _address.value;
  set address(String address) => _address.value = address;

  final RxString _instrumentsText = "".obs;
  String get instrumentsText => _instrumentsText.value;
  set instrumentsText(String instrumentsText) => _instrumentsText.value = instrumentsText;

  final RxInt _distance = 0.obs;
  int get distance => _distance.value;
  set distance(int distance) => _distance.value = distance;

  final RxMap<String, AppItem> _totalItems = <String, AppItem>{}.obs;
  Map<String, AppItem> get totalItems => _totalItems;
  set totalItems(Map<String, AppItem> totalItems) => _totalItems.value = totalItems;

  final RxMap<String, ChamberPreset> _totalPresets = <String, ChamberPreset>{}.obs;
  Map<String, ChamberPreset> get totalPresets => _totalPresets;
  set totalPresets(Map<String, ChamberPreset> totalPresets) => _totalPresets.value = totalPresets;

  final RxMap<String, Itemlist> _itemlists = <String, Itemlist>{}.obs;
  Map<String, Itemlist> get itemlists => _itemlists;
  set itemlists(Map<String, Itemlist> itemlists) => _itemlists.value = itemlists;

  final RxBool _following = false.obs;
  bool get following => _following.value;
  set following(bool following) => _following.value = following;

  final RxMap<String, Event> _events = <String, Event>{}.obs;
  Map<String, Event> get events => _events;
  set events(Map<String, Event> events) => _events.value = events;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isLoadingDetails = true.obs;
  bool get isLoadingDetails => _isLoadingDetails.value;
  set isLoadingDetails(bool isLoadingDetails) => _isLoadingDetails.value = isLoadingDetails;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  List<Post> matePosts = <Post>[];
  List<Post> mateBlogEntries = <Post>[];

  final RxBool _blockedProfile = false.obs;
  bool get blockedProfile => _blockedProfile.value;

  GeoLocatorService geoLocatorService = GeoLocatorController();

  final RxMap<Post, Event> _eventPosts = <Post, Event>{}.obs;
  Map<Post, Event> get eventPosts => _eventPosts;
  set eventPosts(Map<Post, Event> eventPosts) => _eventPosts.value = eventPosts;

  @override
  void onInit() async {
    super.onInit();
    logger.d("");

    String itemmateId = Get.arguments ?? "";

    try {
      profile = userController.profile;
      _blockedProfile.value = profile.blockTo?.contains(itemmateId) ?? false;

      if(itemmateId.isNotEmpty && !blockedProfile) {
        await loadMate(itemmateId);
        await retrieveDetails();

        if(mate.id.isNotEmpty && (userController.user!.userRole == UserRole.subscriber || kDebugMode)) {
          FirebaseMessagingCalls.sendPrivatePushNotification(
            toProfileId: mate.id,
            fromProfile: profile,
            notificationType: PushNotificationType.viewProfile,
            referenceId: profile.id,
          );

          FirebaseMessagingCalls.sendGlobalPushNotification(
            fromProfile: profile,
            toProfile: mate,
            notificationType: PushNotificationType.viewProfile,
            referenceId: mate.id,
          );
        }
      } else {
        logger.i("Profile $itemmateId is blocked");
        isLoading = false;
      }
    } catch (e) {
      logger.e(e.toString());
    }
  }


  @override
  void onReady() async {
    super.onReady();
    logger.d("Itemmate Controller Ready");
    try {
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> loadMate(String itemmateId) async {
    logger.d("");

    try {
      mate = await ProfileFirestore().retrieve(itemmateId);
      if(mate.id.isNotEmpty) {
        following = profile.following!.contains(itemmateId);
      }

    } catch (e) {
      logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.mate, AppPageIdConstants.search]);
  }


  @override
  Future<void> retrieveDetails() async {
    logger.d("");
    try {
      mate.itemlists = await ItemlistFirestore().retrieveItemlists(mate.id);
      itemlists = mate.itemlists ?? {};

      await getTotalInstruments();
      await getAddressSimple();

      if(mate.posts?.isNotEmpty ?? false) {
        await getMatePosts();
      }

      if((mate.events?.isNotEmpty ?? false)
          || (mate.goingEvents?.isNotEmpty ?? false)
          || (mate.playingEvents?.isNotEmpty ?? false)) {
        await getTotalEvents();
      }

      await getTotalItems();

      for (var post in matePosts) {
        eventPosts[post] = events[post.referenceId] ?? Event();
      }

      instrumentsText = CoreUtilities.getInstruments(mate.instruments ?? {});

    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("");
    isLoadingDetails = false;
    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> getMatePosts() async {
    logger.d("");

    try {
      matePosts = await PostFirestore().getProfilePosts(mate.id);

      for (var post in matePosts) {
        if(post.type == PostType.blogEntry && !post.isDraft) {
          mateBlogEntries.add(post);
        }
      }
      matePosts.removeWhere((element) => element.type == PostType.blogEntry);
      logger.d("${mateBlogEntries.length} Total Blog Entries for Profile");
      logger.d("${matePosts.length} Total Posts for Profile");
    } catch (e) {
      logger.e(e.toString());
    }

    //isLoading = false;
    update([AppPageIdConstants.mate]);
  }


  void clear() {
    mates = <String, AppProfile>{};
  }


  @override
  Future<void> getAddressSimple() async {
    logger.d("");

    try {
      if(mate.position!.latitude != 0 && mate.position!.longitude != 0) {
        address = await geoLocatorService.getAddressSimple(mate.position!);
        distance = AppUtilities.distanceBetweenPositionsRounded(profile.position!, mate.position!);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("$address and $distance km");
    update([AppPageIdConstants.mate]);
  }

  @override
  Future<void> getTotalItems() async {
    logger.d("");

    if(mate.itemlists != null) {
      if(AppFlavour.appInUse == AppInUse.cyberneom) {
        mate.frequencies = await FrequencyFirestore().retrieveFrequencies(mate.id);
        for (var freq in mate.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = ChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(mate.itemlists!));
      } else {
        totalItems = CoreUtilities.getTotalItems(mate.itemlists!);
      }

    }

    logger.d("${totalItems.length} Total Items for Profile");
    update([AppPageIdConstants.mate]);
  }

  Future<void> getTotalEvents()  async{
    logger.d("");

    try {
      if(mate.events != null && mate.events!.isNotEmpty) {
        events = await EventFirestore().getEventsById(mate.events!);
      }

      if(mate.playingEvents != null && mate.playingEvents!.isNotEmpty) {
        events.addAll(await EventFirestore().getEventsById(mate.playingEvents!));
      }

      if(mate.goingEvents != null && mate.goingEvents!.isNotEmpty) {
        events.addAll(await EventFirestore().getEventsById(mate.goingEvents!));
      }

    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("${events.length} Total Events for Itemmate");
    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> getTotalInstruments() async {
    logger.d("");

    try {
      mate.instruments = await InstrumentFirestore().retrieveInstruments(mate.id);
      logger.d("${mate.instruments?.length ?? 0} Total Instruments for Profile");
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  void getItemDetails(AppItem appItem){
    logger.d("getItemDetails for ${appItem.name}");
    Get.toNamed(AppFlavour.getItemDetailsRoute(),
        arguments: [appItem]
    );
  }


  @override
  Future<void> follow() async {
    logger.d("");

    try {
      if(await ProfileFirestore().followProfile(profileId: profile.id, followedProfileId:  mate.id)) {
        following = true;
        mate.followers!.add(profile.id);

        try {
          Get.find<ProfileController>().addFollowing(mate.id);
        } catch (e) {
          Get.put(ProfileController()).addFollowing(mate.id);
        }

        ActivityFeed activityFeed = ActivityFeed();
        activityFeed.ownerId =  mate.id;
        activityFeed.profileId = profile.id;
        activityFeed.createdTime = DateTime.now().millisecondsSinceEpoch;
        activityFeed.activityFeedType = ActivityFeedType.follow;
        activityFeed.profileName = profile.name;
        activityFeed.profileImgUrl = profile.photoUrl;
        activityFeed.activityReferenceId = profile.id;

        ActivityFeedFirestore().insert(activityFeed);

        FirebaseMessagingCalls.sendPrivatePushNotification(
          toProfileId: mate.id,
          fromProfile: profile,
          notificationType: PushNotificationType.following,
          referenceId: profile.id,
        );

        FirebaseMessagingCalls.sendGlobalPushNotification(
          fromProfile: profile,
          toProfile: mate,
          notificationType: PushNotificationType.following,
          referenceId: mate.id,
        );

      }

    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> unfollow() async {
    logger.d("");
    try {
      if (await ProfileFirestore().unfollowProfile(profileId: profile.id,unfollowProfileId:  mate.id)) {
        following = false;
        userController.profile.following!.remove(mate.id);
        mate.followers!.remove(profile.id,);
        Get.find<ProfileController>().removeFollowing(mate.id);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }


  @override
  Future<void> blockProfile() async {
    logger.d("");
    try {
      if (await ProfileFirestore().blockProfile(
          profileId: profile.id,
          profileToBlock: mate.id)) {
        following = false;
        userController.profile.following!.remove(mate.id);
        mate.followers?.remove(profile.id);
        mate.blockedBy?.add(profile.id);

        userController.profile.blockTo!.add(mate.id);
      } else {
        logger.i("Something happened while blocking profile");
      }
    } catch (e) {
        logger.e(e.toString());
    }

    Get.back();
    Get.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }



  @override
  Future<void> unblockProfile(AppProfile blockedProfile) async {
    logger.d("");
    try {
      if (await ProfileFirestore().unblockProfile(profileId: userController.profile.id, profileToUnblock:  blockedProfile.id)) {
        userController.profile.blockTo!.remove(blockedProfile.id);
        blockedProfile.blockedBy!.remove(profile.id);
      } else {
        logger.i("Somethnig happened while unblocking profile");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    Get.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }


  @override
  Future<void> sendMessage() async {
    logger.d("");

    Inbox inbox = Inbox();

    try {
      inbox = await InboxFirestore().getOrCreateInboxRoom(profile, mate);

      inbox.id.isNotEmpty ? Get.toNamed(AppRouteConstants.inboxRoom, arguments: [inbox])
        : Get.toNamed(AppRouteConstants.home);
    } catch (e) {
      logger.e(e.toString());
    }
  }


}
