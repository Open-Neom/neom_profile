import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/read_more_container.dart';
import 'package:neom_commons/core/utils/enums/verification_level.dart';
import 'package:neom_commons/neom_commons.dart';

import 'mate_details_controller.dart';

class MateDetailsBody extends StatelessWidget {
  const MateDetailsBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textTheme = theme.textTheme;
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (_) =>  _.isLoading.value ? const Center(child: CircularProgressIndicator())
      : Obx(()=> Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                  child: Text(CoreUtilities.capitalizeFirstLetter(_.mate.value.name),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white),
                  ),
                ),
                AppTheme.widthSpace5,
                if(_.mate.value.verificationLevel != VerificationLevel.none)
                  const SizedBox(height: 30, child: Icon(Icons.verified, size: 20,)),
              ]
          ),
          _.mate.value.type != ProfileType.fan ?
          Row(
            children: [
              Icon(AppFlavour.getInstrumentIcon(), size: 15.0),
              AppTheme.widthSpace5,
              Text(_.mate.value.mainFeature.tr.capitalize,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColor.white
                ),
              ),
            ],
          ) : const SizedBox.shrink(),
          _.mate.value.genres != null ? GenresGridView(
            _.mate.value.genres?.keys.toList() ?? [],
            AppColor.white,
            alignment: Alignment.centerLeft,
            fontSize: 15,
          ) : const SizedBox.shrink(),
          SizedBox(
            child: _.address.value.isNotEmpty && _.distance > 0.0
                ? _buildLocationInfo(_.address.value, _.distance.value, textTheme)
                : const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ReadMoreContainer(
              text: _.mate.value.aboutMe.isEmpty
                  ? AppTranslationConstants.noProfileDesc.tr
                  : CoreUtilities.capitalizeFirstLetter(_.mate.value.aboutMe),
              color: Colors.white70,
            )
          ),
        ]),
      ),
    );
  }

  Widget _buildLocationInfo(String addressSimple, int distance,  TextTheme textTheme) {
    return Row(
        children: <Widget>[
          Icon(Icons.place,
            color: AppColor.white80,
            size: 16.0,
          ),
          AppTheme.widthSpace5,
          Text(addressSimple.isEmpty ? AppTranslationConstants.notSpecified.tr : addressSimple.length > AppConstants.maxLocationNameLength
              ? "${addressSimple.substring(0,AppConstants.maxLocationNameLength)}..." : addressSimple,
            style: textTheme.titleSmall!.copyWith(color: AppColor.white80),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(distance == 0 ? "" : "- ${distance.ceil().toString()} ${AppConstants.km}",
              style: textTheme.titleSmall!.copyWith(color: AppColor.white80),
            ),
          ),
        ],
      );
  }
}
