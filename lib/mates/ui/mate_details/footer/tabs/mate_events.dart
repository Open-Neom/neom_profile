import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/domain/model/event.dart';
import 'package:neom_commons/core/ui/widgets/event_tile.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

import '../../mate_details_controller.dart';

class MateEvents extends StatelessWidget {
  const MateEvents({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (_) => _.events.isNotEmpty ?
        ListView.builder(
            padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
            itemCount: _.events.length,
            itemBuilder: (context, index){
              Event event = _.events.values.elementAt(index);
              return event.eventDate <= 0 ? Container() :
              GestureDetector(
                onTap: () {
                  try {
                    //TODO VERIFY FUNCTIONALITY
                    // if(Get.find<EventDetailsController>().initialized) {
                    //   Get.find<EventDetailsController>().setEvent(event);
                    //   Navigator.of(context).popUntil(ModalRoute.withName(AppRouteConstants.eventDetails));
                    // } else {
                    //   Get.toNamed(AppRouteConstants.eventDetails, arguments: [event]);
                    // }
                    Get.toNamed(AppRouteConstants.eventDetails, arguments: [event]);
                  } catch (e) {
                    Get.toNamed(AppRouteConstants.eventDetails, arguments: [event]);
                  }

                },
                child: EventTile(event)
              );
            }
        ) :
        Image.asset(AppFlavour.getEventVector(),
            height: 150
        )
      );
    }
}
