import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../widgets/admin_form.dart';

/// Platform user directory: filter by role, activate/deactivate an account and
/// push a notification to a single user.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  /// GET /users returns the whole directory; the role filter is applied here
  /// because AdminApiService.getUsers() takes no query parameters.
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  String _roleFilter = 'all';
  List<dynamic> _operators = [];

  /// Must match NotificationType in the backend entity exactly — the server
  /// rejects anything else with a 400.
  static const List<String> _notificationTypes = [
    'booking_confirm',
    'reminder',
    'pickup',
    'flight_update',
    'weather',
    'review_request',
    'promo',
  ];

  static const List<String> _roles = [
    'customer',
    'operator_admin',
    'platform_admin',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminApiService.getUsers(),
        AdminApiService.getOperators(),
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0];
        _operators = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered {
    if (_roleFilter == 'all') return _users;
    return _users
        .where((u) => (u['role'] ?? '').toString() == _roleFilter)
        .toList();
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'customer':
        return 'Customer';
      case 'operator_admin':
        return 'Operator Admin';
      case 'platform_admin':
        return 'Platform Admin';
      default:
        return role.isEmpty ? '-' : role;
    }
  }

  static String _typeLabel(String type) {
    return type
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static Color _roleColor(String role) {
    switch (role) {
      case 'platform_admin':
        return AdminColors.accent;
      case 'operator_admin':
        return AdminColors.secondary;
      default:
        return AdminColors.textSecondary;
    }
  }

  /// Assign a role, and for an operator admin the operator they work for.
  void _showRoleDialog(Map<String, dynamic> user) {
    final id = user['id']?.toString();
    if (id == null) {
      showSnack(context, 'This user has no id; cannot update.', error: true);
      return;
    }
    String role = (user['role'] ?? 'customer').toString();
    String? operatorId = user['operatorId']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AdminColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Role — ${user['name'] ?? user['email'] ?? ''}',
            style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminDropdown(
                  label: 'Role',
                  value: role,
                  items: _roles
                      .map((r) => DropdownMenuItem<String>(
                          value: r, child: Text(_roleLabel(r))))
                      .toList(),
                  onChanged: (v) => setInner(() => role = v ?? role),
                ),
                if (role == 'operator_admin')
                  AdminDropdown(
                    label: 'Operator this admin works for',
                    value: operatorId,
                    items: itemsFrom(_operators),
                    onChanged: (v) => setInner(() => operatorId = v),
                  ),
                if (role == 'operator_admin')
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'An operator admin only ever sees this operator\'s '
                      'flights, bookings and passengers.',
                      style: TextStyle(
                          color: AdminColors.textMuted, fontSize: 11, height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AdminColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (role == 'operator_admin' && operatorId == null) {
                  showSnack(context, 'Pick the operator first', error: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await AdminApiService.setUserRole(id, role,
                      operatorId: role == 'operator_admin' ? operatorId : null);
                  if (!mounted) return;
                  showSnack(context, 'Role updated');
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  showSnack(context, 'Error: $e', error: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> user, bool isActive) async {
    final id = user['id']?.toString();
    if (id == null) {
      showSnack(context, 'This user has no id; cannot update.', error: true);
      return;
    }
    try {
      await AdminApiService.updateUserStatus(id, isActive);
      if (!mounted) return;
      showSnack(context, isActive ? 'User activated' : 'User deactivated');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Error: $e', error: true);
    }
  }

  void _showNotificationDialog(Map<String, dynamic> user) {
    final id = user['id']?.toString();
    if (id == null) {
      showSnack(context, 'This user has no id; cannot notify.', error: true);
      return;
    }

    final titleEnCtrl = TextEditingController();
    final bodyEnCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();
    final bodyArCtrl = TextEditingController();
    String type = _notificationTypes.first;

    final who = user['name']?.toString() ?? user['email']?.toString() ?? 'user';

    showAdminDialog(
      context: context,
      title: 'Notify $who',
      saveLabel: 'Send',
      content: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminDropdown(
              label: 'Type',
              value: type,
              items: _notificationTypes
                  .map((t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(_typeLabel(t)),
                      ))
                  .toList(),
              onChanged: (v) => setLocal(() => type = v ?? type),
            ),
            AdminTextField(label: 'Title (EN)', controller: titleEnCtrl),
            AdminTextField(
              label: 'Body (EN)',
              controller: bodyEnCtrl,
              maxLines: 3,
            ),
            AdminTextField(
              label: 'Title (AR) — optional',
              controller: titleArCtrl,
            ),
            AdminTextField(
              label: 'Body (AR) — optional',
              controller: bodyArCtrl,
              maxLines: 3,
            ),
          ],
        ),
      ),
      onSave: () async {
        final titleEn = titleEnCtrl.text.trim();
        final bodyEn = bodyEnCtrl.text.trim();
        if (titleEn.isEmpty || bodyEn.isEmpty) {
          if (!mounted) return;
          showSnack(context, 'English title and body are required.',
              error: true);
          return;
        }
        try {
          await AdminApiService.sendNotification(
            userId: id,
            titleEn: titleEn,
            bodyEn: bodyEn,
            type: type,
            titleAr: titleArCtrl.text.trim(),
            bodyAr: bodyArCtrl.text.trim(),
          );
          if (!mounted) return;
          showSnack(context, 'Notification sent');
        } catch (e) {
          if (!mounted) return;
          showSnack(context, 'Error: $e', error: true);
        }
      },
    );
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    return DateFormat('d MMM yyyy').format(parsed.toLocal());
  }

  Widget _flagChip(bool on, String onLabel, String offLabel) {
    final color = on ? AdminColors.success : AdminColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        on ? onLabel : offLabel,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Users',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${rows.length} of ${_users.length} users',
                    style: const TextStyle(
                        color: AdminColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: AdminDropdown(
                      label: 'Role',
                      value: _roleFilter,
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('All roles'),
                        ),
                        ..._roles.map((r) => DropdownMenuItem<String>(
                              value: r,
                              child: Text(_roleLabel(r)),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _roleFilter = v ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh,
                        color: AdminColors.textMuted),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AdminColors.border, height: 1),
        Expanded(
          child: ListState(
            loading: _isLoading,
            error: _error,
            empty: rows.isEmpty,
            emptyMessage: _roleFilter == 'all'
                ? 'No users yet.'
                : 'No users with this role.',
            onRetry: _load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('EMAIL')),
                    DataColumn(label: Text('PHONE')),
                    DataColumn(label: Text('ROLE')),
                    DataColumn(label: Text('VERIFIED')),
                    DataColumn(label: Text('ACTIVE')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: rows.map<DataRow>((raw) {
                    final u = Map<String, dynamic>.from(raw as Map);
                    final role = (u['role'] ?? '').toString();
                    final isActive = u['isActive'] == true;
                    final isVerified = u['isVerified'] == true;
                    return DataRow(cells: [
                      DataCell(
                        Tooltip(
                          message: 'Joined ${_formatDate(u['createdAt'])}',
                          child: Text(
                            u['name']?.toString() ?? '-',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      DataCell(Text(u['email']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                        (u['phone']?.toString().isNotEmpty ?? false)
                            ? u['phone'].toString()
                            : '-',
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        _roleLabel(role),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _roleColor(role),
                        ),
                      )),
                      DataCell(_flagChip(isVerified, 'VERIFIED', 'UNVERIFIED')),
                      DataCell(_flagChip(isActive, 'ACTIVE', 'INACTIVE')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message:
                                isActive ? 'Deactivate user' : 'Activate user',
                            child: Switch(
                              value: isActive,
                              onChanged: (v) => _toggleActive(u, v),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.admin_panel_settings_outlined,
                                color: AdminColors.primary, size: 18),
                            tooltip: 'Change role / operator',
                            onPressed: () => _showRoleDialog(u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_active_outlined,
                                color: AdminColors.secondary, size: 18),
                            tooltip: 'Send notification',
                            onPressed: () => _showNotificationDialog(u),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
