import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_plan_provider.dart';
import '../../widgets/workout/plan_list_card.dart';

/// Danh sách toàn bộ lịch tập của user, cho phép kích hoạt/xem chi tiết/tạo mới.
class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) context.read<WorkoutPlanProvider>().fetchPlans(userId);
  }

  Future<void> _activate(String planId) async {
    final ok = await context.read<WorkoutPlanProvider>().activatePlan(planId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kích hoạt lịch tập.')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kích hoạt lịch tập.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutPlanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch tập của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/workout-plans/build');
          if (mounted) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo lịch mới'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.errorMessage != null
              ? Center(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : provider.plans.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có lịch tập nào. Bấm "Tạo lịch mới" để bắt đầu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: provider.plans.length,
                      itemBuilder: (context, index) {
                        final plan = provider.plans[index];
                        return PlanListCard(
                          plan: plan,
                          onTap: () async {
                            await context.push('/workout-plans/${plan.id}');
                            if (mounted) _load();
                          },
                          onActivate: plan.isActive ? null : () => _activate(plan.id),
                        );
                      },
                    ),
    );
  }
}
