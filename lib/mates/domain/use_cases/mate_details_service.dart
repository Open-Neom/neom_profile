import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';

abstract class MateDetailsService {

  Future<void> retrieveDetails();
  Future<void> loadMate(String mateId);
  Future<void> getMatePosts();
  Future<void> getAddressSimple();
  Future<void> getTotalInstruments();
  void getItemDetails(AppMediaItem appMediaItem);
  Future<void> follow();
  Future<void> unfollow();
  Future<void> blockProfile();
  Future<void> sendMessage();
  Future<void> unblockProfile(AppProfile blockedProfile);
  Future<void> getTotalItems();

}
