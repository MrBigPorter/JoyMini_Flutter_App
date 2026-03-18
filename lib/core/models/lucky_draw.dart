class LuckyDrawTicketQuery {
  final int page;
  final int pageSize;
  final bool? unusedOnly;

  const LuckyDrawTicketQuery({
    this.page = 1,
    this.pageSize = 20,
    this.unusedOnly,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (unusedOnly != null) {
      data['unusedOnly'] = unusedOnly;
    }
    return data;
  }
}

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

  factory LuckyDrawTicket.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');

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

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'activityId': activityId,
      'activityName': activityName,
      'status': status,
      'createdAt': createdAt,
      'expiredAt': expiredAt,
      'usedAt': usedAt,
    };
  }
}

class LuckyDrawResultItem {
  final String resultId;
  final String? ticketId;
  final String? activityName;
  final String? prizeName;
  final String? rewardType;
  final String? rewardRefId;
  final String? rewardSummary;
  final int? createdAt;

  const LuckyDrawResultItem({
    required this.resultId,
    this.ticketId,
    this.activityName,
    this.prizeName,
    this.rewardType,
    this.rewardRefId,
    this.rewardSummary,
    this.createdAt,
  });

  factory LuckyDrawResultItem.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');

    return LuckyDrawResultItem(
      resultId: (json['resultId'] ?? json['id'] ?? '').toString(),
      ticketId: json['ticketId']?.toString(),
      activityName: json['activityName']?.toString(),
      prizeName: json['prizeName']?.toString(),
      rewardType: json['rewardType']?.toString(),
      rewardRefId: json['rewardRefId']?.toString(),
      rewardSummary: json['rewardSummary']?.toString(),
      createdAt: toInt(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'ticketId': ticketId,
      'activityName': activityName,
      'prizeName': prizeName,
      'rewardType': rewardType,
      'rewardRefId': rewardRefId,
      'rewardSummary': rewardSummary,
      'createdAt': createdAt,
    };
  }
}

class LuckyDrawActionResult {
  final String? resultId;
  final String? prizeName;
  final String? rewardType;
  final String? rewardRefId;
  final String? rewardSummary;
  final bool? won;
  final String? message;

  const LuckyDrawActionResult({
    this.resultId,
    this.prizeName,
    this.rewardType,
    this.rewardRefId,
    this.rewardSummary,
    this.won,
    this.message,
  });

  factory LuckyDrawActionResult.fromJson(Map<String, dynamic> json) {
    return LuckyDrawActionResult(
      resultId: json['resultId']?.toString(),
      prizeName: json['prizeName']?.toString(),
      rewardType: json['rewardType']?.toString(),
      rewardRefId: json['rewardRefId']?.toString(),
      rewardSummary: json['rewardSummary']?.toString(),
      won: json['won'] as bool?,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'prizeName': prizeName,
      'rewardType': rewardType,
      'rewardRefId': rewardRefId,
      'rewardSummary': rewardSummary,
      'won': won,
      'message': message,
    };
  }
}

