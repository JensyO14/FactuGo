import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'business_profile.dart';
import 'business_repository.dart';

final businessRepositoryProvider = Provider((ref) => BusinessRepository());

class BusinessNotifier extends AsyncNotifier<BusinessProfile?> {
  late final BusinessRepository _repo;

  @override
  Future<BusinessProfile?> build() {
    _repo = ref.watch(businessRepositoryProvider);
    return _repo.get();
  }

  Future<void> save(BusinessProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.save(profile);
      return _repo.get();
    });
  }
}

final businessProvider =
    AsyncNotifierProvider<BusinessNotifier, BusinessProfile?>(
      BusinessNotifier.new,
    );
