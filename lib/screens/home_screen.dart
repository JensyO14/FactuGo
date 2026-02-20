import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/navigation_provider.dart';
import '../features/dashboard/dashboard_provider.dart';
import '../features/dashboard/dashboard_repository.dart';
import '../features/invoices/invoice.dart';
import 'main_shell.dart';

/// Dashboard — solo el body, sin Scaffold propio.
/// El Scaffold lo gestiona MainShell.
class HomeBody extends ConsumerWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Refresh logic could be improved with a RefreshIndicator
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(weeklySalesProvider);
            ref.invalidate(recentInvoicesProvider);
            // Wait a bit for UX
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 24),
                const _StatsSection(),
                const SizedBox(height: 24),
                const _ChartSection(),
                const SizedBox(height: 24),
                const _RecentActivitySection(),
                const SizedBox(height: 80), // Fab space
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              ref.read(navigationProvider.notifier).setIndex(1);
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_shopping_cart),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE d, MMMM', 'es').format(now);
    // Capitalize first letter
    final dateFormatted = dateStr[0].toUpperCase() + dateStr.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateFormatted,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumen de actividad',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox(),
      data: (stats) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            // 2 items per row
            final double itemWidth = (width - 16) / 2;

            return Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _StatCard(
                        title: 'Ventas Hoy',
                        value: NumberFormat.simpleCurrency(
                          decimalDigits: 0,
                        ).format(stats.dailySales),
                        icon: Icons.attach_money,
                        color: AppColors.success,
                        backgroundColor: AppColors.successLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: itemWidth,
                      child: _StatCard(
                        title: 'Ventas Mes',
                        value: NumberFormat.simpleCurrency(
                          decimalDigits: 0,
                        ).format(stats.monthlySales),
                        icon: Icons.calendar_today,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _StatCard(
                        title: 'Por Cobrar',
                        value: stats.pendingCount.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        backgroundColor: Colors.orange.withAlpha(40),
                      ),
                    ),
                    if (stats.lowStockCount > 0) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: itemWidth,
                        child: _StatCard(
                          title: 'Stock Bajo',
                          value: stats.lowStockCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.error,
                          backgroundColor: AppColors.errorLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.inputBorder.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklySalesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas últimos 7 días',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          weeklyAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(height: 150),
            data: (points) {
              if (points.isEmpty) return const SizedBox(height: 150);

              final maxVal = points
                  .map((e) => e.amount)
                  .reduce((a, b) => a > b ? a : b);
              final safeMax = maxVal == 0 ? 1.0 : maxVal;

              return SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: points.map((p) {
                    final percentage = p.amount / safeMax;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (p.amount > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              NumberFormat.compact().format(p.amount),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Container(
                          width: 20, // bar width
                          height:
                              100 * percentage + 4, // min height + proportional
                          decoration: BoxDecoration(
                            color: percentage > 0
                                ? AppColors.primary
                                : AppColors.inputBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentInvoicesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        activityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error al cargar actividad'),
          data: (invoices) {
            if (invoices.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Text(
                  'No hay actividad reciente',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textHint),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.inputBorder.withAlpha(50),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: invoice.status == 'pagada'
                          ? AppColors.successLight
                          : (invoice.status == 'anulada'
                                ? AppColors.errorLight
                                : Colors.orange.withAlpha(40)),
                      child: Icon(
                        invoice.status == 'pagada'
                            ? Icons.check
                            : (invoice.status == 'anulada'
                                  ? Icons.close
                                  : Icons.access_time),
                        color: invoice.status == 'pagada'
                            ? AppColors.success
                            : (invoice.status == 'anulada'
                                  ? AppColors.error
                                  : Colors.orange),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      invoice.client?.name ?? 'Cliente Final',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '#${invoice.number ?? "---"} • ${DateFormat('dd/MM HH:mm').format(invoice.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      NumberFormat.simpleCurrency(
                        decimalDigits: 0,
                      ).format(invoice.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Adaptador: convierte HomeBody en ScreenConfig para MainShell.
extension HomBodyConfig on HomeBody {
  ScreenConfig toConfig() => ScreenConfig(body: this);
}
