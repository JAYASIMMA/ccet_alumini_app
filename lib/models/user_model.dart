class UserModel {
  final String uid;
  final String email;
  final String? profileImageUrl;
  final String firstName;
  final String lastName;
  final String department;
  final String rollNumber;
  final String? completedYear;
  final DateTime? dateOfBirth;
  final String phoneNumber;
  final String countryCode;

  // Getters for compatibility
  String get displayName => '$firstName $lastName';
  String? get photoURL => profileImageUrl;

  // Residential Address
  final String resAddressLine1;
  final String? resAddressLine2;
  final String resDistrict;
  final String resPincode;

  // Placement Info
  final bool isPlaced;
  final String? placedIn; // On Campus/Off Campus
  final String? designation;
  final String? companyName;

  // Permanent Address
  final bool isPermanentSameAsResidential;
  final String? permAddressLine1;
  final String? permAddressLine2;
  final String? permDistrict;
  final String? permPincode;

  final String? linkedInId;
  final bool isAdmin;
  final bool isAlumni;
  final String role; // 'alumni', 'student', 'admin'
  final String? currentYear;
  final String? semester;

  UserModel({
    required this.uid,
    required this.email,
    this.profileImageUrl,
    required this.firstName,
    required this.lastName,
    required this.department,
    required this.rollNumber,
    this.completedYear,
    this.dateOfBirth,
    required this.phoneNumber,
    this.countryCode = '+91',
    required this.resAddressLine1,
    this.resAddressLine2,
    required this.resDistrict,
    required this.resPincode,
    this.isPlaced = false,
    this.placedIn,
    this.designation,
    this.companyName,
    this.isPermanentSameAsResidential = false,
    this.permAddressLine1,
    this.permAddressLine2,
    this.permDistrict,
    this.permPincode,
    this.linkedInId,
    this.isAdmin = false,
    this.isAlumni = false,
    this.role = 'alumni',
    this.currentYear,
    this.semester,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'firstName': firstName,
      'lastName': lastName,
      'department': department,
      'rollNumber': rollNumber,
      'completedYear': completedYear,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'resAddressLine1': resAddressLine1,
      'resAddressLine2': resAddressLine2,
      'resDistrict': resDistrict,
      'resPincode': resPincode,
      'isPlaced': isPlaced,
      'placedIn': placedIn,
      'designation': designation,
      'companyName': companyName,
      'isPermanentSameAsResidential': isPermanentSameAsResidential,
      'permAddressLine1': permAddressLine1,
      'permAddressLine2': permAddressLine2,
      'permDistrict': permDistrict,
      'permPincode': permPincode,
      'linkedInId': linkedInId,
      'isAdmin': isAdmin,
      'isAlumni': isAlumni,
      'role': role,
      'currentYear': currentYear,
      'semester': semester,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      department: map['department'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      completedYear: map['completedYear'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      phoneNumber: map['phoneNumber'] ?? '',
      countryCode: map['countryCode'] ?? '+91',
      resAddressLine1: map['resAddressLine1'] ?? '',
      resAddressLine2: map['resAddressLine2'],
      resDistrict: map['resDistrict'] ?? '',
      resPincode: map['resPincode'] ?? '',
      isPlaced: map['isPlaced'] ?? false,
      placedIn: map['placedIn'],
      designation: map['designation'],
      companyName: map['companyName'],
      isPermanentSameAsResidential:
          map['isPermanentSameAsResidential'] ?? false,
      permAddressLine1: map['permAddressLine1'],
      permAddressLine2: map['permAddressLine2'],
      permDistrict: map['permDistrict'],
      permPincode: map['permPincode'],
      linkedInId: map['linkedInId'],
      isAdmin: map['isAdmin'] ?? false,
      isAlumni: map['isAlumni'] ?? false,
      role: map['role'] ?? 'alumni',
      currentYear: map['currentYear'],
      semester: map['semester'],
    );
  }
}
