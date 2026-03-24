import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// ─── Prize Type ───────────────────────────────────────────────────────────────
// 与后端一致：1=优惠券  2=金币  3=余额  4=谢谢参与
enum LuckyDrawPrizeType {
  coupon(1),
  coin(2),
  balance(3),
  thanks(4);

  const LuckyDrawPrizeType(this.value);
  final int value;

  static LuckyDrawPrizeType fromValue(int? v) {
    return LuckyDrawPrizeType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => LuckyDrawPrizeType.thanks,
    );
  }

  IconData get icon => switch (this) {
        LuckyDrawPrizeType.coupon  => Icons.local_offer_rounded,
        LuckyDrawPrizeType.coin    => Icons.monetization_on_rounded,
        LuckyDrawPrizeType.balance => Icons.account_balance_wallet_rounded,
        LuckyDrawPrizeType.thanks  => Icons.favorite_border_rounded,
      };

  String get label => switch (this) {
        LuckyDrawPrizeType.coupon  => 'Coupon',
        LuckyDrawPrizeType.coin    => 'Coins',
        LuckyDrawPrizeType.balance => 'Balance',
        LuckyDrawPrizeType.thanks  => 'Thanks',
      };
}

// ─── Ticket Query ─────────────────────────────────────────────────────────────
class LuckyDrawTicketQuery {
  final int page;
  final int pageSize;
  final bool? unusedOnly;

  const LuckyDrawTicketQuery({
    this.page = 1,
    this.pageSize = 20,
    this.unusedOnly,
  });

  LuckyDrawTicketQuery copyWith({int? page, int? pageSize, bool? unusedOnly}) {
    return LuckyDrawTicketQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      unusedOnly: unusedOnly ?? this.unusedOnly,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (unusedOnly != null) data['unusedOnly'] = unusedOnly;
    return data;
  }

  @override
  bool operator ==(Object other) =>
      other is LuckyDrawTicketQuery &&
      other.page == page &&
      other.pageSize == pageSize &&
      other.unusedOnly == unusedOnly;

  @override
  int get hashCode => Object.hash(page, pageSize, unusedOnly);
}

// ─── Ticket ───────────────────────────────────────────────────────────────────
class LuckyDrawTicket {
  final String ticketId;
  final String? activityId;
  final String? activityName;
  final String? status;
  final int? createdAt;
  final int? expiredAt;
  final int? usedAt;

  const LuckyDrawTicket({
    required this.ticketId,
    this.activityId,
    this.activityName,
    this.status,
    this.createdAt,
    this.expiredAt,
    this.usedAt,
  });

  /// 是否临近过期（距离过期时间不足 24 小时）
  bool get isExpiringSoon {
    if (expiredAt == null || expiredAt! <= 0) return false;
    final bool isMs = expiredAt! > 1000000000000;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      isMs ? expiredAt! : expiredAt! * 1000,
    );
    return expiry.difference(DateTime.now()).inHours < 24 &&
        expiry.isAfter(DateTime.now());
  }

  /// 是否已过期
  bool get isExpired {
    if (expiredAt == null || expiredAt! <= 0) return false;
    final bool isMs = expiredAt! > 1000000000000;
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      isMs ? expiredAt! : expiredAt! * 1000,
    );
    return expiry.isBefore(DateTime.now());
  }

  factory LuckyDrawTicket.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) =>
        value is num ? value.toInt() : int.tryParse('$value');

    return LuckyDrawTicket(
      ticketId: (json['ticketId'] ?? json['id'] ?? '').toString(),
      activityId: json['activityId']?.toString(),
      activityName: json['activityName']?.toString(),
      status: json['status']?.toString(),
      createdAt: toInt(json['createdAt']),
      expiredAt: toInt(json['expiredAt']),
      usedAt: toInt(json['usedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ticketId': ticketId,
        'activityId': activityId,
        'activityName': activityName,
        'status': status,
        'createdAt': createdAt,
        'expiredAt': expiredAt,
        'usedAt': usedAt,
      };
}

// ─── Result Item ──────────────────────────────────────────────────────────────
class LuckyDrawResultItem {
  final String resultId;
  final String? ticketId;
  final String? activityName;
  final String? prizeName;
  final int? prizeType;        // 1=优惠券 2=金币 3=余额 4=谢谢参与
  final String? rewardType;
  final String? rewardRefId;
  final String? rewardSummary;
  final int? createdAt;

  const LuckyDrawResultItem({
    required this.resultId,
    this.ticketId,
    this.activityName,
    this.prizeName,
    this.prizeType,
    this.rewardType,
    this.rewardRefId,
    this.rewardSummary,
    this.createdAt,
  });

  LuckyDrawPrizeType get prizeTypeEnum =>
      LuckyDrawPrizeType.fromValue(prizeType);

  factory LuckyDrawResultItem.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) =>
        value is num ? value.toInt() : int.tryParse('$value');

    return LuckyDrawResultItem(
      resultId: (json['resultId'] ?? json['id'] ?? '').toString(),
      ticketId: json['ticketId']?.toString(),
      activityName: json['activityName']?.toString(),
      prizeName: json['prizeName']?.toString(),
      prizeType: toInt(json['prizeType']),
      rewardType: json['rewardType']?.toString(),
      rewardRefId: json['rewardRefId']?.toString(),
      rewardSummary: json['rewardSummary']?.toString(),
      createdAt: toInt(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'resultId': resultId,
        'ticketId': ticketId,
        'activityName': activityName,
        'prizeName': prizeName,
        'prizeType': prizeType,
        'rewardType': rewardType,
        'rewardRefId': rewardRefId,
        'rewardSummary': rewardSummary,
        'createdAt': createdAt,
      };
}

// ─── Action Result ────────────────────────────────────────────────────────────
class LuckyDrawActionResult {
  final String? resultId;
  final String? prizeName;
  final int? prizeType;        // 1=优惠券 2=金币 3=余额 4=谢谢参与
  final String? rewardType;
  final String? rewardRefId;
  final String? rewardSummary;
  final bool? won;
  final String? message;

  const LuckyDrawActionResult({
    this.resultId,
    this.prizeName,
    this.prizeType,
    this.rewardType,
    this.rewardRefId,
    this.rewardSummary,
    this.won,
    this.message,
  });

  LuckyDrawPrizeType get prizeTypeEnum =>
      LuckyDrawPrizeType.fromValue(prizeType);

  factory LuckyDrawActionResult.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse('$v');
    return LuckyDrawActionResult(
      resultId: json['resultId']?.toString(),
      prizeName: json['prizeName']?.toString(),
      prizeType: toInt(json['prizeType']),
      rewardType: json['rewardType']?.toString(),
      rewardRefId: json['rewardRefId']?.toString(),
      rewardSummary: json['rewardSummary']?.toString(),
      won: json['won'] as bool?,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'resultId': resultId,
        'prizeName': prizeName,
        'prizeType': prizeType,
        'rewardType': rewardType,
        'rewardRefId': rewardRefId,
        'rewardSummary': rewardSummary,
        'won': won,
        'message': message,
      };
}
