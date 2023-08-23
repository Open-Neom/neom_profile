import 'package:neom_commons/core/domain/model/app_media_item.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';

abstract class ProfileService {

  Future<void> editProfile();

  void getItemDetails(AppMediaItem appMediaItem);
  void getTotalItems();

  Future<void> updateLocation();
  Future<void> updateProfileData();

  void addFollowing(String followingId);
  void removeFollowing(String followingId);
  void addBlockTo(String followingId);

  Future<void> handleAndUploadImage(UploadImageType uploadType);

}
