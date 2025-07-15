import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/widgets/event_tile.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../profile_controller.dart';

class ProfileEvents extends StatelessWidget {
  
  const ProfileEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: AppPageIdConstants.profile,
      // init: ProfileController(),
      builder: (_) => _.events.isNotEmpty ?
      ListView.builder(
          padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
          itemCount: _.events.length,
          itemBuilder: (context, index){
            Event event = _.events.values.elementAt(index);
            return event.eventDate <= 0 ? const SizedBox.shrink() :
            GestureDetector(
              onTap: () => Get.toNamed(AppRouteConstants.eventDetails, arguments: [event]),
              child: EventTile(event),
            );
          })
          : Image.asset(AppFlavour.getEventVector(),
            height: 150
        )
      );
    }
}
