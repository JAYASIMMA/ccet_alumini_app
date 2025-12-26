import 'dart:async';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  // Current user cache
  static UserModel? _currentUser;

  // Stream of auth state changes (simple simplified version)
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  UserModel? get currentUser => _currentUser;

  // Sign in with Google (Not implemented in backend yet, keeping mock or TODO)
  Future<bool> signInWithGoogle() async {
    // TODO: Implement Google Auth with backend
    return false;
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      // In this flow, we just validated inputs locally or check if user exists.
      // But creating a user requires full profile.
      // We will store the password temporarily to use it when saving full profile.
      _tempPassword = password;

      _currentUser = UserModel(
        uid: 'temp_${DateTime.now().millisecondsSinceEpoch}',
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

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        _currentUser = UserModel.fromMap(response['user']);
        _authStateController.add(_currentUser);
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
        await ApiService.post('/auth/register', data);
        _tempPassword = null; // Clear it
      } else {
        // Update existing
        await ApiService.put('/user/${userModel.uid}', data);
      }

      _currentUser = userModel;
      _authStateController.add(_currentUser);
    } catch (e) {
      print('Save details error: $e');
      rethrow;
    }
  }

  String? _tempPassword;

  Future<bool> isUserRegistered(String uid) async {
    try {
      if (uid.startsWith('temp_')) return false;
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

  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
