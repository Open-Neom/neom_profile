import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_frequencies/frequencies/data/firestore/frequency_firestore.dart';
import 'package:neom_itemlists/itemlists/data/firestore/app_media_item_firestore.dart';
import '../../../profile/ui/profile_controller.dart';
import '../../domain/use_cases/mate_details_service.dart';

class MateDetailsController extends GetxController implements MateDetailsService {

  
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  final RxMap<String, AppProfile> mates = <String, AppProfile>{}.obs;
  
  final Rx<AppProfile> mate = AppProfile().obs;

  AppProfile profile = AppProfile();

  final RxString address = "".obs;
  final RxString instrumentsText = "".obs;
  final RxInt distance = 0.obs;

  final RxMap<String, AppMediaItem> totalMediaItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, AppReleaseItem> totalReleaseItems = <String, AppReleaseItem>{}.obs;
  final RxMap<String, AppMediaItem>  totalMixedItems = <String, AppMediaItem>{}.obs;
  final RxMap<String, ChamberPreset> totalPresets = <String, ChamberPreset>{}.obs;

  final RxMap<String, Itemlist> itemlists = <String, Itemlist>{}.obs;

  final RxBool following = false.obs;
  final RxBool blockedProfile = false.obs;

  final RxMap<Post, Event> eventPosts = <Post, Event>{}.obs;
  final RxMap<String, Event> events = <String, Event>{}.obs;
  
  final RxBool isLoading = true.obs;
  final RxBool isLoadingDetails = true.obs;
  final RxBool isButtonDisabled = false.obs;

  List<Post> matePosts = <Post>[];
  List<Post> mateBlogEntries = <Post>[];
  
  GeoLocatorService geoLocatorService = GeoLocatorController();

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("onInit");

    String itemmateId = Get.arguments ?? "";

    try {
      profile = userController.profile;
      blockedProfile.value = profile.blockTo?.contains(itemmateId) ?? false;

      if(itemmateId.isNotEmpty && !blockedProfile.value) {
        await loadMate(itemmateId);
        await retrieveDetails();

        if(mate.value.id.isNotEmpty && (userController.user!.userRole == UserRole.subscriber || kDebugMode)) {
          FirebaseMessagingCalls.sendPrivatePushNotification(
            toProfileId: mate.value.id,
            fromProfile: profile,
            notificationType: PushNotificationType.viewProfile,
            referenceId: profile.id,
          );

          FirebaseMessagingCalls.sendGlobalPushNotification(
            fromProfile: profile,
            toProfile: mate.value,
            notificationType: PushNotificationType.viewProfile,
            referenceId: mate.value.id,
          );
        }
      } else {
        AppUtilities.logger.i("Profile $itemmateId is blocked");
        isLoading.value = false;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }


  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.d("Itemmate Controller Ready");
    try {
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> loadMate(String itemmateId) async {
    AppUtilities.logger.t("loadMate $itemmateId}");

    try {
      mate.value = await ProfileFirestore().retrieve(itemmateId);
      if(mate.value.id.isNotEmpty) {
        following.value = profile.following!.contains(itemmateId);
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading.value = false;
    update([AppPageIdConstants.mate, AppPageIdConstants.search]);
  }


  @override
  Future<void> retrieveDetails() async {
    AppUtilities.logger.t("retrieveDetails");
    try {
      mate.value.itemlists = await ItemlistFirestore().fetchAll(ownerId: mate.value.id);
      itemlists.value = mate.value.itemlists ?? {};

      await getTotalInstruments();
      await getAddressSimple();

      if(mate.value.posts?.isNotEmpty ?? false) {
        await getMatePosts();
      }

      if((mate.value.events?.isNotEmpty ?? false)
          || (mate.value.goingEvents?.isNotEmpty ?? false)
          || (mate.value.playingEvents?.isNotEmpty ?? false)) {
        await getTotalEvents();
      }

      await getTotalItems();

      for (var post in matePosts) {
        eventPosts[post] = events[post.referenceId] ?? Event();
      }

      instrumentsText.value = CoreUtilities.getInstruments(mate.value.instruments ?? {});

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoadingDetails.value = false;
    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> getMatePosts() async {
    AppUtilities.logger.t("getMatePosts");

    try {
      matePosts = await PostFirestore().getProfilePosts(mate.value.id);

      for (var post in matePosts) {
        if(post.type == PostType.blogEntry && !post.isDraft) {
          mateBlogEntries.add(post);
        }
      }
      matePosts.removeWhere((element) => element.type == PostType.blogEntry);
      matePosts.removeWhere((element) => element.type == PostType.caption);
      AppUtilities.logger.d("${mateBlogEntries.length} Total Blog Entries for Profile");
      AppUtilities.logger.d("${matePosts.length} Total Posts for Profile");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    //isLoading.value = false;
    update([AppPageIdConstants.mate]);
  }


  void clear() {
    mates.value = <String, AppProfile>{};
  }


  @override
  Future<void> getAddressSimple() async {
    AppUtilities.logger.t('getAddressSimple');

    try {
      if(mate.value.position!.latitude != 0 && mate.value.position!.longitude != 0) {
        address.value = await geoLocatorService.getAddressSimple(mate.value.position!);
        distance.value = AppUtilities.distanceBetweenPositionsRounded(profile.position!, mate.value.position!);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("$address and $distance km");
    update([AppPageIdConstants.mate]);
  }

  @override
  Future<void> getTotalItems() async {
    AppUtilities.logger.t("getTotalItems");

    if(mate.value.itemlists?.isNotEmpty ?? false) {
      if(AppFlavour.appInUse == AppInUse.c) {
        mate.value.frequencies = await FrequencyFirestore().retrieveFrequencies(mate.value.id);
        for (var freq in mate.value.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = ChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(mate.value.chambers!));
      } else {
        totalMediaItems.value = CoreUtilities.getTotalMediaItems(mate.value.itemlists!);
        totalReleaseItems.value = CoreUtilities.getTotalReleaseItems(mate.value.itemlists!);
      }
    } else if(mate.value.favoriteItems?.isNotEmpty ?? false){
      totalMediaItems.value = await AppMediaItemFirestore().retrieveFromList(mate.value.favoriteItems!);
      totalReleaseItems.value = await AppReleaseItemFirestore().retrieveFromList(mate.value.favoriteItems!);
    }

    for (var item in totalReleaseItems.values) {
      totalMixedItems[item.id] = AppMediaItem.fromAppReleaseItem(item);
    }
    totalMixedItems.addAll(totalMediaItems);
    AppUtilities.logger.d("${totalMixedItems.length} Total Items for Profile");

    update([AppPageIdConstants.mate]);
  }

  Future<void> getTotalEvents()  async{
    AppUtilities.logger.t("getTotalEvents for mate");

    try {
      if(mate.value.events != null && mate.value.events!.isNotEmpty) {
        Map<String, Event> createdEvents = await EventFirestore().getEventsById(mate.value.events!);
        AppUtilities.logger.d("${createdEvents.length} created events founds for mate ${mate.value.id}");
        events.addAll(createdEvents);
      }

      if(mate.value.playingEvents != null && mate.value.playingEvents!.isNotEmpty) {
        Map<String, Event> playingEvents = await EventFirestore().getEventsById(mate.value.playingEvents!);
        AppUtilities.logger.d("${playingEvents.length} playing events founds for mate ${mate.value.id}");
        events.addAll(playingEvents);
      }

      if(mate.value.goingEvents != null && mate.value.goingEvents!.isNotEmpty) {
        Map<String, Event> goingEvents = await EventFirestore().getEventsById(mate.value.goingEvents!);
        AppUtilities.logger.d("${goingEvents.length} going events founds for mate ${mate.value.id}");
        events.addAll(goingEvents);
      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${events.length} Total Events for Itemmate");
    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> getTotalInstruments() async {
    AppUtilities.logger.t('getTotalInstruments');

    try {
      mate.value.instruments = await InstrumentFirestore().retrieveInstruments(mate.value.id);
      AppUtilities.logger.t("${mate.value.instruments?.length ?? 0} Total Instruments for Profile");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  void getItemDetails(AppMediaItem appMediaItem) {
    AppUtilities.logger.d("getItemDetails for ${appMediaItem.name}");
    if (AppFlavour.appInUse == AppInUse.g) {
      ///DEPRECATED Get.to(() => MediaPlayerPage(appMediaItem: appMediaItem), transition: Transition.downToUp);
      Get.toNamed(AppRouteConstants.musicPlayerMedia, arguments: [appMediaItem]);
    } else {
      Get.toNamed(AppFlavour.getItemDetailsRoute(), arguments: [appMediaItem]);
    }
  }

  @override
  Future<void> follow() async {
    AppUtilities.logger.t("Follow profile ${mate.value.id}");

    try {
      if(await ProfileFirestore().followProfile(profileId: profile.id, followedProfileId:  mate.value.id)) {
        following.value = true;
        mate.value.followers!.add(profile.id);

        try {
          Get.find<ProfileController>().addFollowing(mate.value.id);
        } catch (e) {
          Get.put(ProfileController()).addFollowing(mate.value.id);
        }

        ActivityFeed activityFeed = ActivityFeed();
        activityFeed.ownerId =  mate.value.id;
        activityFeed.profileId = profile.id;
        activityFeed.createdTime = DateTime.now().millisecondsSinceEpoch;
        activityFeed.activityFeedType = ActivityFeedType.follow;
        activityFeed.profileName = profile.name;
        activityFeed.profileImgUrl = profile.photoUrl;
        activityFeed.activityReferenceId = profile.id;

        ActivityFeedFirestore().insert(activityFeed);

        FirebaseMessagingCalls.sendPrivatePushNotification(
          toProfileId: mate.value.id,
          fromProfile: profile,
          notificationType: PushNotificationType.following,
          referenceId: profile.id,
        );

        FirebaseMessagingCalls.sendGlobalPushNotification(
          fromProfile: profile,
          toProfile: mate.value,
          notificationType: PushNotificationType.following,
          referenceId: mate.value.id,
        );

      }

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> unfollow() async {
    AppUtilities.logger.t("Unfollow ${mate.value.id}");
    try {
      if (await ProfileFirestore().unfollowProfile(profileId: profile.id,unfollowProfileId:  mate.value.id)) {
        following.value = false;
        userController.profile.following!.remove(mate.value.id);
        mate.value.followers!.remove(profile.id,);
        Get.find<ProfileController>().removeFollowing(mate.value.id);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }


  @override
  Future<void> blockProfile() async {
    AppUtilities.logger.d("");
    try {
      if (await ProfileFirestore().blockProfile(
          profileId: profile.id,
          profileToBlock: mate.value.id)) {
        following.value = false;
        userController.profile.following!.remove(mate.value.id);
        mate.value.followers?.remove(profile.id);
        mate.value.blockedBy?.add(profile.id);

        userController.profile.blockTo!.add(mate.value.id);
      } else {
        AppUtilities.logger.i("Something happened while blocking profile");
      }
    } catch (e) {
        AppUtilities.logger.e(e.toString());
    }

    Get.back();
    Get.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }



  @override
  Future<void> unblockProfile(AppProfile blockedProfile) async {
    AppUtilities.logger.d("");
    try {
      if (await ProfileFirestore().unblockProfile(profileId: userController.profile.id, profileToUnblock:  blockedProfile.id)) {
        userController.profile.blockTo!.remove(blockedProfile.id);
        blockedProfile.blockedBy!.remove(profile.id);
      } else {
        AppUtilities.logger.i("Somethnig happened while unblocking profile");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    Get.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile]);
  }


  @override
  Future<void> sendMessage() async {
    AppUtilities.logger.d("");

    Inbox inbox = Inbox();

    try {
      inbox = await InboxFirestore().getOrCreateInboxRoom(profile, mate.value);

      inbox.id.isNotEmpty ? Get.toNamed(AppRouteConstants.inboxRoom, arguments: [inbox])
        : Get.toNamed(AppRouteConstants.home);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }


}
