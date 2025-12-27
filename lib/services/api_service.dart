import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static String get baseUrl {
    // For physical device, use the machine's LAN IP.
    // Found via ipconfig: 192.168.1.33
    return 'http://192.168.1.33:3000/api';
  }

  static String? fixImageUrl(String? url) {
    if (url == null) return null;
    if (url.contains('localhost')) {
      return url.replaceFirst('localhost', '192.168.1.33');
    }
    return url;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      print('API Request: POST $baseUrl$endpoint');
      print('Data: ${jsonEncode(data)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10)); // Add 10s timeout

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('API Error (POST $endpoint): $e');
      rethrow;
    }
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      print('API Request: GET $baseUrl$endpoint');
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error (GET $endpoint): $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error (PUT $endpoint): $e');
      rethrow;
    }
  }

  static Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/upload'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          imageFile.path,
          contentType: MediaType(
            'image',
            'jpeg',
          ), // Adjust based on file type if needed
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr);
        return json['file']; // Returns the URL
      } else {
        print('Image upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getPosts() async {
    try {
      final response = await get('/posts');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  // --- Connection Methods ---

  static Future<dynamic> sendConnectionRequest(
    String requester,
    String recipient,
  ) async {
    return await post('/connections/request', {
      'requester': requester,
      'recipient': recipient,
    });
  }

  static Future<dynamic> respondConnectionRequest(
    String connectionId,
    String status,
  ) async {
    return await post('/connections/respond', {
      'connectionId': connectionId,
      'status': status,
    });
  }

  static Future<List<dynamic>> getMyConnections(String uid) async {
    try {
      final response = await get('/connections/my-connections/$uid');
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getPendingRequests(String uid) async {
    try {
      final response = await get('/connections/requests/$uid');
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> checkConnectionStatus(
    String uid,
    String targetUid,
  ) async {
    try {
      final response = await get('/connections/status/$uid/$targetUid');
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'none'};
    }
  }

  // --- Message Methods ---

  static Future<dynamic> sendMessage(
    String sender,
    String recipient,
    String content,
  ) async {
    return await post('/messages/send', {
      'sender': sender,
      'recipient': recipient,
      'content': content,
    });
  }

  static Future<List<dynamic>> getMessages(String uid, String targetUid) async {
    try {
      final response = await get('/messages/$uid/$targetUid');
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // --- Upload Methods ---
  static Future<String?> uploadContentImage(File file) async {
    return await uploadFile(file);
  }

  static Future<String?> uploadDocument(File file) async {
    return await uploadFile(file);
  }

  static Future<String?> uploadFile(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl']; // Backend returns 'imageUrl' key currently
      } else {
        print('Upload Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // --- Post Methods ---
  static Future<dynamic> createPost(Map<String, dynamic> data) async {
    return await post('/posts', data);
  }

  static Future<void> deletePost(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/posts/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // --- Event Methods ---
  static Future<List<dynamic>> getEvents() async {
    try {
      final response = await get('/events');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  static Future<dynamic> createEvent(Map<String, dynamic> data) async {
    return await post('/events', data);
  }

  static Future<void> deleteEvent(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/events/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // --- Job Methods ---
  static Future<List<dynamic>> getJobs() async {
    try {
      final response = await get('/jobs');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching jobs: $e');
      return [];
    }
  }

  static Future<dynamic> createJob(Map<String, dynamic> data) async {
    return await post('/jobs', data);
  }

  static Future<void> deleteJob(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/jobs/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete job');
      }
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }

  // --- Admin User Management ---
  static Future<List<dynamic>> getAllUsers({String? department}) async {
    try {
      String endpoint = '/user/all';
      if (department != null && department.isNotEmpty) {
        endpoint += '?department=$department';
      }
      final response = await get(endpoint);
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteUser(String uid) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/user/$uid'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  static Future<void> createUser(Map<String, dynamic> data) async {
    // Admin creating user. Reusing auth register for now.
    // Ensure data has password.
    await post('/auth/register', data);
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await put('/user/$uid', data);
  }

  static Future<void> deleteProfileImage(String uid) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/user/$uid/image'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete profile image');
      }
    } catch (e) {
      print('Error deleting profile image: $e');
      rethrow;
    }
  }

  // --- Donation Methods ---
  static Future<List<dynamic>> getCampaigns() async {
    try {
      final response = await get('/donations/campaigns');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching campaigns: $e');
      return [];
    }
  }

  static Future<void> donate(Map<String, dynamic> data) async {
    await post('/donations/donate', data);
  }

  static Future<List<dynamic>> getMyDonations(String uid) async {
    try {
      final response = await get('/donations/my-donations/$uid');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching donations: $e');
      return [];
    }
  }
}
