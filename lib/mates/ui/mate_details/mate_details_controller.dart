import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_commons/core/data/firestore/itemlist_firestore.dart';
import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_release_item.dart';
import 'package:neom_commons/core/domain/model/neom/chamber_preset.dart';
import 'package:neom_commons/core/utils/enums/verification_level.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:neom_frequencies/frequencies/data/firestore/frequency_firestore.dart';
import '../../../profile/ui/profile_controller.dart';
import '../../domain/use_cases/mate_details_service.dart';

class MateDetailsController extends GetxController implements MateDetailsService {

  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  Map<String, AppProfile> mates = <String, AppProfile>{};
  AppProfile mate = AppProfile();

  AppProfile profile = AppProfile();

  PostFirestore postFirestore = PostFirestore();

  String address = "";
  String instrumentsText = "";
  int distance = 0;

  Map<String, AppMediaItem> totalMediaItems = <String, AppMediaItem>{};
  Map<String, AppReleaseItem> totalReleaseItems = <String, AppReleaseItem>{};
  Map<String, AppMediaItem>  totalMixedItems = <String, AppMediaItem>{};
  Map<String, ChamberPreset> totalPresets = <String, ChamberPreset>{};

  Map<String, Itemlist> itemlists = <String, Itemlist>{};

  bool following = false;
  bool blockedProfile = false;

  Map<Post, Event> eventPosts = <Post, Event>{};
  Map<String, Event> events = <String, Event>{};
  
  bool isLoading = true;
  bool isLoadingDetails = true;
  bool isLoadingPosts = true;

  List<Post> matePosts = <Post>[];
  List<Post> mateBlogEntries = <Post>[];
  
  GeoLocatorService geoLocatorService = GeoLocatorController();
  bool debugPushNotifications = false;

  final Rx<VerificationLevel> verificationLevel = VerificationLevel.none.obs;
  final Rx<UserRole> newUserRole = UserRole.subscriber.obs;
  AppUser mateUser = AppUser();

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("onInit");

    String itemmateId = Get.arguments ?? "";

    try {
      profile = userController.profile;
      blockedProfile = profile.blockTo?.contains(itemmateId) ?? false;

      if(itemmateId.isNotEmpty && !blockedProfile) {
        await loadMate(itemmateId);
        await retrieveDetails();

        if(mate.id.isNotEmpty && (userController.user!.userRole == UserRole.subscriber || debugPushNotifications)) {
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
        AppUtilities.logger.i("Profile $itemmateId is blocked");
        isLoading = false;
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
      mate = await ProfileFirestore().retrieve(itemmateId);
      if(mate.id.isNotEmpty) {
        following = profile.following!.contains(itemmateId);
      }
      verificationLevel.value = mate.verificationLevel;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoading = false;
    update([AppPageIdConstants.mate, AppPageIdConstants.search]);
  }


  @override
  Future<void> retrieveDetails() async {
    AppUtilities.logger.t("retrieveDetails");
    try {
      mate.itemlists = await ItemlistFirestore().fetchAll(ownerId: mate.id);
      itemlists = mate.itemlists ?? {};

      if(mate.posts?.isNotEmpty ?? false) {
        getMatePosts();
      }

      getAddressSimple();
      getTotalInstruments(); ///NO NEED TO WAIT FOR IT
      getTotalItems();

      if((mate.events?.isNotEmpty ?? false)
          || (mate.goingEvents?.isNotEmpty ?? false)
          || (mate.playingEvents?.isNotEmpty ?? false)) {
        getTotalEvents();
      }

      for (var post in matePosts) {
        eventPosts[post] = events[post.referenceId] ?? Event();
      }

      instrumentsText = CoreUtilities.getInstruments(mate.instruments ?? {});

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    isLoadingDetails = false;
    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> getMatePosts() async {
    AppUtilities.logger.t("getMatePosts");

    try {
      matePosts = await postFirestore.getProfilePosts(mate.id);

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

    isLoadingPosts = false;
    update([AppPageIdConstants.mate]);
  }


  void clear() {
    mates = <String, AppProfile>{};
  }


  @override
  Future<void> getAddressSimple() async {
    AppUtilities.logger.t('getAddressSimple');

    try {
      if(mate.position!.latitude != 0 && mate.position!.longitude != 0) {
        address = await geoLocatorService.getAddressSimple(mate.position!);
        distance = AppUtilities.distanceBetweenPositionsRounded(profile.position!, mate.position!);
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

    if(mate.itemlists?.isNotEmpty ?? false) {
      if(AppFlavour.appInUse == AppInUse.c) {
        mate.frequencies = await FrequencyFirestore().retrieveFrequencies(mate.id);
        for (var freq in mate.frequencies!.values) {
          totalPresets[freq.frequency.toString()] = ChamberPreset.custom(frequency: freq);
        }
        totalPresets.addAll(CoreUtilities.getTotalPresets(mate.chambers!));
      } else {
        totalMediaItems = CoreUtilities.getTotalMediaItems(mate.itemlists!);
        totalReleaseItems = CoreUtilities.getTotalReleaseItems(mate.itemlists!);
      }
    } else if(mate.favoriteItems?.isNotEmpty ?? false){
      totalMediaItems = await AppMediaItemFirestore().retrieveFromList(mate.favoriteItems!);
      totalReleaseItems = await AppReleaseItemFirestore().retrieveFromList(mate.favoriteItems!);
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
      if(mate.events != null && mate.events!.isNotEmpty) {
        Map<String, Event> createdEvents = await EventFirestore().getEventsById(mate.events!);
        AppUtilities.logger.d("${createdEvents.length} created events founds for mate ${mate.id}");
        events.addAll(createdEvents);
      }

      if(mate.playingEvents != null && mate.playingEvents!.isNotEmpty) {
        Map<String, Event> playingEvents = await EventFirestore().getEventsById(mate.playingEvents!);
        AppUtilities.logger.d("${playingEvents.length} playing events founds for mate ${mate.id}");
        events.addAll(playingEvents);
      }

      if(mate.goingEvents != null && mate.goingEvents!.isNotEmpty) {
        Map<String, Event> goingEvents = await EventFirestore().getEventsById(mate.goingEvents!);
        AppUtilities.logger.d("${goingEvents.length} going events founds for mate ${mate.id}");
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
      mate.instruments = await InstrumentFirestore().retrieveInstruments(mate.id);
      AppUtilities.logger.t("${mate.instruments?.length ?? 0} Total Instruments for Profile");
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
    AppUtilities.logger.t("Follow profile ${mate.id}");

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
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }


  @override
  Future<void> unfollow() async {
    AppUtilities.logger.t("Unfollow ${mate.id}");
    try {
      if (await ProfileFirestore().unfollowProfile(profileId: profile.id,unfollowProfileId:  mate.id)) {
        following = false;
        userController.profile.following!.remove(mate.id);
        mate.followers!.remove(profile.id,);
        Get.find<ProfileController>().removeFollowing(mate.id);
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
          profileToBlock: mate.id)) {
        following = false;
        userController.profile.following!.remove(mate.id);
        mate.followers?.remove(profile.id);
        mate.blockedBy?.add(profile.id);

        userController.profile.blockTo!.add(mate.id);

        AppUtilities.showSnackBar(
            title: AppTranslationConstants.blockProfile.tr,
            message: AppTranslationConstants.blockedProfileMsg.tr);
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
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.unblockProfile.tr,
            message: AppTranslationConstants.unblockedProfileMsg.tr
        );
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
      inbox = await InboxFirestore().getOrCreateInboxRoom(profile, mate);

      inbox.id.isNotEmpty ? Get.toNamed(AppRouteConstants.inboxRoom, arguments: [inbox])
        : Get.toNamed(AppRouteConstants.home);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> removeProfile() async {
    AppUtilities.logger.d("Remove Profile from Application - Admin Function");
    try {
      AppUser userFromProfile = await UserFirestore().getByProfileId(mate.id);

      if (await ProfileFirestore().remove(userId: userFromProfile.id, profileId: mate.id)) {
        if(following) {
          ProfileFirestore().unfollowProfile(profileId: profile.id, unfollowProfileId: mate.id);
          userController.profile.following!.remove(mate.id);
        }

        AppUtilities.showSnackBar(
          title: AppTranslationConstants.removeProfile.tr,
          message: AppTranslationConstants.removedProfileMsg.tr
        );
      } else {
        AppUtilities.logger.i("Something happened while removing profile");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    Get.back();
    Get.back();
    update([AppPageIdConstants.mate, AppPageIdConstants.profile, AppPageIdConstants.home]);
  }

  @override
  void selectVerificationLevel(VerificationLevel level) {
    try {
      verificationLevel.value = level;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateVerificationLevel() async {
    try {
      if(await ProfileFirestore().updateVerificationLevel(mate.id, verificationLevel.value)) {
        mate.verificationLevel = verificationLevel.value;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }

  @override
  void selectUserRole(UserRole role) {
    try {
      newUserRole.value = role;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateUserRole() async {
    try {
      if(newUserRole.value != mateUser.userRole && mateUser.id.isNotEmpty) {
        await UserFirestore().updateUserRole(mateUser.id, newUserRole.value);
        Get.back();
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateUserRole.tr,
            message: AppTranslationConstants.updateUserRoleSuccess.tr);
      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateUserRoleSame.tr,
            message: AppTranslationConstants.updateUserRoleSame.tr);
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Future<void> getUserInfo() async {

    try {
      mateUser = await UserFirestore().getByProfileId(mate.id);
      newUserRole.value = mateUser.userRole;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.mate]);
  }



}
