import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maneja el índice de la pestaña activa en el [MainShell].
/// 0: Dashboard
/// 1: Nueva Factura
/// 2: Historial de Ventas
/// 3: Clientes
/// 4: Productos
/// 5: Categorías
/// 6: Gastos
/// 7: Mi empresa
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);
