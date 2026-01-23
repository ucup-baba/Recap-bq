import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/fund_request_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

/// Fund Request Service for SIQowwam
/// Handles fund request operations between users and super admin
class FundRequestService {
  static final FundRequestService _instance = FundRequestService._internal();
  factory FundRequestService() => _instance;
  FundRequestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection(AppConstants.fundRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Get all pending fund requests (for super admin)
  Stream<List<FundRequestModel>> getPendingRequestsStream() {
    return _requestsRef
        .where('status', isEqualTo: AppConstants.statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FundRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get all fund requests (for super admin)
  Stream<List<FundRequestModel>> getAllRequestsStream() {
    return _requestsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FundRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get fund requests by user
  Stream<List<FundRequestModel>> getUserRequestsStream(String userId) {
    return _requestsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FundRequestModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create new fund request
  Future<FundRequestModel> createRequest({
    required UserModel user,
    required double amount,
    required String description,
  }) async {
    final docRef = _requestsRef.doc();
    final request = FundRequestModel(
      id: docRef.id,
      userId: user.uid,
      userName: user.username,
      userEmail: user.email,
      amount: amount,
      description: description,
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
    );

    await docRef.set(request.toFirestore());
    return request;
  }

  /// Approve fund request (transfers balance from super admin to user)
  /// Throws exception if reviewer has insufficient balance
  Future<void> approveRequest({
    required String requestId,
    required String reviewerId,
    String? reviewNote,
  }) async {
    final requestDoc = await _requestsRef.doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Request not found');

    final request = FundRequestModel.fromFirestore(requestDoc);
    if (!request.isPending) throw Exception('Request already processed');

    // Check reviewer (Super Admin) balance
    final reviewerDoc = await _usersRef.doc(reviewerId).get();
    if (!reviewerDoc.exists) throw Exception('Reviewer not found');

    final reviewerData = reviewerDoc.data() as Map<String, dynamic>;
    final reviewerBalance = (reviewerData['balance'] ?? 0).toDouble();
    final reviewerName = reviewerData['username'] ?? 'Super Admin';

    if (reviewerBalance < request.amount) {
      final formatter = NumberFormat('#,###', 'id_ID');
      throw Exception(
        'Saldo tidak mencukupi. Saldo Anda: Rp ${formatter.format(reviewerBalance.toInt())}, Pengajuan: Rp ${formatter.format(request.amount.toInt())}',
      );
    }

    // Start batch write for atomic operation
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Update request status
    batch.update(_requestsRef.doc(requestId), {
      'status': AppConstants.statusApproved,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerId,
      'reviewNote': reviewNote,
    });

    // Deduct balance from Super Admin (reviewer)
    batch.update(_usersRef.doc(reviewerId), {
      'balance': FieldValue.increment(-request.amount),
    });

    // Add balance to user (requester)
    batch.update(_usersRef.doc(request.userId), {
      'balance': FieldValue.increment(request.amount),
    });

    // Get requester user data for role
    final requesterDoc = await _usersRef.doc(request.userId).get();
    String requesterRole = 'Member';
    if (requesterDoc.exists) {
      final requesterData = requesterDoc.data() as Map<String, dynamic>;
      requesterRole = requesterData['role'] ?? 'Member';
      // Capitalize role for display
      if (requesterRole == 'super_admin') {
        requesterRole = 'Super Admin';
      } else if (requesterRole.isNotEmpty) {
        requesterRole =
            requesterRole[0].toUpperCase() + requesterRole.substring(1);
      }
    }

    // Create expense transaction for Super Admin
    final expenseDocRef = _firestore
        .collection(AppConstants.transactionsCollection)
        .doc();
    batch.set(expenseDocRef, {
      'userId': reviewerId,
      'userName': reviewerName,
      'type': 'expense',
      'amount': request.amount,
      'category': 'Transfer Dana',
      'description':
          'Pengajuan dana ke ${request.userName}: ${request.description}',
      'subject': request.userName,
      'date': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'fundRequestId': requestId,
      'approvedUserName': request.userName,
      'approvedUserRole': requesterRole,
    });

    // Create income transaction for requester
    final incomeDocRef = _firestore
        .collection(AppConstants.transactionsCollection)
        .doc();
    batch.set(incomeDocRef, {
      'userId': request.userId,
      'userName': request.userName,
      'type': 'income',
      'amount': request.amount,
      'category': 'Penerimaan Dana',
      'description': 'Dana dari $reviewerName: ${request.description}',
      'subject': reviewerName,
      'date': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'fundRequestId': requestId,
    });

    await batch.commit();
  }

  /// Reject fund request
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerId,
    String? reviewNote,
  }) async {
    await _requestsRef.doc(requestId).update({
      'status': AppConstants.statusRejected,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerId,
      'reviewNote': reviewNote,
    });
  }

  /// Get request by ID
  Future<FundRequestModel?> getRequestById(String requestId) async {
    final doc = await _requestsRef.doc(requestId).get();
    if (doc.exists) {
      return FundRequestModel.fromFirestore(doc);
    }
    return null;
  }

  /// Get pending requests count
  Future<int> getPendingRequestsCount() async {
    final snapshot = await _requestsRef
        .where('status', isEqualTo: AppConstants.statusPending)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
