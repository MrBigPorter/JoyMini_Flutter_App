import 'package:flutter_app/app/routes/app_router.dart';

import '../fcm_payload.dart';
import 'base_handler.dart';

/// FCM 抽奖券推送处理器
///
/// payload.type == 'lucky_draw' 时触发，点击通知直达抽奖券列表页。
class LuckyDrawActionHandler implements FcmActionHandler {
  @override
  void handle(FcmPayload payload) {
    appRouter.pushNamed('luckyDraw');
  }
}

