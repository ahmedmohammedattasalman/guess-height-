import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class UserProvider with ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userProfile != null;
  String? get error => _error;

  // Initialize user from shared preferences
  Future<void> initUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_profile');

      if (userJson != null) {
        _userProfile = UserProfile.fromJson(json.decode(userJson));
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load user profile: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserProfile userProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', json.encode(userProfile.toJson()));

      _userProfile = userProfile;
      _error = null;
    } catch (e) {
      _error = 'Failed to save user profile: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update specific user fields
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? profileImageUrl,
    double? knownHeight,
    List<String>? savedEstimationIds,
  }) async {
    if (_userProfile == null) {
      _error = 'No user profile to update';
      notifyListeners();
      return;
    }

    final updatedProfile = _userProfile!.copyWith(
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      knownHeight: knownHeight,
      savedEstimationIds: savedEstimationIds,
    );

    await saveUserProfile(updatedProfile);
  }

  // Log out user
  Future<void> logOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');

      _userProfile = null;
      _error = null;
    } catch (e) {
      _error = 'Failed to log out: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add estimation to saved list
  Future<void> saveEstimation(String estimationId) async {
    if (_userProfile == null) {
      _error = 'No user profile to update';
      notifyListeners();
      return;
    }

    if (!_userProfile!.savedEstimationIds.contains(estimationId)) {
      final updatedIds = List<String>.from(_userProfile!.savedEstimationIds)
        ..add(estimationId);

      await updateUserProfile(savedEstimationIds: updatedIds);
    }
  }

  // Remove estimation from saved list
  Future<void> removeEstimation(String estimationId) async {
    if (_userProfile == null) {
      _error = 'No user profile to update';
      notifyListeners();
      return;
    }

    if (_userProfile!.savedEstimationIds.contains(estimationId)) {
      final updatedIds = List<String>.from(_userProfile!.savedEstimationIds)
        ..remove(estimationId);

      await updateUserProfile(savedEstimationIds: updatedIds);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
