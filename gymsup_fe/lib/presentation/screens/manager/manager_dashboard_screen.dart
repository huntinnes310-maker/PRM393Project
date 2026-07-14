import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  // State for Users
  List<dynamic> _users = [];
  bool _isLoadingUsers = false;
  String _userSearchQuery = '';

  // State for Exercises
  List<dynamic> _exercises = [];
  bool _isLoadingExercises = false;
  String _exerciseSearchQuery = '';

  // State for Stats Summary
  Map<String, dynamic>? _summaryStats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadTabCurrentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _loadTabCurrentData();
  }

  void _loadTabCurrentData() {
    if (_tabController.index == 0) {
      _fetchUsers();
    } else if (_tabController.index == 1) {
      _fetchExercises();
    } else if (_tabController.index == 2) {
      _fetchSummaryStats();
    }
  }

  // --- API CALLS ---

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await _apiClient.get('/user');
      if (response.statusCode == 200) {
        setState(() {
          _users = ApiClient.decodeResponse(response) as List? ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchExercises() async {
    setState(() => _isLoadingExercises = true);
    try {
      final response = await _apiClient.get('/exercises');
      if (response.statusCode == 200) {
        setState(() {
          _exercises = ApiClient.decodeResponse(response) as List? ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
    } finally {
      setState(() => _isLoadingExercises = false);
    }
  }

  Future<void> _fetchSummaryStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final response = await _apiClient.get('/admin/dashboard/summary');
      if (response.statusCode == 200) {
        setState(() {
          _summaryStats = ApiClient.decodeResponse(response) as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching summary stats: $e');
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _toggleUserActiveStatus(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    final endpoint = '/user/$userId/${newStatus ? "activate" : "deactivate"}';
    try {
      final response = await _apiClient.put(endpoint, {});
      if (response.statusCode == 204 || response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Đã kích hoạt tài khoản! ✅' : 'Đã vô hiệu hóa tài khoản! 🔒'),
            backgroundColor: newStatus ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling user status: $e');
    }
  }

  Future<void> _changeUserRole(String userId, String currentRole) async {
    final newRole = currentRole == 'Manager' ? 'Customer' : 'Manager';
    try {
      final response = await _apiClient.put('/user/$userId', {
        'role': newRole,
      });
      if (response.statusCode == 204 || response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật vai trò thành $newRole! 👑'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error changing user role: $e');
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa tài khoản này khỏi hệ thống không?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _apiClient.delete('/user/$userId');
      if (response.statusCode == 204 || response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa người dùng khỏi hệ thống. 🗑️'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> _deleteExercise(String exerciseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa bài tập này không?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _apiClient.delete('/exercises/$exerciseId');
      if (response.statusCode == 204 || response.statusCode == 200) {
        _fetchExercises();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài tập thành công! 🗑️'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
    }
  }

  // --- POPUP DIALOG FOR CUSTOMER DETAIL ---

  Future<dynamic> _fetchCustomerProfile(String userId) async {
    try {
      final response = await _apiClient.get('/customer/user/$userId');
      if (response.statusCode == 200) {
        return ApiClient.decodeResponse(response);
      }
    } catch (e) {
      debugPrint('Error loading customer profile: $e');
    }
    return null;
  }

  Future<void> _showCustomerProfileDialog(String userId, String name, String email) async {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return FutureBuilder<dynamic>(
            future: _fetchCustomerProfile(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  content: const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Chưa cập nhật hồ sơ thể trạng. 📋',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                );
              }

              final profile = snapshot.data!;
              final int age = profile['age'] ?? 0;
              final double height = (profile['heightCm'] as num? ?? 0).toDouble();
              final double weight = (profile['weightKg'] as num? ?? 0).toDouble();
              final double bmi = (profile['bmi'] as num? ?? 0).toDouble();
              final String bmiStatus = profile['bmiStatus'] ?? '';
              final String gender = profile['gender'] == 'Male'
                  ? 'Nam 👨'
                  : profile['gender'] == 'Female'
                      ? 'Nữ 👩'
                      : 'Chưa cập nhật';
              final String goal = profile['goalDisplayName'] ?? 'Chưa cập nhật';
              final String exp = profile['experienceDisplayName'] ?? 'Chưa cập nhật';
              final String injury = profile['injuryNotes'] ?? '';

              return AlertDialog(
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.assignment_ind, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Divider(color: AppColors.surfaceVariant, height: 20),
                      
                      // Body Metrics
                      const Text('Chỉ số cơ thể', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileStatItem('Chiều cao', '${height.round()} cm'),
                          _buildProfileStatItem('Cân nặng', '${weight.round()} kg'),
                          _buildProfileStatItem('BMI', bmi > 0 ? bmi.toStringAsFixed(1) : '--'),
                        ],
                      ),
                      if (bmiStatus.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Trạng thái: $bmiStatus',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const Divider(color: AppColors.surfaceVariant, height: 20),

                      // Personal info
                      const Text('Thông tin chi tiết', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildProfileRowItem('Tuổi', age > 0 ? '$age tuổi' : 'Chưa cập nhật'),
                      _buildProfileRowItem('Giới tính', gender),
                      _buildProfileRowItem('Mục tiêu', goal),
                      _buildProfileRowItem('Trình độ', exp),
                      if (injury.isNotEmpty)
                        _buildProfileRowItem('Lưu ý chấn thương', injury),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildProfileRowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'GymSup Manager & Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _loadTabCurrentData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Thành viên'),
            Tab(icon: Icon(Icons.fitness_center_outlined, size: 20), text: 'Bài tập'),
            Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'Thống kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildExercisesTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // --- TAB 1: USER MANAGEMENT ---

  Widget _buildUsersTab() {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    final filteredUsers = _users.where((u) {
      final name = (u['fullName'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(_userSearchQuery) || email.contains(_userSearchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (val) => setState(() => _userSearchQuery = val.trim().toLowerCase()),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tìm thành viên...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : filteredUsers.isEmpty
                  ? const Center(child: Text('Không tìm thấy thành viên.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (ctx, i) {
                        final u = filteredUsers[i];
                        final String id = u['id'] ?? '';
                        final String name = u['fullName'] ?? 'Không tên';
                        final String email = u['email'] ?? '';
                        final String role = u['role'] ?? 'Customer';
                        final bool isActive = u['isActive'] ?? true;
                        final bool isVerified = u['isEmailVerified'] ?? false;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceVariant, width: 0.5),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (role == 'Customer') {
                                _showCustomerProfileDialog(id, name, email);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: role == 'Manager'
                                        ? AppColors.primary.withOpacity(0.15)
                                        : role == 'Admin'
                                            ? Colors.purple.withOpacity(0.15)
                                            : AppColors.surfaceVariant,
                                    child: Icon(
                                      role == 'Admin'
                                          ? Icons.admin_panel_settings
                                          : role == 'Manager'
                                              ? Icons.security
                                              : Icons.person,
                                      color: role == 'Admin'
                                          ? Colors.purple
                                          : role == 'Manager'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isVerified ? AppColors.success.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isVerified ? 'Đã xác thực' : 'Chưa xác thực',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: isVerified ? AppColors.success : Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (role == 'Customer') ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.info_outline, size: 13, color: AppColors.primary),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('Vai trò: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                            Text(
                                              role,
                                              style: TextStyle(
                                                color: role == 'Admin'
                                                    ? Colors.purple
                                                    : role == 'Manager'
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text('Trạng thái: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                            Text(
                                              isActive ? 'Hoạt động' : 'Bị khóa',
                                              style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                      color: AppColors.cardBackground,
                                      onSelected: (action) {
                                        if (action == 'toggle_active') {
                                          _toggleUserActiveStatus(id, isActive);
                                        } else if (action == 'toggle_role') {
                                          _changeUserRole(id, role);
                                        } else if (action == 'delete') {
                                          _deleteUser(id);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          value: 'toggle_active',
                                          child: Text(isActive ? 'Khóa tài khoản 🔒' : 'Mở khóa 🔓', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle_role',
                                          child: Text(role == 'Manager' ? 'Hạ quyền Customer 👤' : 'Nâng quyền Manager 👑', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Xóa vĩnh viễn 🗑️', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // --- TAB 2: EXERCISE MANAGEMENT ---

  Widget _buildExercisesTab() {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    final filteredExercises = _exercises.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final equip = (e['equipment'] ?? '').toString().toLowerCase();
      return name.contains(_exerciseSearchQuery) || equip.contains(_exerciseSearchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showExerciseForm(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _exerciseSearchQuery = val.trim().toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm bài tập...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoadingExercises
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredExercises.isEmpty
                    ? const Center(child: Text('Không tìm thấy bài tập.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        itemCount: filteredExercises.length,
                        itemBuilder: (ctx, i) {
                          final e = filteredExercises[i];
                          final String id = e['id'] ?? '';
                          final String name = e['name'] ?? 'Không tên';
                          final String equipment = e['equipment'] ?? 'Không có';
                          final String difficulty = e['difficulty'] ?? 'Medium';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceVariant, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Thiết bị: $equipment', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          difficulty,
                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin) ...[
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                    color: AppColors.cardBackground,
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _showExerciseForm(exercise: e);
                                      } else if (action == 'delete') {
                                        _deleteExercise(id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Chỉnh sửa 📝', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa bài tập 🗑️', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showExerciseForm({Map<String, dynamic>? exercise}) {
    final isEdit = exercise != null;
    final nameController = TextEditingController(text: isEdit ? exercise['name'] : '');
    final equipController = TextEditingController(text: isEdit ? exercise['equipment'] : '');
    final diffController = TextEditingController(text: isEdit ? exercise['difficulty'] : 'Beginner');
    final descController = TextEditingController(text: isEdit ? exercise['description'] : '');
    final instController = TextEditingController(text: isEdit ? exercise['instruction'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Chỉnh sửa bài tập' : 'Thêm bài tập mới',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildFormTextField(nameController, 'Tên bài tập (ví dụ: Bench Press)'),
                const SizedBox(height: 12),
                _buildFormTextField(equipController, 'Thiết bị (ví dụ: Barbell)'),
                const SizedBox(height: 12),
                _buildFormTextField(diffController, 'Mức độ (Beginner/Intermediate/Advanced)'),
                const SizedBox(height: 12),
                _buildFormTextField(descController, 'Mô tả bài tập', maxLines: 2),
                const SizedBox(height: 12),
                _buildFormTextField(instController, 'Hướng dẫn tập luyện', maxLines: 3),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final equip = equipController.text.trim();
                      final diff = diffController.text.trim();
                      final desc = descController.text.trim();
                      final inst = instController.text.trim();

                      if (name.isEmpty || equip.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng điền đủ Tên và Thiết bị! ⚠️'), backgroundColor: AppColors.error),
                        );
                        return;
                      }

                      final body = {
                        'name': name,
                        'equipment': equip,
                        'difficulty': diff,
                        'description': desc,
                        'instruction': inst,
                        'defaultSets': 3,
                        'defaultReps': '10-12',
                        'restTimeSeconds': 60,
                        'muscleImpacts': []
                      };

                      Navigator.pop(ctx);
                      try {
                        final res = isEdit
                            ? await _apiClient.put('/exercises/${exercise['id']}', body)
                            : await _apiClient.post('/exercises', body);

                        if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
                          _fetchExercises();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Đã lưu chỉnh sửa bài tập! 💾' : 'Đã tạo bài tập mới thành công! 🎉'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error saving exercise: $e');
                      }
                    },
                    child: const Text('Lưu thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
    );
  }

  // --- TAB 3: STATISTICS SUMMARY ---

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_summaryStats == null) {
      return const Center(
        child: Text('Không thể tải số liệu thống kê.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final totalCustomers = _summaryStats!['totalCustomers'] ?? 0;
    final newCustomers = _summaryStats!['newCustomersThisMonth'] ?? 0;
    final activeVIPs = _summaryStats!['activeSubscriptions'] ?? 0;
    final revenue = _summaryStats!['revenueThisMonth'] ?? 0;
    final totalRevenue = _summaryStats!['totalRevenue'] ?? 0;
    final completedWorkouts = _summaryStats!['completedWorkouts'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMetricCard('Thành viên', '$totalCustomers', '+$newCustomers tháng này', Icons.people, AppColors.info),
          _buildMetricCard('Thành viên VIP 👑', '$activeVIPs', 'Gói đang kích hoạt', Icons.stars, AppColors.primary),
          _buildMetricCard('Doanh thu tháng 💵', '${revenue.toStringAsFixed(0)}đ', 'Tháng hiện tại', Icons.monetization_on, AppColors.success),
          _buildMetricCard('Tổng doanh thu 💰', '${totalRevenue.toStringAsFixed(0)}đ', 'Doanh thu lũy kế', Icons.account_balance_wallet, Colors.amber),
          _buildMetricCard('Buổi tập hoàn thành', '$completedWorkouts', 'Toàn bộ hệ thống', Icons.fitness_center, Colors.purple),
          _buildMetricCard('Vai trò hệ thống', 'Quản trị viên', 'Manager & Admin', Icons.admin_panel_settings, Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtext, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
