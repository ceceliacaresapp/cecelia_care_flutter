// lib/services/firestore_service_financial.dart
//
// Financial-domain methods on FirestoreService. This file is a `part of`
// the firestore_service library, which means it shares the same private
// scope as firestore_service.dart — so the extensions below can read the
// library-private `FirestoreService._budgetEntriesRef`, `FirestoreService._incomeEntriesRef`, etc. without
// any visibility plumbing.
//
// The point of this split is purely to keep firestore_service.dart from
// growing past 2,500 lines. Behavior is unchanged.

part of 'firestore_service.dart';

extension FinancialFirestoreOps on FirestoreService {
  // ── Budget Entries ─────────────────────────────────────────

  Future<void> addBudgetEntry(BudgetEntry entry) async {
    await FirestoreService._budgetEntriesRef.add(entry);
  }

  Future<void> updateBudgetEntry(String entryId, BudgetEntry entry) async {
    await FirestoreService._budgetEntriesRef.doc(entryId).update(entry.toFirestore());
  }

  Future<void> deleteBudgetEntry(String entryId) async {
    await FirestoreService._budgetEntriesRef.doc(entryId).delete();
  }

  Stream<List<BudgetEntry>> getBudgetStreamForMonth({
    required String userId,
    String? careRecipientId,
    required DateTime month,
  }) {
    final DateTime startDate = DateTime(month.year, month.month, 1);
    final DateTime endDate =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    Query<BudgetEntry> query = FirestoreService._budgetEntriesRef
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('userId', isEqualTo: userId);

    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }

    return query
        .orderBy('date', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      debugPrint(
          'FirestoreService.getBudgetStreamForMonth error: $error');
      return <BudgetEntry>[];
    });
  }

  /// Streams every BudgetEntry for the given user/year. Used by the
  /// insurance OOP tracker and tax-deduction summary which span months.
  Stream<List<BudgetEntry>> getBudgetStreamForYear({
    required String userId,
    String? careRecipientId,
    required int year,
  }) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    Query<BudgetEntry> query = FirestoreService._budgetEntriesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    return query
        .limit(2000)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error) {
      debugPrint('FirestoreService.getBudgetStreamForYear error: $error');
      return <BudgetEntry>[];
    });
  }

  // ── Income Entries ─────────────────────────────────────────

  Future<void> addIncomeEntry(IncomeEntry entry) async {
    await FirestoreService._incomeEntriesRef.add(entry);
  }

  Future<void> updateIncomeEntry(String entryId, IncomeEntry entry) async {
    await FirestoreService._incomeEntriesRef.doc(entryId).update(entry.toFirestore());
  }

  Future<void> deleteIncomeEntry(String entryId) async {
    await FirestoreService._incomeEntriesRef.doc(entryId).delete();
  }

  Stream<List<IncomeEntry>> getIncomeStreamForMonth({
    required String userId,
    String? careRecipientId,
    required DateTime month,
  }) {
    final DateTime startDate = DateTime(month.year, month.month, 1);
    final DateTime endDate =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    Query<IncomeEntry> query = FirestoreService._incomeEntriesRef
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('userId', isEqualTo: userId);

    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }

    return query
        .orderBy('date', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      debugPrint(
          'FirestoreService.getIncomeStreamForMonth error: $error');
      return <IncomeEntry>[];
    });
  }

  // ── Assets ────────────────────────────────────────────────

  Future<void> addAsset(FinancialAsset asset) async {
    await FirestoreService._financialAssetsRef.add(asset);
  }

  Future<void> updateAsset(String assetId, FinancialAsset asset) async {
    await FirestoreService._financialAssetsRef.doc(assetId).update(asset.toFirestore());
  }

  Future<void> deleteAsset(String assetId) async {
    await FirestoreService._financialAssetsRef.doc(assetId).delete();
  }

  Stream<List<FinancialAsset>> getAssetsStream({
    required String userId,
    String? careRecipientId,
  }) {
    Query<FinancialAsset> query =
        FirestoreService._financialAssetsRef.where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    return query
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((e) {
      debugPrint('FirestoreService.getAssetsStream error: $e');
      return <FinancialAsset>[];
    });
  }

  // ── Liabilities ───────────────────────────────────────────

  Future<void> addLiability(FinancialLiability liability) async {
    await FirestoreService._financialLiabilitiesRef.add(liability);
  }

  Future<void> updateLiability(
      String liabilityId, FinancialLiability liability) async {
    await FirestoreService._financialLiabilitiesRef
        .doc(liabilityId)
        .update(liability.toFirestore());
  }

  Future<void> deleteLiability(String liabilityId) async {
    await FirestoreService._financialLiabilitiesRef.doc(liabilityId).delete();
  }

  Stream<List<FinancialLiability>> getLiabilitiesStream({
    required String userId,
    String? careRecipientId,
  }) {
    Query<FinancialLiability> query =
        FirestoreService._financialLiabilitiesRef.where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    return query
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((e) {
      debugPrint('FirestoreService.getLiabilitiesStream error: $e');
      return <FinancialLiability>[];
    });
  }

  // ── Category Budgets (Monthly) ────────────────────────────

  Future<void> setCategoryBudgets({
    required String elderId,
    required Map<String, double> budgets,
    required DateTime month,
  }) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    final String yearMonth = DateFormat('yyyy-MM').format(month);
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection(FirestoreService._categoryBudgetsSubcollection)
        .doc(yearMonth)
        .set({'budgets': budgets}, SetOptions(merge: true));
  }

  Future<Map<String, double>> getCategoryBudgets({
    required String elderId,
    required DateTime month,
  }) async {
    if (elderId.isEmpty) return {};
    final String yearMonth = DateFormat('yyyy-MM').format(month);
    try {
      final docSnapshot = await FirestoreService._db
          .collection(FirestoreService._elderProfilesCollection)
          .doc(elderId)
          .collection(FirestoreService._categoryBudgetsSubcollection)
          .doc(yearMonth)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('budgets') && data['budgets'] is Map) {
          final rawMap = data['budgets'] as Map;
          return rawMap.map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble()));
        }
      }
      return {};
    } catch (error) {
      debugPrint(
          'FirestoreService.getCategoryBudgets error ($yearMonth): $error');
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Insurance Policies
  //
  // Owner-only records at top-level `insurancePolicies/{id}`. Benefit
  // counters live as a subcollection under each policy.
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _insurancePoliciesRef() =>
      FirestoreService._db.collection('insurancePolicies');

  Stream<List<InsurancePolicy>> getInsurancePoliciesStream({
    required String userId,
    String? careRecipientId,
  }) {
    if (userId.isEmpty) return Stream.value(const []);
    Query<Map<String, dynamic>> query =
        _insurancePoliciesRef().where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    return query
        .orderBy('startDate', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InsurancePolicy.fromFirestore(d))
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getInsurancePoliciesStream error: $e');
      return <InsurancePolicy>[];
    });
  }

  Future<String> addInsurancePolicy(InsurancePolicy policy) async {
    final ref = await _insurancePoliciesRef().add(policy.toFirestore());
    return ref.id;
  }

  Future<void> updateInsurancePolicy(InsurancePolicy policy) async {
    final id = policy.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Policy id is required for update');
    }
    await _insurancePoliciesRef().doc(id).update(policy.toFirestore());
  }

  Future<void> deleteInsurancePolicy(String policyId) async {
    if (policyId.isEmpty) return;
    await _insurancePoliciesRef().doc(policyId).delete();
  }

  // ---------------------------------------------------------------------------
  // Benefit Counters (subcollection of a policy)
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _benefitCountersRef(
          String policyId) =>
      _insurancePoliciesRef().doc(policyId).collection('benefitCounters');

  Stream<List<BenefitCounter>> getBenefitCountersStream(String policyId) {
    if (policyId.isEmpty) return Stream.value(const []);
    return _benefitCountersRef(policyId)
        .orderBy('benefitName')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BenefitCounter.fromFirestore(d, policyId))
            .toList())
        .handleError((e) {
      debugPrint(
          'FirestoreService.getBenefitCountersStream error ($policyId): $e');
      return <BenefitCounter>[];
    });
  }

  Future<String> addBenefitCounter(BenefitCounter counter) async {
    if (counter.policyId.isEmpty) {
      throw ArgumentError('policyId is required for a benefit counter');
    }
    final ref = await _benefitCountersRef(counter.policyId)
        .add(counter.toFirestore());
    return ref.id;
  }

  Future<void> updateBenefitCounter(BenefitCounter counter) async {
    final id = counter.id;
    if (id == null || id.isEmpty || counter.policyId.isEmpty) {
      throw ArgumentError('counter id and policyId are required');
    }
    await _benefitCountersRef(counter.policyId)
        .doc(id)
        .update(counter.toFirestore());
  }

  Future<void> deleteBenefitCounter({
    required String policyId,
    required String counterId,
  }) async {
    if (policyId.isEmpty || counterId.isEmpty) return;
    await _benefitCountersRef(policyId).doc(counterId).delete();
  }

  // ---------------------------------------------------------------------------
  // Insurance Claims
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _insuranceClaimsRef() =>
      FirestoreService._db.collection('insuranceClaims');

  Stream<List<InsuranceClaim>> getInsuranceClaimsStream({
    required String userId,
    String? careRecipientId,
    String? policyId,
    int limit = 200,
  }) {
    if (userId.isEmpty) return Stream.value(const []);
    Query<Map<String, dynamic>> query =
        _insuranceClaimsRef().where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query = query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    if (policyId != null && policyId.isNotEmpty) {
      query = query.where('policyId', isEqualTo: policyId);
    }
    return query
        .orderBy('dateOfService', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InsuranceClaim.fromFirestore(d))
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getInsuranceClaimsStream error: $e');
      return <InsuranceClaim>[];
    });
  }

  Future<String> addInsuranceClaim(InsuranceClaim claim) async {
    final ref = await _insuranceClaimsRef().add(claim.toFirestore());
    return ref.id;
  }

  Future<void> updateInsuranceClaim(InsuranceClaim claim) async {
    final id = claim.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('claim id is required for update');
    }
    await _insuranceClaimsRef().doc(id).update(claim.toFirestore());
  }

  Future<void> deleteInsuranceClaim(String claimId) async {
    if (claimId.isEmpty) return;
    await _insuranceClaimsRef().doc(claimId).delete();
  }

  // ---------------------------------------------------------------------------

  Stream<Map<String, double>> getCategoryBudgetsStream({
    required String elderId,
    required DateTime month,
  }) {
    if (elderId.isEmpty) return Stream.value(<String, double>{});
    final String yearMonth = DateFormat('yyyy-MM').format(month);
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection(FirestoreService._categoryBudgetsSubcollection)
        .doc(yearMonth)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('budgets') && data['budgets'] is Map) {
          final rawMap = data['budgets'] as Map;
          return rawMap.map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble()));
        }
      }
      return <String, double>{};
    }).handleError((error) {
      debugPrint(
          'FirestoreService.getCategoryBudgetsStream error ($yearMonth): '
          '$error');
      return <String, double>{};
    });
  }
}
