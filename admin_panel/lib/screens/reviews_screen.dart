import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../utils/num_parse.dart';
import '../widgets/admin_form.dart';

/// Read-only view of customer reviews, optionally narrowed to one operator.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<dynamic> _reviews = [];
  List<dynamic> _operators = [];
  bool _isLoading = true;
  String? _error;

  /// null means "all operators".
  String? _operatorFilter;

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
      // The operator list only powers the filter and the name lookup, so a
      // failure there must not hide the reviews themselves.
      if (_operators.isEmpty) {
        try {
          _operators = await AdminApiService.getOperators();
        } catch (e) {
          debugPrint('Could not load operators for the review filter: $e');
        }
      }
      final data = await AdminApiService.getReviews(operatorId: _operatorFilter);
      if (!mounted) return;
      setState(() {
        _reviews = data;
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

  /// GET /reviews only joins the `user` relation, so the operator arrives as a
  /// bare `operatorId` and has to be resolved against the operator list.
  String _operatorName(Map<String, dynamic> review) {
    final nested = review['operator']?['nameEn'];
    if (nested != null && nested.toString().trim().isNotEmpty) {
      return nested.toString();
    }
    final id = review['operatorId']?.toString();
    if (id == null || id.isEmpty) return '-';
    for (final raw in _operators) {
      final o = raw as Map;
      if (o['id']?.toString() == id) {
        final name = o['nameEn'] ?? o['nameAr'] ?? o['name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString();
        }
      }
    }
    return '-';
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    return DateFormat('d MMM yyyy').format(parsed.toLocal());
  }

  /// `rating` is an integer column, but Postgres/TypeORM can hand numerics back
  /// as strings, so it goes through asDouble like every other numeric field.
  Widget _stars(dynamic rawRating) {
    final rating = asDouble(rawRating);
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: i <= filled ? AdminColors.primary : AdminColors.border,
          ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AdminColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Reviews',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${_reviews.length} published reviews',
                    style: const TextStyle(
                        color: AdminColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: AdminDropdown(
                      label: 'Operator',
                      value: _operatorFilter ?? 'all',
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('All operators'),
                        ),
                        ..._operators.map((raw) {
                          final o = raw as Map;
                          final name = o['nameEn'] ?? o['nameAr'] ?? 'Unnamed';
                          return DropdownMenuItem<String>(
                            value: o['id']?.toString(),
                            child: Text(name.toString(),
                                overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _operatorFilter = (v == null || v == 'all') ? null : v;
                        });
                        _load();
                      },
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
            empty: _reviews.isEmpty,
            emptyMessage: _operatorFilter == null
                ? 'No reviews yet.'
                : 'No reviews for this operator.',
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
                    DataColumn(label: Text('RATING')),
                    DataColumn(label: Text('COMMENT')),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('OPERATOR')),
                    DataColumn(label: Text('DATE')),
                  ],
                  rows: _reviews.map<DataRow>((raw) {
                    final r = Map<String, dynamic>.from(raw as Map);
                    final comment = r['comment']?.toString().trim() ?? '';
                    return DataRow(cells: [
                      DataCell(_stars(r['rating'])),
                      DataCell(SizedBox(
                        width: 360,
                        child: Text(
                          comment.isEmpty ? 'No comment' : comment,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: comment.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: comment.isEmpty
                                ? AdminColors.textMuted
                                : AdminColors.textPrimary,
                          ),
                        ),
                      )),
                      DataCell(Text(
                        r['user']?['name'] ?? r['user']?['email'] ?? '-',
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        _operatorName(r),
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        _formatDate(r['createdAt']),
                        style: const TextStyle(
                            fontSize: 12, color: AdminColors.textSecondary),
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
