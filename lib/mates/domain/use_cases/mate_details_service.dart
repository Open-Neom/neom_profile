import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';

abstract class MateDetailsService {

  Future<void> retrieveDetails();
  Future<void> loadMate(String mateId);
  Future<void> getMatePosts();
  Future<void> getAddressSimple();
  Future<void> getTotalInstruments();
  void getItemDetails(AppItem appItem);
  Future<void> follow();
  Future<void> unfollow();
  Future<void> blockProfile();
  Future<void> sendMessage();
  Future<void> unblockProfile(AppProfile blockedProfile);

}
