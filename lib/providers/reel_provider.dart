// lib/providers/reel_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';

class ReelProvider extends ChangeNotifier {
  final ReelService _reelService = ReelService();

  List<Reel> _reels = [];
  List<Reel> _myReels = [];
  List<ReelComment> _comments = [];
  bool _isLoading = false;
  bool _isUploading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  // Getters
  List<Reel> get reels => _reels;
  List<Reel> get myReels => _myReels;
  List<ReelComment> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // ============== LOAD REELS FEED ==============
  Future<void> loadReelsFeed({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _reels = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await _reelService.getReelsFeed(
        page: _currentPage,
        size: 10,
      );

      if (response.success && response.data != null) {
        final feed = response.data!;
        _reels.addAll(feed.content);
        _hasMore = !feed.last;
        _currentPage++;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // ============== LOAD MY REELS (OWNER) ==============
  Future<bool> loadMyReels() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _reelService.getMyReels();
      if (response.success && response.data != null) {
        _myReels = response.data!;
        _setLoading(false);
        return true;
      } else {
        _error = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== UPLOAD REEL ==============
  Future<bool> uploadReel({
    required int propertyId,
    required String caption,
    required File videoFile,
  }) async {
    _setUploading(true);
    _clearError();

    try {
      final response = await _reelService.uploadReel(
        propertyId: propertyId,
        caption: caption,
        videoFile: videoFile,
      );

      _setUploading(false);

      if (response.success && response.data != null) {
        _myReels.insert(0, response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setUploading(false);
      return false;
    }
  }

  // ============== DELETE REEL ==============
  Future<bool> deleteReel(int reelId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _reelService.deleteReel(reelId);
      _setLoading(false);

      if (response.success) {
        _myReels.removeWhere((r) => r.reelId == reelId);
        _reels.removeWhere((r) => r.reelId == reelId);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== LIKE REEL ==============
  Future<bool> likeReel(int reelId) async {
    try {
      final response = await _reelService.likeReel(reelId);
      if (response.success) {
        _updateReelLike(reelId, true);
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============== UNLIKE REEL ==============
  Future<bool> unlikeReel(int reelId) async {
    try {
      final response = await _reelService.unlikeReel(reelId);
      if (response.success) {
        _updateReelLike(reelId, false);
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============== ADD COMMENT ==============
  Future<bool> addComment({
    required int reelId,
    required String content,
  }) async {
    try {
      final response = await _reelService.addComment(
        reelId: reelId,
        content: content,
      );

      if (response.success && response.data != null) {
        _comments.insert(0, response.data!);
        _updateReelCommentCount(reelId, 1);
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============== GET COMMENTS ==============
  Future<bool> getComments(int reelId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _reelService.getComments(reelId);
      _setLoading(false);

      if (response.success && response.data != null) {
        _comments = response.data!;
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============== REGISTER VIEW ==============
  Future<void> registerView(int reelId) async {
    try {
      await _reelService.registerView(reelId);
    } catch (e) {
      // Silent fail for view tracking
    }
  }

  // ============== REGISTER SHARE ==============
  Future<void> registerShare(int reelId) async {
    try {
      await _reelService.registerShare(reelId);
    } catch (e) {
      // Silent fail for share tracking
    }
  }

  // ============== HELPERS ==============
  void _updateReelLike(int reelId, bool liked) {
    for (var reel in _reels) {
      if (reel.reelId == reelId) {
        final updatedReel = Reel(
          reelId: reel.reelId,
          propertyId: reel.propertyId,
          propertyTitle: reel.propertyTitle,
          propertyCity: reel.propertyCity,
          ownerUserId: reel.ownerUserId,
          ownerName: reel.ownerName,
          ownerDisplayId: reel.ownerDisplayId,
          ownerProfilePic: reel.ownerProfilePic,
          isVerifiedOwner: reel.isVerifiedOwner,
          videoUrl: reel.videoUrl,
          caption: reel.caption,
          viewCount: reel.viewCount,
          likeCount: liked ? reel.likeCount + 1 : reel.likeCount - 1,
          commentCount: reel.commentCount,
          shareCount: reel.shareCount,
          isLikedByMe: liked,
          createdAt: reel.createdAt,
        );
        final index = _reels.indexOf(reel);
        _reels[index] = updatedReel;
        break;
      }
    }
    notifyListeners();
  }

  void _updateReelCommentCount(int reelId, int delta) {
    for (var reel in _reels) {
      if (reel.reelId == reelId) {
        final updatedReel = Reel(
          reelId: reel.reelId,
          propertyId: reel.propertyId,
          propertyTitle: reel.propertyTitle,
          propertyCity: reel.propertyCity,
          ownerUserId: reel.ownerUserId,
          ownerName: reel.ownerName,
          ownerDisplayId: reel.ownerDisplayId,
          ownerProfilePic: reel.ownerProfilePic,
          isVerifiedOwner: reel.isVerifiedOwner,
          videoUrl: reel.videoUrl,
          caption: reel.caption,
          viewCount: reel.viewCount,
          likeCount: reel.likeCount,
          commentCount: reel.commentCount + delta,
          shareCount: reel.shareCount,
          isLikedByMe: reel.isLikedByMe,
          createdAt: reel.createdAt,
        );
        final index = _reels.indexOf(reel);
        _reels[index] = updatedReel;
        break;
      }
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearReels() {
    _reels = [];
    _myReels = [];
    _comments = [];
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
  }
}