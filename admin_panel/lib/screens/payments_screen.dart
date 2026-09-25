import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../utils/num_parse.dart';
import '../widgets/admin_form.dart';

/// Payments overview.
///
/// The payments module exposes no "list all payments" route — the only read
/// endpoint is GET /payments/booking/:bookingId. So this screen lists the
/// bookings (GET /bookings) with the payment state the booking row carries,
/// and loads the real Payment records on demand, per booking, when an admin
/// opens the detail dialog or issues a refund.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

/// PaymentStatus in bookings/entities/booking.entity.ts — these strings must
/// match the backend enum exactly.
const List<String> _paymentStatuses = [
  'pending',
  'paid',
  'refunded',
  'partial_refund',
];

String _errorText(Object e) {
  if (e is ApiException) return e.message;
  return e.toString();
}

String _money(dynamic value) {
  // Postgres decimals arrive as strings ("18000.00"); asDouble is the only
  // safe way to get a number out of them.
  return '${NumberFormat('#,##0').format(asDouble(value))} EGP';
}

String _dateLabel(dynamic raw) {
  if (raw == null) return '-';
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return raw.toString();
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}

String _dateTimeLabel(dynamic raw) {
  if (raw == null) return '-';
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return raw.toString();
  return DateFormat('dd MMM yyyy • HH:mm').format(parsed.toLocal());
}

String _statusLabel(String raw) {
  if (raw.isEmpty) return '-';
  return raw.replaceAll('_', ' ').toUpperCase();
}

Color _paymentStatusColor(String status) {
  switch (status) {
    case 'paid':
      return AdminColors.success;
    case 'refunded':
      return AdminColors.info;
    case 'partial_refund':
      return AdminColors.secondary;
    default:
      return AdminColors.warning;
  }
}

Color _bookingStatusColor(String status) {
  switch (status) {
    case 'confirmed':
    case 'completed':
      return AdminColors.success;
    case 'checked_in':
      return AdminColors.info;
    case 'cancelled':
    case 'no_show':
      return AdminColors.error;
    default:
      return AdminColors.warning;
  }
}

/// TransactionStatus on the Payment row itself (payments/entities/payment.entity.ts):
/// pending | success | failed | refunded — deliberately NOT the same set as the
/// booking's PaymentStatus.
Color _txnStatusColor(String status) {
  switch (status) {
    case 'success':
      return AdminColors.success;
    case 'refunded':
      return AdminColors.info;
    case 'failed':
      return AdminColors.error;
    default:
      return AdminColors.warning;
  }
}

Widget _chip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  color: AdminColors.textMuted, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AdminColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> _bookings = [];

  /// What each operator is owed, computed by the API from paid bookings and
  /// the operator's commission rate. Settling up used to mean exporting the
  /// bookings and doing the arithmetic in a spreadsheet.
  Map<String, dynamic>? _payouts;
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  /// Set while a booking's Payment rows are being fetched for a refund, so the
  /// row's button can't be pressed twice.
  String? _busyBookingId;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    try {
      final data = await AdminApiService.getPayouts();
      if (!mounted) return;
      setState(() => _payouts = data);
    } catch (_) {
      // The payments table is the main thing on this screen; a failed
      // settlement query should not take it down with it.
      if (mounted) setState(() => _payouts = null);
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await AdminApiService.getBookings();
      if (!mounted) return;
      setState(() {
        _bookings = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(e);
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered {
    if (_statusFilter == 'all') return _bookings;
    return _bookings
        .where((b) => (b['paymentStatus'] ?? '').toString() == _statusFilter)
        .toList();
  }

  void _openDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => _BookingPaymentsDialog(
        booking: booking,
        onRefund: (payment) => _confirmAndRefund(booking, payment),
      ),
    );
  }

  /// Refunding needs a *payment* id, and the booking row does not carry one —
  /// so look the Payment rows up first and refund the settled one.
  Future<void> _startRefund(Map<String, dynamic> booking) async {
    final bookingId = booking['id']?.toString();
    final ref = booking['bookingRef']?.toString() ?? 'this booking';
    if (bookingId == null || bookingId.isEmpty) {
      showSnack(context, 'This booking has no id — cannot look up its payments.',
          error: true);
      return;
    }

    setState(() => _busyBookingId = bookingId);
    List<dynamic> payments;
    try {
      payments = await AdminApiService.getPaymentsForBooking(bookingId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyBookingId = null);
      showSnack(context, 'Could not load payments for $ref: ${_errorText(e)}',
          error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _busyBookingId = null);

    final settled = payments
        .where((p) => (p['status'] ?? '').toString() == 'success')
        .toList();
    if (settled.isEmpty) {
      showSnack(
        context,
        'No settled payment record exists for $ref, so there is nothing to '
        'refund. Open the details to see what was recorded.',
        error: true,
      );
      return;
    }

    // getPaymentsForBooking orders by createdAt DESC, so the first settled row
    // is the most recent one.
    await _confirmAndRefund(
        booking, Map<String, dynamic>.from(settled.first as Map));
  }

  Future<void> _confirmAndRefund(
      Map<String, dynamic> booking, Map<String, dynamic> payment) async {
    final paymentId = payment['id']?.toString();
    if (paymentId == null || paymentId.isEmpty) {
      showSnack(context, 'That payment record has no id — cannot refund it.',
          error: true);
      return;
    }
    final ref = booking['bookingRef']?.toString() ?? '-';
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Refund $ref?',
            style: const TextStyle(
                color: AdminColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Amount', _money(payment['amountEgp'])),
              _detailRow('Guest', (booking['user']?['name'] ?? '-').toString()),
              _detailRow('Gateway',
                  (payment['gateway'] ?? '-').toString().toUpperCase()),
              _detailRow('Transaction',
                  (payment['gatewayTransactionId'] ?? '-').toString()),
              const SizedBox(height: 12),
              AdminTextField(
                label: 'Reason (optional)',
                controller: reasonCtrl,
                hint: 'Shown on the booking as the cancellation reason',
                maxLines: 2,
              ),
              const _WarningNote(
                'This marks the payment and the booking as refunded and puts '
                'the seats back on the flight. No payment gateway is wired up, '
                'so no money is actually returned to the customer — settle that '
                'separately.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep payment',
                style: TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark refunded'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final reason = reasonCtrl.text.trim();
    try {
      await AdminApiService.refundPayment(
        paymentId,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      showSnack(context,
          'Payment recorded as refunded for $ref — records only, no money moved.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, _errorText(e), error: true);
    }
  }

  /// Who is owed what. Gross is the money collected from paid, non-cancelled
  /// bookings; the platform keeps the operator's commission rate and the rest
  /// is payable to them.
  Widget _payoutSection() {
    final payouts = _payouts;
    if (payouts == null) return const SizedBox.shrink();

    final lines = (payouts['lines'] as List?) ?? const [];
    if (lines.isEmpty) return const SizedBox.shrink();
    final totals = (payouts['totals'] as Map?) ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operator settlement',
          style: TextStyle(
            color: AdminColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Collected money, minus commission, per operator.',
          style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AdminColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.border),
          ),
          child: DataTable(
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('OPERATOR')),
              DataColumn(label: Text('BOOKINGS')),
              DataColumn(label: Text('PASSENGERS')),
              DataColumn(label: Text('GROSS')),
              DataColumn(label: Text('COMMISSION')),
              DataColumn(label: Text('NET PAYABLE')),
            ],
            rows: [
              ...lines.map<DataRow>((raw) {
                final l = Map<String, dynamic>.from(raw as Map);
                return DataRow(cells: [
                  DataCell(Text(l['operatorName']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text('${l['bookings'] ?? 0}',
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text('${l['passengers'] ?? 0}',
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(_money(asDouble(l['grossEgp'])),
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(
                    '${_money(asDouble(l['commissionEgp']))}  '
                    '(${asDouble(l['commissionRate']).toStringAsFixed(1)}%)',
                    style: const TextStyle(
                        fontSize: 12, color: AdminColors.textSecondary),
                  )),
                  DataCell(Text(
                    _money(asDouble(l['netPayableEgp'])),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.success,
                    ),
                  )),
                ]);
              }),
              DataRow(
                color: WidgetStateProperty.all(
                    AdminColors.primary.withValues(alpha: 0.06)),
                cells: [
                  const DataCell(Text('Total',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold))),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  DataCell(Text(_money(asDouble(totals['grossEgp'])),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(Text(_money(asDouble(totals['commissionEgp'])),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(Text(
                    _money(asDouble(totals['netPayableEgp'])),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.success,
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    // Totals are computed over whatever is currently on screen, and revenue
    // counts only bookings the backend considers paid.
    double revenue = 0;
    double commission = 0;
    double refunded = 0;
    for (final b in rows) {
      final status = (b['paymentStatus'] ?? '').toString();
      if (status == 'paid') {
        revenue += asDouble(b['totalPriceEgp']);
        commission += asDouble(b['commissionAmount']);
      } else if (status == 'refunded' || status == 'partial_refund') {
        refunded += asDouble(b['totalPriceEgp']);
      }
    }

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
                  Text('Payments',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${rows.length} of ${_bookings.length} bookings shown',
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
                      label: 'Payment status',
                      value: _statusFilter,
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('All payment statuses'),
                        ),
                        ..._paymentStatuses.map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(_statusLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v ?? 'all'),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 0),
          child: _ScreenNote(),
        ),
        const SizedBox(height: 16),
        const Divider(color: AdminColors.border, height: 1),
        Expanded(
          child: ListState(
            loading: _isLoading,
            error: _error,
            empty: rows.isEmpty,
            emptyMessage: _statusFilter == 'all'
                ? 'No bookings yet, so there is nothing to collect.'
                : 'No bookings with payment status "${_statusLabel(_statusFilter)}".',
            onRetry: _load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _payoutSection(),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Revenue (paid)',
                          value: _money(revenue),
                          icon: Icons.payments_outlined,
                          color: AdminColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Platform commission',
                          value: _money(commission),
                          icon: Icons.percent,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Refunded',
                          value: _money(refunded),
                          icon: Icons.undo,
                          color: AdminColors.info,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Bookings shown',
                          value: '${rows.length}',
                          icon: Icons.receipt_long_outlined,
                          color: AdminColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AdminColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: DataTable(
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(label: Text('BOOKING REF')),
                        DataColumn(label: Text('CUSTOMER')),
                        DataColumn(label: Text('AMOUNT (EGP)')),
                        DataColumn(label: Text('COMMISSION')),
                        DataColumn(label: Text('PAYMENT')),
                        DataColumn(label: Text('BOOKING')),
                        DataColumn(label: Text('DATE')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: rows.map<DataRow>((raw) {
                        final b = Map<String, dynamic>.from(raw as Map);
                        final payStatus =
                            (b['paymentStatus'] ?? 'pending').toString();
                        final bookStatus =
                            (b['bookingStatus'] ?? 'pending').toString();
                        final canRefund = payStatus == 'paid';
                        final busy =
                            _busyBookingId == b['id']?.toString();

                        return DataRow(cells: [
                          DataCell(InkWell(
                            onTap: () => _openDetails(b),
                            child: Text(
                              b['bookingRef']?.toString() ?? '-',
                              style: const TextStyle(
                                color: AdminColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )),
                          DataCell(Text(
                            (b['user']?['name'] ?? '-').toString(),
                            style: const TextStyle(fontSize: 12),
                          )),
                          DataCell(Text(
                            _money(b['totalPriceEgp']),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            _money(b['commissionAmount']),
                            style: const TextStyle(fontSize: 12),
                          )),
                          DataCell(_chip(_statusLabel(payStatus),
                              _paymentStatusColor(payStatus))),
                          DataCell(_chip(_statusLabel(bookStatus),
                              _bookingStatusColor(bookStatus))),
                          DataCell(Text(
                            _dateLabel(b['createdAt']),
                            style: const TextStyle(fontSize: 12),
                          )),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.receipt_long_outlined,
                                    color: AdminColors.secondary, size: 18),
                                tooltip: 'Payment records',
                                onPressed: () => _openDetails(b),
                              ),
                              TextButton.icon(
                                onPressed: (canRefund && !busy)
                                    ? () => _startRefund(b)
                                    : null,
                                icon: busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AdminColors.error),
                                      )
                                    : const Icon(Icons.undo, size: 16),
                                label: const Text('Refund',
                                    style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AdminColors.error,
                                  disabledForegroundColor:
                                      AdminColors.textMuted,
                                ),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The two things an admin has to know before trusting this screen.
class _ScreenNote extends StatelessWidget {
  const _ScreenNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AdminColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'The API has no "list all payments" route, so this table '
                  'lists bookings and the payment state they carry. Open a row '
                  'to load the actual payment records for that booking.',
                  style:
                      TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'Refunding updates the payment and booking records and '
                  'releases the seats. No payment gateway is connected yet, so '
                  'no money leaves or returns — move the funds yourself.',
                  style:
                      TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningNote extends StatelessWidget {
  final String text;
  const _WarningNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AdminColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AdminColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AdminColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loads GET /payments/booking/:id and shows the real Payment rows — the only
/// place in the admin panel where actual payment records are visible.
class _BookingPaymentsDialog extends StatefulWidget {
  final Map<String, dynamic> booking;
  final void Function(Map<String, dynamic> payment) onRefund;

  const _BookingPaymentsDialog({
    required this.booking,
    required this.onRefund,
  });

  @override
  State<_BookingPaymentsDialog> createState() => _BookingPaymentsDialogState();
}

class _BookingPaymentsDialogState extends State<_BookingPaymentsDialog> {
  List<dynamic> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    try {
      final data = await AdminApiService.getPayouts();
      if (!mounted) return;
      setState(() => _payouts = data);
    } catch (_) {
      // The payments table is the main thing on this screen; a failed
      // settlement query should not take it down with it.
      if (mounted) setState(() => _payouts = null);
    }
  }

  Future<void> _load() async {
    final bookingId = widget.booking['id']?.toString();
    if (bookingId == null || bookingId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'This booking has no id, so its payments cannot be loaded.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminApiService.getPaymentsForBooking(bookingId);
      if (!mounted) return;
      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final ref = b['bookingRef']?.toString() ?? '-';

    return AlertDialog(
      backgroundColor: AdminColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Payments — $ref',
          style: const TextStyle(
              color: AdminColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 560,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Guest', (b['user']?['name'] ?? '-').toString()),
                _detailRow('Email', (b['user']?['email'] ?? '-').toString()),
                _detailRow('Booking total', _money(b['totalPriceEgp'])),
                _detailRow('Commission', _money(b['commissionAmount'])),
                _detailRow('Discount', _money(b['discountAmount'])),
                _detailRow('Payment status',
                    _statusLabel((b['paymentStatus'] ?? '').toString())),
                _detailRow('Booking status',
                    _statusLabel((b['bookingStatus'] ?? '').toString())),
                _detailRow('Booked on', _dateTimeLabel(b['createdAt'])),
                const Divider(color: AdminColors.border),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'PAYMENT RECORDS',
                    style: TextStyle(
                        color: AdminColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6),
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AdminColors.primary),
                    ),
                  )
                else if (_error != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!,
                          style: const TextStyle(
                              color: AdminColors.error, fontSize: 12)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  )
                else if (_payments.isEmpty)
                  const Text(
                    'No payment records for this booking. The customer never '
                    'started a payment, so nothing was ever charged.',
                    style:
                        TextStyle(color: AdminColors.textMuted, fontSize: 12),
                  )
                else
                  ..._payments.map((raw) {
                    final p = Map<String, dynamic>.from(raw as Map);
                    return _PaymentCard(
                      payment: p,
                      onRefund: () {
                        Navigator.pop(context);
                        widget.onRefund(p);
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close',
              style: TextStyle(color: AdminColors.primary)),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onRefund;

  const _PaymentCard({required this.payment, required this.onRefund});

  @override
  Widget build(BuildContext context) {
    final status = (payment['status'] ?? 'pending').toString();
    final currency = (payment['currencyCharged'] ?? 'EGP').toString();
    final charged = payment['amountCharged'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _money(payment['amountEgp']),
                style: const TextStyle(
                    color: AdminColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              _chip(_statusLabel(status), _txnStatusColor(status)),
            ],
          ),
          const SizedBox(height: 8),
          _detailRow('Charged',
              charged == null
                  ? '-'
                  : '${NumberFormat('#,##0.00').format(asDouble(charged))} $currency'),
          _detailRow(
              'Method', (payment['method'] ?? '-').toString().toUpperCase()),
          _detailRow(
              'Gateway', (payment['gateway'] ?? '-').toString().toUpperCase()),
          _detailRow('Transaction',
              (payment['gatewayTransactionId'] ?? '-').toString()),
          _detailRow('Created', _dateTimeLabel(payment['createdAt'])),
          _detailRow('Paid at', _dateTimeLabel(payment['paidAt'])),
          _detailRow('Refunded at', _dateTimeLabel(payment['refundedAt'])),
          _detailRow('Payment id', (payment['id'] ?? '-').toString()),
          if (status == 'success')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRefund,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Refund this payment'),
                style: TextButton.styleFrom(
                    foregroundColor: AdminColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
