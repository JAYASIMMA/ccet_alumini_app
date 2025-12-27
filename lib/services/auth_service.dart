import 'dart:async';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current user cache
  static UserModel? _currentUser;
  static const String _userUidKey = 'user_uid';

  // Stream of auth state changes
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  UserModel? get currentUser => _currentUser;

  /// Try to auto-login from SharedPreferences
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_userUidKey)) return false;

    final uid = prefs.getString(_userUidKey);
    if (uid == null) return false;

    final user = await getUserDetails(uid);
    if (user != null) {
      _currentUser = user;
      _authStateController.add(user);
      return true;
    }
    return false;
  }

  // Sign in with Google (Not implemented in backend yet, keeping mock or TODO)
  Future<bool> signInWithGoogle() async {
    // TODO: Implement Google Auth with backend
    return false;
  }

  // Sign up with username, email and password
  Future<bool> signUp(String username, String email, String password) async {
    try {
      _tempPassword = password;

      _currentUser = UserModel(
        uid: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        firstName: '',
        lastName: '',
        department: '',
        rollNumber: '',
        phoneNumber: '',
        resAddressLine1: '',
        resDistrict: '',
        resPincode: '',
      );
      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response['success'] == true) {
        _currentUser = UserModel.fromMap(response['user']);
        _authStateController.add(_currentUser);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userUidKey, _currentUser!.uid);

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> saveUserDetails(UserModel userModel) async {
    try {
      final data = userModel.toMap();

      if (_tempPassword != null) {
        data['password'] = _tempPassword;
        final response = await ApiService.post('/auth/register', data);
        _tempPassword = null; // Clear it

        // Update local user with backend response (which has the real UID)
        if (response['success'] == true && response['user'] != null) {
          userModel = UserModel.fromMap(response['user']);
        }
      } else {
        // Update existing
        await ApiService.put('/user/${userModel.uid}', data);
      }

      _currentUser = userModel;
      _authStateController.add(_currentUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userUidKey, userModel.uid);
    } catch (e) {
      print('Save details error: $e');
      rethrow;
    }
  }

  String? _tempPassword;

  Future<bool> isUserRegistered(String uid) async {
    try {
      // if (uid.startsWith('temp_')) return false; // Removed to allow backend check

      final exists = await ApiService.get('/auth/check/$uid');
      return exists == true;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getUserDetails(String uid) async {
    try {
      final data = await ApiService.get('/user/$uid');
      return UserModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  Future<void> fetchUserDetails() async {
    if (_currentUser == null) return;
    final user = await getUserDetails(_currentUser!.uid);
    if (user != null) {
      _currentUser = user;
      _authStateController.add(user);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userUidKey);
  }
}
