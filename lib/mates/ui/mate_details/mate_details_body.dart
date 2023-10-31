import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/neom_commons.dart';
import 'package:readmore/readmore.dart';

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
      builder: (_) =>  _.isLoading ? const Center(child: CircularProgressIndicator())
      : Obx(()=> Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_.mate.name.capitalize, style: textTheme.headlineSmall!.copyWith()),
          _.mate.type != ProfileType.fan ?
          Row(
            children: [
              Icon(AppFlavour.getInstrumentIcon(),
                size: 15.0),
              AppTheme.widthSpace5,
              Text(_.mate.mainFeature.tr.capitalize,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColor.white
                ),
              ),
            ],
          ) : Container(),
          _.mate.genres != null ? GenresGridView(
            _.mate.genres?.keys.toList() ?? [],
            AppColor.white,
            alignment: Alignment.centerLeft,
            fontSize: 15,
          ) : Container(),
          Container(
            child: _.address.isNotEmpty && _.distance > 0.0
                ? _buildLocationInfo(_.address, _.distance, textTheme)
                : Container(),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: ReadMoreText(_.mate.aboutMe.isEmpty ? AppTranslationConstants.noProfileDesc.tr : _.mate.aboutMe.capitalizeFirst,
              trimLines: 6,
              colorClickableText: Colors.grey.shade500,
              trimMode: TrimMode.Line,
              trimCollapsedText: '... ${AppTranslationConstants.readMore.tr}',
              textAlign: TextAlign.justify,
              style: textTheme.bodyMedium!.copyWith(color: Colors.white70, fontSize: 16.0),
              trimExpandedText: ' ${AppTranslationConstants.less.tr.capitalize}',
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLocationInfo(String addressSimple, int distance,  TextTheme textTheme) {
    return Row(
        children: <Widget>[
          Icon(
            Icons.place,
            color: AppColor.white80,
            size: 16.0,
          ),
          AppTheme.widthSpace5,
          Text(addressSimple.isEmpty ? AppTranslationConstants.notSpecified.tr : addressSimple,
            style: textTheme.titleSmall!.copyWith(color: AppColor.white80),
          ),
          Container(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(distance == 0 ? "" : "- ${distance.ceil().toString()} ${AppConstants.km}",
              style: textTheme.titleSmall!.copyWith(color: AppColor.white80),
            ),
          ),
        ],
      );
  }
}
