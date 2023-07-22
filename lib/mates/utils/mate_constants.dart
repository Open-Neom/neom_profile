import '../../../mates/ui/mate_details/footer/tabs/mate_events.dart';
import '../../../mates/ui/mate_details/footer/tabs/mate_items.dart';
import '../../../mates/ui/mate_details/footer/tabs/mate_posts.dart';
import '../ui/mate_details/footer/tabs/mate_chamber_presets.dart';

class MateConstants {

  static final neomMateTabPages = [const MatePosts(), const MateChamberPresets(), const MateEvents()];
  static final mateTabPages = [const MatePosts(), const MateItems(), const MateEvents()];

}
