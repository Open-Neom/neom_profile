import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/utils/app_color.dart';

import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'footer/mate_detail_footer.dart';
import 'header/mate_details_header.dart';
import 'mate_details_body.dart';
import 'mate_details_controller.dart';

class MateDetailsPage extends StatelessWidget {
  const MateDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      Get.delete<MateDetailsController>();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: AppTheme.appBoxDecoration,
          child: _.isLoading ? const AppCircularProgressIndicator()
              : _.blockedProfile ? Container() : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MateDetailHeader(),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.padding20),
                    child: const MateDetailsBody(),
                  ),
                  _.isLoadingDetails ? const Center(
                      child: CircularProgressIndicator())
                      : const MateShowcase(),
                ],
              ),
          ),
        ),
      ),
    );
  }
}
