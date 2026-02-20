import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client.dart';
import 'client_repository.dart';

final _clientRepo = ClientRepository();

/// Lista de clientes (se reconstruye con ref.invalidate).
final clientsProvider = FutureProvider<List<Client>>((ref) {
  // Watch the notifier so this provider auto-refreshes
  // whenever clients are added, edited, or deleted
  ref.watch(clientNotifierProvider);
  return _clientRepo.getAll();
});

/// Notifier para mutaciones (alta, baja, modificación).
class ClientNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() => _clientRepo.getAll();

  Future<void> add(Client client) async {
    await _clientRepo.insert(client);
    ref.invalidateSelf();
  }

  Future<void> edit(Client client) async {
    await _clientRepo.update(client);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _clientRepo.delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<int> ensureDefaultClient() async {
    return _clientRepo.ensureDefaultClient();
  }
}

final clientNotifierProvider =
    AsyncNotifierProvider<ClientNotifier, List<Client>>(ClientNotifier.new);
