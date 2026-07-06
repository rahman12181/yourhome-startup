class Property {
  final int propertyId;
  final String title;
  final String description;
  final String propertyType;
  final String genderAllowed;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final double? monthlyRentMin;
  final double? monthlyRentMax;
  final double? securityDeposit;
  final bool isNegotiable;
  final int totalRooms;
  final int availableRooms;
  final String occupancyStatus;
  final bool isPublished;
  final List<String> amenities;
  final List<Media> media;
  final String coverImage;
  final bool isVerifiedOwner;
  final double? distanceKm;
  final double? averageRating;
  final int totalReviews;
  final bool isFeatured;
  final int viewCount;
  final int? ownerUserId;
  final String? ownerName;
  final String? ownerDisplayId;
  final String? ownerSubscriptionPlan;
  final String? ownerSubscriptionStatus;
  final DateTime createdAt;

  Property({
    required this.propertyId,
    required this.title,
    this.description = '',
    required this.propertyType,
    required this.genderAllowed,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.monthlyRentMin,
    this.monthlyRentMax,
    this.securityDeposit,
    this.isNegotiable = false,
    this.totalRooms = 0,
    this.availableRooms = 0,
    this.occupancyStatus = 'AVAILABLE',
    this.isPublished = false,
    this.amenities = const [],
    this.media = const [],
    this.coverImage = '',
    this.isVerifiedOwner = false,
    this.distanceKm,
    this.averageRating,
    this.totalReviews = 0,
    this.isFeatured = false,
    this.viewCount = 0,
    this.ownerUserId,
    this.ownerName,
    this.ownerDisplayId,
    this.ownerSubscriptionPlan,
    this.ownerSubscriptionStatus,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Extract cover image from media list
    String coverImage = json['coverImage'] ?? '';
    if (coverImage.isEmpty && json['media'] != null) {
      final mediaList = json['media'] as List;
      final primaryMedia = mediaList.firstWhere(
        (m) => m['isPrimary'] == true,
        orElse: () => mediaList.isNotEmpty ? mediaList.first : null,
      );
      if (primaryMedia != null) {
        coverImage = primaryMedia['url'] ?? '';
      }
    }

    return Property(
      propertyId: json['propertyId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['propertyType'] ?? '',
      genderAllowed: json['genderAllowed'] ?? '',
      addressLine: json['addressLine'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      monthlyRentMin: json['monthlyRentMin']?.toDouble(),
      monthlyRentMax: json['monthlyRentMax']?.toDouble(),
      securityDeposit: json['securityDeposit']?.toDouble(),
      isNegotiable: json['isNegotiable'] ?? false,
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      occupancyStatus: json['occupancyStatus'] ?? 'AVAILABLE',
      isPublished: json['isPublished'] ?? false,
      amenities: List<String>.from(json['amenities'] ?? []),
      media: (json['media'] as List?)
              ?.map((m) => Media.fromJson(m))
              .toList() ??
          [],
      coverImage: coverImage,
      isVerifiedOwner: json['isVerifiedOwner'] ?? false,
      distanceKm: json['distanceKm']?.toDouble(),
      averageRating: json['averageRating']?.toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      ownerUserId: json['ownerUserId'],
      ownerName: json['ownerName'],
      ownerDisplayId: json['ownerDisplayId'],
      ownerSubscriptionPlan: json['ownerSubscriptionPlan'],
      ownerSubscriptionStatus: json['ownerSubscriptionStatus'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Media {
  final int mediaId;
  final String mediaType;
  final String url;
  final String? thumbnailUrl;
  final int? durationSec;
  final bool isPrimary;
  final int sortOrder;
  final bool is360;

  Media({
    required this.mediaId,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.durationSec,
    this.isPrimary = false,
    this.sortOrder = 0,
    this.is360 = false,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      mediaId: json['mediaId'] ?? 0,
      mediaType: json['mediaType'] ?? 'IMAGE',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      durationSec: json['durationSec'],
      isPrimary: json['isPrimary'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      is360: json['is360'] ?? false,
    );
  }
}