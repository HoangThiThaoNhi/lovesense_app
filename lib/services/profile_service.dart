import 'dart:io';
import 'dart:math'; // Added for Random
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection Reference
  CollectionReference get _users => _firestore.collection('users');

  /// Update mutable profile fields
  /// Validates inputs before writing to Firestore.
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phoneNumber,
    Gender? gender,
    String? photoUrl,
    String? coverUrl,
    bool? showBirthday,
    bool? showGender,
    bool? showStatus,
    bool? showPrivateInfo,
    bool? shareMood,
    bool? shareDiary,
    bool? shareQuiz,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final Map<String, dynamic> updates = {};

    if (name != null) {
      if (name.length > 50) throw Exception("Name too long (max 50 chars)");
      updates['name'] = name;
    }

    if (bio != null) {
      if (bio.length > 300) throw Exception("Bio too long (max 300 chars)");
      updates['bio'] = bio;
    }

    if (phoneNumber != null) {
      // E.164 regex (simple version)
      final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
      if (!phoneRegex.hasMatch(phoneNumber)) {
        throw Exception("Invalid phone format");
      }
      updates['phoneNumber'] = phoneNumber;
    }

    if (gender != null) {
      updates['gender'] = gender.name;
    }

    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (coverUrl != null) updates['coverUrl'] = coverUrl;

    // Privacy updates
    if (showBirthday != null) updates['showBirthday'] = showBirthday;
    if (showGender != null) updates['showGender'] = showGender;
    if (showStatus != null) updates['showStatus'] = showStatus;
    if (showPrivateInfo != null) updates['showPrivateInfo'] = showPrivateInfo;

    // Partner Sharing Settings
    if (shareMood != null) updates['shareMood'] = shareMood;
    if (shareDiary != null) updates['shareDiary'] = shareDiary;
    if (shareQuiz != null) updates['shareQuiz'] = shareQuiz;

    if (updates.isEmpty) return;

    await _users.doc(uid).update(updates);
  }

  /// Generate Username
  /// Format: slug(name) + random 4 digits
  String generateUsername(String fullName) {
    if (fullName.isEmpty) {
      return "user_${DateTime.now().millisecondsSinceEpoch}";
    }

    // Simple slugify: remove accents, lowercase, remove non-alphanumeric
    String slug = removeDiacritics(
      fullName,
    ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final random = Random();
    final suffix = (1000 + random.nextInt(9000)).toString(); // 4 digits

    return "${slug}_$suffix";
  }

  String removeDiacritics(String str) {
    const withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  /// Update Username
  /// Logic: Check uniqueness, enforce regex, limit change frequency (1 per 30 days)
  Future<void> updateUsername(String username) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    // 1. Validation
    if (username.length < 3 || username.length > 30) {
      throw Exception("Username phải từ 3-30 ký tự");
    }

    final validRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validRegex.hasMatch(username)) {
      throw Exception("Username chỉ được chứa chữ cái, số và dấu gạch dưới");
    }

    // 2. Check Frequency (from DB)
    final userDoc = await _users.doc(uid).get();
    final userData =
        userDoc.data() as Map<String, dynamic>?; // raw data to check field

    if (userData != null && userData['lastUsernameChangeAt'] != null) {
      final lastChange = DateTime.parse(userData['lastUsernameChangeAt']);
      final difference = DateTime.now().difference(lastChange).inDays;
      if (difference < 30) {
        throw Exception(
          "Bạn chỉ có thể đổi username 30 ngày một lần. Hãy thử lại sau ${30 - difference} ngày.",
        );
      }
    }

    // 3. Check Uniqueness
    final query = await _users.where('username', isEqualTo: username).get();
    if (query.docs.isNotEmpty) {
      if (query.docs.first.id != uid) {
        throw Exception("Username đã được sử dụng");
      }
    }

    await _users.doc(uid).update({
      'username': username,
      'lastUsernameChangeAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update Date of Birth
  /// Logic: Only allows update if not already set (or via specific flow, simplified here)
  Future<void> updateDOB(DateTime dob) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    // Age Check (18+)
    final now = DateTime.now();
    final age =
        now.year -
        dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);

    if (age < 18) throw Exception("User must be at least 18 years old");

    await _users.doc(uid).update({'dateOfBirth': dob.toIso8601String()});
  }

  // Code to handle requests
  CollectionReference get _requests => _firestore.collection('requests');

  /// Send Couple Request
  /// Enhanced: Checks for mutual invite (auto-match)
  Future<void> sendCoupleRequest(String targetUid, String message) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    // 1. Check self status (redundant but safe)
    final userDoc = await _users.doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    if (userData?['partnerId'] != null) {
      throw Exception("Bạn đã có người yêu rồi!");
    }

    // 2. Check if we already sent a request to this user
    final sentQuery =
        await _requests
            .where('fromUid', isEqualTo: uid)
            .where('toUid', isEqualTo: targetUid)
            .where('status', isEqualTo: 'pending')
            .get();
    if (sentQuery.docs.isNotEmpty) {
      throw Exception("Bạn đã gửi lời mời cho người này rồi");
    }

    // 3. Check for MUTUAL INVITE (Did target already invite me?)
    final mutualQuery =
        await _requests
            .where('fromUid', isEqualTo: targetUid)
            .where('toUid', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();

    if (mutualQuery.docs.isNotEmpty) {
      // SCENARIO C: Mutual Invite -> Auto Match
      final incomingRequestDoc = mutualQuery.docs.first;
      final incomingRequest = RequestModel.fromJson(
        incomingRequestDoc.data() as Map<String, dynamic>,
      );

      // Accept the *incoming* request instead of creating a new one
      await acceptRequest(incomingRequest);
      return;
    }

    // 4. Standard Flow: Create new request
    final targetDoc = await _users.doc(targetUid).get();
    if (!targetDoc.exists) throw Exception("Người dùng không tồn tại");
    final targetData = targetDoc.data() as Map<String, dynamic>?;

    if (targetData?['partnerId'] != null) {
      throw Exception("Người này đã có người yêu rồi!");
    }

    final id = _requests.doc().id;
    final request = RequestModel(
      id: id,
      fromUid: uid,
      toUid: targetUid,
      type: RequestType.coupleInvite,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      message: message,
    );

    await _requests.doc(id).set(request.toJson());
  }

  /// Get My Sent Requests (Outbound)
  Stream<List<RequestModel>> getSentRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _requests
        .where('fromUid', isEqualTo: uid)
        .where(
          'type',
          isEqualTo: 'coupleInvite',
        ) // Fixed: matches RequestType.coupleInvite.name
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (d) =>
                        RequestModel.fromJson(d.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  /// Cancel Sent Request
  Future<void> cancelSentRequest(String requestId) async {
    // We can delete or set to 'canceled'
    await _requests.doc(requestId).delete();
  }

  /// Send Creator Application
  Future<void> sendCreatorApplication(String message) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    // Check existing pending
    final existing =
        await _requests
            .where('fromUid', isEqualTo: uid)
            .where('type', isEqualTo: 'creatorApplication')
            .where('status', isEqualTo: 'pending')
            .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Bạn đã có đơn đăng ký đang chờ duyệt");
    }

    final id = _requests.doc().id;
    final request = RequestModel(
      id: id,
      fromUid: uid,
      toUid: 'admin',
      type: RequestType.creatorApplication,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      message: message,
    );

    await _requests.doc(id).set(request.toJson());
  }

  /// Get Pending Requests (Incoming)
  Stream<List<RequestModel>> getPendingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _requests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests =
              snapshot.docs
                  .map(
                    (doc) => RequestModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList();

          // Fetch sender info for each request
          for (var req in requests) {
            if (req.type == RequestType.coupleInvite) {
              final senderDoc = await _users.doc(req.fromUid).get();
              final senderData = senderDoc.data() as Map<String, dynamic>?;
              // We modify the model in memory to include sender info
              // (Requires mutable fields or copyWith, using copyWith here)
              // Note: Dart pass-by-value for structs, but here we replace the item in list
              final index = requests.indexOf(req);
              requests[index] = req.copyWith(
                senderName: senderData?['name'],
                senderAvatar: senderData?['photoUrl'],
                senderUsername: senderData?['username'],
              );
            }
          }
          return requests;
        });
  }

  /// Get My Sent Application (Creator)
  Stream<RequestModel?> getMyCreatorApplication() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _requests
        .where('fromUid', isEqualTo: uid)
        .where('type', isEqualTo: 'creatorApplication')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return RequestModel.fromJson(
            snapshot.docs.first.data() as Map<String, dynamic>,
          );
        });
  }

  /// Accept Request
  Future<void> acceptRequest(RequestModel request) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    if (request.type == RequestType.coupleInvite) {
      // Transaction to update both users and request status
      await _firestore.runTransaction((transaction) async {
        final requestRef = _requests.doc(request.id);
        final myRef = _users.doc(uid);
        final partnerRef = _users.doc(request.fromUid);

        transaction.update(requestRef, {'status': 'accepted'});

        final String startDate = DateTime.now().toIso8601String();

        transaction.update(myRef, {
          'partnerId': request.fromUid,
          'role': 'couple',
          'coupleStartDate': startDate,
        });

        transaction.update(partnerRef, {
          'partnerId': uid,
          'role': 'couple',
          'coupleStartDate': startDate,
        });
      });
    }
    // Creator application acceptance is done by Admin (not here)
  }

  /// Decline Request
  Future<void> declineRequest(String requestId) async {
    await _requests.doc(requestId).update({'status': 'rejected'});
  }

  /// Unpair
  Future<void> unpairCouple() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final userDoc = await _users.doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final partnerId = userData?['partnerId'];

    if (partnerId != null) {
      await _firestore.runTransaction((transaction) async {
        final myRef = _users.doc(uid);
        final partnerRef = _users.doc(partnerId);

        transaction.update(myRef, {
          'partnerId': FieldValue.delete(),
          'role': 'single', // Revert to single
          'coupleStartDate': FieldValue.delete(),
        });

        transaction.update(partnerRef, {
          'partnerId': FieldValue.delete(),
          'role': 'single',
          'coupleStartDate': FieldValue.delete(),
        });
      });
    }
  }

  // NOTE: Level and Points should NOT be updated via Client API directly.
  // They should be updated via Cloud Functions or trusted server-side logic in response to events.

  /// Upload Avatar
  /// Rules: JPG/PNG/WebP, <= 5MB.
  Future<String> uploadAvatar({
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    return _uploadImage(
      file: file,
      bytes: bytes,
      fileName: fileName,
      maxSizeMB: 5,
      folder: 'avatars',
    );
  }

  /// Upload Cover
  /// Rules: <= 8MB.
  Future<String> uploadCover({
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    return _uploadImage(
      file: file,
      bytes: bytes,
      fileName: fileName,
      maxSizeMB: 8,
      folder: 'covers',
    );
  }

  Future<String> _uploadImage({
    File? file,
    Uint8List? bytes,
    required String fileName,
    required int maxSizeMB,
    required String folder,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Người dùng chưa đăng nhập");

    if (file == null && bytes == null) {
      throw Exception("Không có dữ liệu ảnh");
    }

    // 1. Validation (File Type & Size)
    int sizeInBytes = 0;
    if (file != null) {
      sizeInBytes = await file.length();
    } else if (bytes != null) {
      sizeInBytes = bytes.lengthInBytes;
    }

    if (sizeInBytes > maxSizeMB * 1024 * 1024) {
      throw Exception("Dung lượng ảnh quá lớn (tối đa ${maxSizeMB}MB)");
    }

    try {
      // 2. Create Reference
      // Path: users/{uid}/{folder}/{timestamp}_{fileName}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$uid/$folder/${timestamp}_$fileName',
      );

      // 3. Upload Task
      UploadTask uploadTask;
      if (bytes != null) {
        // Web or Bytes
        final metadata = SettableMetadata(contentType: 'image/jpeg'); // Generic
        uploadTask = storageRef.putData(bytes, metadata);
      } else if (file != null) {
        // Mobile File
        uploadTask = storageRef.putFile(file);
      } else {
        throw Exception("Lỗi không xác định: File và Bytes đều null");
      }

      // 4. Wait for completion and get URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print("Upload Success: $downloadUrl");

      // 5. Update Firestore with new URL
      if (folder == 'avatars') await updateProfile(photoUrl: downloadUrl);
      if (folder == 'covers') await updateProfile(coverUrl: downloadUrl);

      return downloadUrl;
    } catch (e) {
      print("Upload Error: $e");
      throw Exception("Lỗi tải ảnh lên: $e");
    }
  }

  /// Search Users for Couple Invite
  /// Query can be Username (prefix), Phone (exact), or Email (exact)
  Future<List<UserModel>> searchUsers(String query) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    query = query.trim();
    if (query.isEmpty) return [];

    List<UserModel> results = [];

    // 1. Try search by Phone (Exact)
    final phoneQuery =
        await _users.where('phoneNumber', isEqualTo: query).get();
    if (phoneQuery.docs.isNotEmpty) {
      results.addAll(
        phoneQuery.docs
            .map((d) => UserModel.fromDocument(d))
            .where((u) => u.uid != uid && u.partnerId == null),
      );
    }

    // 2. Try search by Username (Exact or Prefix?)
    // Firestore lacks native full-text search. We'll do simple exact for now or startAt if needed.
    // Let's do exact match for simplicity and performance first, or startAt for "starts with"
    final usernameQuery =
        await _users
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThan: '${query}z')
            .limit(5)
            .get();

    if (usernameQuery.docs.isNotEmpty) {
      final usernameResults = usernameQuery.docs
          .map((d) => UserModel.fromDocument(d))
          .where(
            (u) =>
                u.uid != uid &&
                u.partnerId == null &&
                !results.any((exist) => exist.uid == u.uid),
          ); // Avoid dupes
      results.addAll(usernameResults);
    }

    // 3. Try Email (Exact)
    final emailQuery = await _users.where('email', isEqualTo: query).get();
    if (emailQuery.docs.isNotEmpty) {
      final emailResults = emailQuery.docs
          .map((d) => UserModel.fromDocument(d))
          .where(
            (u) =>
                u.uid != uid &&
                u.partnerId == null &&
                !results.any((exist) => exist.uid == u.uid),
          );
      results.addAll(emailResults);
    }

    return results;
  }

  /// Get User by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  // --- Couple Code ---
  Future<String> generateCoupleCode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not found");

    // Generate 6-char random code (Uppercased)
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 1, 0
    final rnd = Random();
    String code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    await _users.doc(uid).update({'coupleCode': code});
    return code;
  }

  Future<void> sendCoupleRequestByCode(String code) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Chưa đăng nhập");

    // Find user by code
    final query =
        await _users.where('coupleCode', isEqualTo: code).limit(1).get();

    if (query.docs.isEmpty) {
      throw Exception("Mã không tồn tại");
    }

    final targetUser = UserModel.fromDocument(query.docs.first);
    // sendCoupleRequest requires 2 arguments: targetUid and message
    await sendCoupleRequest(
      targetUser.uid,
      "Chào bạn, mình muốn kết nối đôi với bạn qua mã code!",
    );
  }

  // --- Policy ---
  Future<String?> getPolicyContent(String id) async {
    try {
      final doc =
          await _firestore
              .collection('system')
              .doc('policies')
              .collection('items')
              .doc(id)
              .get();

      if (doc.exists) {
        return doc.data()?['content'] as String?;
      }
      return null;
    } catch (e) {
      print("Error fetching policy: $e");
      return null;
    }
  }
}
