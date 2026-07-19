import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/payment_provider.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _gold = Color(0xFFE4C46C);
  static const _goldLight = Color(0xFFF7E3A4);
  static const _obsidian = Color(0xFF121313);
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      paymentProvider.fetchActivePlans();
      paymentProvider.fetchMySubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hội viên'), elevation: 0),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.plans.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final mySub = provider.mySubscription;
          final normalizedPlanName = mySub?.planName.trim().toLowerCase() ?? '';
          final isMonthlyOrYearlyPlan =
              normalizedPlanName == 'hội viên tháng' ||
              normalizedPlanName == 'hội viên năm';
          final hasActiveVIP =
              mySub != null &&
              mySub.status.toLowerCase() == 'active' &&
              isMonthlyOrYearlyPlan;

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchActivePlans();
              await provider.fetchMySubscription();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Active VIP Status Header ---
                  if (hasActiveVIP) ...[
                    _buildActiveVIPCard(mySub),
                    const SizedBox(height: 25),
                  ],

                  // --- VIP Benefits Section ---
                  Text(
                    'Đặc quyền thành viên VIP',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitsList(),

                  const SizedBox(height: 30),

                  // --- Plans Section ---
                  Text(
                    'Chọn gói nâng cấp',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.plans.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Không có gói dịch vụ nào khả dụng lúc này.',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.plans.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final plan = provider.plans[index];
                        return _buildPlanCard(plan, provider, hasActiveVIP);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveVIPCard(dynamic mySub) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final endDateStr = mySub.endDate != null
        ? dateFormat.format(mySub.endDate!.toLocal())
        : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_obsidian, Color(0xFF1C1B17), Color(0xFF111212)],
          stops: [0, 0.55, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(color: _gold.withValues(alpha: 0.08), blurRadius: 24),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -75,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.16),
                    _gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF65D99A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'ĐANG HOẠT ĐỘNG',
                            style: GoogleFonts.outfit(
                              color: _goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_goldLight, _gold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF33280E),
                        size: 25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'THÀNH VIÊN GYMSUP',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPlanName(mySub.planName),
                  style: GoogleFonts.outfit(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: _goldLight,
                  ),
                ),
                const SizedBox(height: 22),
                Container(height: 1, color: _gold.withValues(alpha: 0.16)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    _buildMembershipMeta(
                      icon: Icons.timelapse_rounded,
                      label: 'Thời gian còn lại',
                      value: '${mySub.daysRemaining} ngày',
                    ),
                    _buildMembershipMeta(
                      icon: Icons.event_available_rounded,
                      label: 'Ngày hết hạn',
                      value: endDateStr,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlanName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Hội viên VIP';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  Widget _buildMembershipMeta({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Icon(icon, color: _gold, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'title': 'AI huấn luyện viên cá nhân 24/7',
        'subtitle': 'Trò chuyện phân tích bài tập không giới hạn',
      },
      {
        'title': 'Thống kê nhóm cơ thông minh',
        'subtitle': 'Đồ thị phân tích chi tiết tiến trình tập luyện',
      },
      {
        'title': 'Gợi ý thực đơn cá nhân hóa',
        'subtitle': 'AI đề xuất dinh dưỡng tự động theo thể trạng',
      },
      {
        'title': 'Trải nghiệm không quảng cáo',
        'subtitle': 'Tập trung hoàn toàn vào hành trình tăng cơ',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: benefits.map((b) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: _gold, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['title']!,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b['subtitle']!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(
    dynamic plan,
    PaymentProvider provider,
    bool isAlreadyVIP,
  ) {
    final isYearly = plan.durationMonths == 12;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isYearly
              ? const [Color(0xFF1D1C18), Color(0xFF171818)]
              : const [AppColors.cardBackground, AppColors.cardBackground],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYearly ? _gold.withValues(alpha: 0.38) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatPlanName(plan.name),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isYearly) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'NỔI BẬT',
                          style: GoogleFonts.outfit(
                            color: _goldLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Thời hạn: ${plan.durationMonths} Tháng',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(plan.price),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _goldLight,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    final success = await provider.startCheckout(plan.id);
                    if (success && mounted) {
                      context.push('/subscription/checkout');
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.errorMessage ??
                                'Không thể kết nối thanh toán.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
            isLoading: provider.isLoading,
            text: isAlreadyVIP ? 'Gia hạn' : 'Nâng cấp',
            isSecondary: isAlreadyVIP,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String text,
    required bool isSecondary,
  }) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.autorenew_rounded, size: 19),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _gold, width: 1.5),
          minimumSize: const Size(132, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        label: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _goldLight,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_goldLight, _gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(132, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2A210D),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 19,
              color: Color(0xFF2A210D),
            ),
          ],
        ),
      ),
    );
  }
}
