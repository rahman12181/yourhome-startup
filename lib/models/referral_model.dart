// lib/models/referral_model.dart

class ReferralInfo {
  final String referralCode;
  final String referralLink;
  final String shareMessage;
  final int totalReferred;
  final int totalRewarded;
  final double totalEarned;
  final double walletBalance;
  final double rewardPerReferral;

  ReferralInfo({
    required this.referralCode,
    required this.referralLink,
    required this.shareMessage,
    required this.totalReferred,
    required this.totalRewarded,
    required this.totalEarned,
    required this.walletBalance,
    required this.rewardPerReferral,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      referralCode: json['referralCode'] ?? '',
      referralLink: json['referralLink'] ?? '',
      shareMessage: json['shareMessage'] ?? '',
      totalReferred: json['totalReferred'] ?? 0,
      totalRewarded: json['totalRewarded'] ?? 0,
      totalEarned: (json['totalEarned'] ?? 0).toDouble(),
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      rewardPerReferral: (json['rewardPerReferral'] ?? 19).toDouble(),
    );
  }
}

class ReferralHistory {
  final String referredUserName;
  final String referredUserDisplayId;
  final String status; // PENDING, REWARDED
  final double rewardAmount;
  final String joinedAt;
  final String? rewardedAt;

  ReferralHistory({
    required this.referredUserName,
    required this.referredUserDisplayId,
    required this.status,
    required this.rewardAmount,
    required this.joinedAt,
    this.rewardedAt,
  });

  factory ReferralHistory.fromJson(Map<String, dynamic> json) {
    return ReferralHistory(
      referredUserName: json['referredUserName'] ?? '',
      referredUserDisplayId: json['referredUserDisplayId'] ?? '',
      status: json['status'] ?? 'PENDING',
      rewardAmount: (json['rewardAmount'] ?? 0).toDouble(),
      joinedAt: json['joinedAt'] ?? '',
      rewardedAt: json['rewardedAt'],
    );
  }
}

class WalletTransaction {
  final int transactionId;
  final String type; // CREDIT, DEBIT
  final double amount;
  final String reason;
  final double balanceAfter;
  final String description;
  final String createdAt;

  WalletTransaction({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.reason,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      transactionId: json['transactionId'] ?? 0,
      type: json['type'] ?? 'CREDIT',
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class WalletTransactionsResponse {
  final List<WalletTransaction> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool last;

  WalletTransactionsResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.last,
  });

  factory WalletTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List? ?? [];
    return WalletTransactionsResponse(
      content: contentList.map((item) => WalletTransaction.fromJson(item)).toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      number: json['number'] ?? 0,
      size: json['size'] ?? 20,
      last: json['last'] ?? true,
    );
  }
}

class WithdrawalRequest {
  final int withdrawalId;
  final double amount;
  final String upiId;
  final String status; // PENDING, APPROVED, REJECTED
  final String? transactionRef;
  final String? adminNote;
  final String requestedAt;
  final String? processedAt;

  WithdrawalRequest({
    required this.withdrawalId,
    required this.amount,
    required this.upiId,
    required this.status,
    this.transactionRef,
    this.adminNote,
    required this.requestedAt,
    this.processedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      withdrawalId: json['withdrawalId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      upiId: json['upiId'] ?? '',
      status: json['status'] ?? 'PENDING',
      transactionRef: json['transactionRef'],
      adminNote: json['adminNote'],
      requestedAt: json['requestedAt'] ?? '',
      processedAt: json['processedAt'],
    );
  }
}

class WithdrawalResponse {
  final int withdrawalId;
  final double amount;
  final String upiId;
  final String status;
  final String requestedAt;

  WithdrawalResponse({
    required this.withdrawalId,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.requestedAt,
  });

  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalResponse(
      withdrawalId: json['withdrawalId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      upiId: json['upiId'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: json['requestedAt'] ?? '',
    );
  }
}

class PendingWithdrawal {
  final int withdrawalId;
  final double amount;
  final String upiId;
  final String status;
  final String requestedAt;
  final int userId;
  final String userName;
  final String userDisplayId;

  PendingWithdrawal({
    required this.withdrawalId,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.requestedAt,
    required this.userId,
    required this.userName,
    required this.userDisplayId,
  });

  factory PendingWithdrawal.fromJson(Map<String, dynamic> json) {
    return PendingWithdrawal(
      withdrawalId: json['withdrawalId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      upiId: json['upiId'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: json['requestedAt'] ?? '',
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      userDisplayId: json['userDisplayId'] ?? '',
    );
  }
}