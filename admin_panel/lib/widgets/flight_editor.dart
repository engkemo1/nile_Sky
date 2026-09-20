import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../utils/num_parse.dart';
import 'admin_form.dart';
import 'media_manager.dart';

/// Add / edit dialog for a flight. Covers every field the backend accepts,
/// including photos and video, which had no UI at all before.
class FlightEditor extends StatefulWidget {
  /// null = creating a new flight.
  final Map<String, dynamic>? flight;
  final List<dynamic> operators;
  final List<dynamic> packages;
  final List<dynamic> balloons;
  final List<dynamic> pilots;
  final List<dynamic> drivers;

  const FlightEditor({
    super.key,
    required this.flight,
    required this.operators,
    required this.packages,
    required this.balloons,
    required this.pilots,
    this.drivers = const [],
  });

  @override
  State<FlightEditor> createState() => _FlightEditorState();
}

class _FlightEditorState extends State<FlightEditor> {
  late TextEditingController _numberCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _videoCtrl;
  late TextEditingController _launchSiteCtrl;
  late TextEditingController _launchLatCtrl;
  late TextEditingController _launchLngCtrl;
  late TextEditingController _landingSiteCtrl;
  late TextEditingController _landingLatCtrl;
  late TextEditingController _landingLngCtrl;
  late TextEditingController _altitudeCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _windCtrl;
  late TextEditingController _crewCtrl;

  String? _operatorId;
  String? _packageId;
  String? _balloonId;
  String? _pilotId;
  String? _chaseDriverId;
  String _status = 'scheduled';
  String _weather = 'favorable';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  List<String> _photos = [];

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.flight != null;

  static const _statuses = [
    'scheduled', 'boarding', 'in_flight', 'landed', 'completed', 'cancelled',
  ];
  // Must match WeatherStatus in flight.entity.ts exactly, or the save 400s.
  static const _weathers = ['favorable', 'uncertain', 'unfavorable'];

  @override
  void initState() {
    super.initState();
    final f = widget.flight;
    _numberCtrl = TextEditingController(text: f?['flightNumber']?.toString() ?? _suggestNumber());
    _timeCtrl = TextEditingController(text: f?['departureTime']?.toString() ?? '06:15:00');
    _capacityCtrl = TextEditingController(text: (f?['capacity'] ?? 16).toString());
    _priceCtrl = TextEditingController(
      text: f != null ? asDouble(f['priceEgp']).toStringAsFixed(2) : '9000',
    );
    _videoCtrl = TextEditingController(text: f?['videoUrl']?.toString() ?? '');
    _launchSiteCtrl = TextEditingController(text: f?['launchSite']?.toString() ?? '');
    _launchLatCtrl = TextEditingController(text: _num(f?['launchLat']));
    _launchLngCtrl = TextEditingController(text: _num(f?['launchLng']));
    _landingSiteCtrl = TextEditingController(text: f?['landingSite']?.toString() ?? '');
    _landingLatCtrl = TextEditingController(text: _num(f?['landingLat']));
    _landingLngCtrl = TextEditingController(text: _num(f?['landingLng']));
    _altitudeCtrl = TextEditingController(text: f?['maxAltitudeM']?.toString() ?? '');
    _durationCtrl = TextEditingController(text: f?['actualDurationMin']?.toString() ?? '');
    _windCtrl = TextEditingController(text: _num(f?['recordedWindKph']));
    _crewCtrl = TextEditingController(text: f?['groundCrew']?.toString() ?? '');
    _chaseDriverId = f?['chaseDriverId']?.toString();

    _operatorId = f?['operatorId']?.toString();
    _packageId = f?['packageId']?.toString();
    _balloonId = f?['balloonId']?.toString();
    _pilotId = f?['pilotId']?.toString();
    _status = f?['status']?.toString() ?? 'scheduled';
    _weather = f?['weatherStatus']?.toString() ?? 'favorable';

    final raw = f?['photos'];
    if (raw is List) _photos = raw.map((e) => e.toString()).toList();

    final d = f?['flightDate']?.toString();
    if (d != null && d.length >= 10) {
      _date = DateTime.tryParse(d.substring(0, 10)) ?? _date;
    }

    // Default the operator so a new flight is not missing a required field.
    if (_operatorId == null && widget.operators.isNotEmpty) {
      _operatorId = widget.operators.first['id']?.toString();
    }
    if (_packageId == null && widget.packages.isNotEmpty) {
      _packageId = widget.packages.first['id']?.toString();
    }
  }

  /// Postgres decimals arrive as padded strings ("25.7201000"); show them
  /// tidily and leave blanks blank.
  static String _num(dynamic v) {
    if (v == null) return '';
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    final s = d.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  String _suggestNumber() {
    final d = DateFormat('yyyyMMdd').format(DateTime.now().add(const Duration(days: 1)));
    return 'FL-$d-${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _timeCtrl.dispose();
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    _videoCtrl.dispose();
    _launchSiteCtrl.dispose();
    _launchLatCtrl.dispose();
    _launchLngCtrl.dispose();
    _landingSiteCtrl.dispose();
    _landingLatCtrl.dispose();
    _landingLngCtrl.dispose();
    _altitudeCtrl.dispose();
    _durationCtrl.dispose();
    _windCtrl.dispose();
    _crewCtrl.dispose();
    super.dispose();
  }

  /// Only the fields that belong to this operator, so the dropdowns cannot
  /// produce an invalid combination.
  List<dynamic> _forOperator(List<dynamic> all) {
    if (_operatorId == null) return all;
    final scoped = all.where((e) => e['operatorId']?.toString() == _operatorId).toList();
    return scoped.isEmpty ? all : scoped;
  }

  String? _validate() {
    if (_numberCtrl.text.trim().isEmpty) return 'Flight number is required.';
    if (_operatorId == null) return 'Choose an operator.';
    if (_packageId == null) return 'Choose a package.';
    if (!RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(_timeCtrl.text.trim())) {
      return 'Departure time must look like 06:15 or 06:15:00.';
    }
    final cap = int.tryParse(_capacityCtrl.text.trim());
    if (cap == null || cap < 1) return 'Capacity must be a whole number above 0.';
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price < 0) return 'Price must be a number.';
    return null;
  }

  /// Includes the key only when there is text; blank optional strings are
  /// rejected by @IsOptional() + @IsString().
  Map<String, dynamic> _text(String key, TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? const {} : {key: v};
  }

  /// Same for numbers — a blank field must be omitted, not sent as 0.
  Map<String, dynamic> _number(String key, TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return const {};
    final n = double.tryParse(v);
    return n == null ? const {} : {key: n};
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    var time = _timeCtrl.text.trim();
    if (time.length == 5) time = '$time:00';

    final body = <String, dynamic>{
      'flightNumber': _numberCtrl.text.trim(),
      'operatorId': _operatorId,
      'packageId': _packageId,
      'flightDate': DateFormat('yyyy-MM-dd').format(_date),
      'departureTime': time,
      'capacity': int.parse(_capacityCtrl.text.trim()),
      'priceEgp': double.parse(_priceCtrl.text.trim()),
      'status': _status,
      'weatherStatus': _weather,
      'photos': _photos,
      if (_balloonId != null) 'balloonId': _balloonId,
      if (_pilotId != null) 'pilotId': _pilotId,
      // Optional strings must be omitted when blank: @IsOptional() only skips
      // null/undefined, so '' would fail validation.
      if (_videoCtrl.text.trim().isNotEmpty) 'videoUrl': _videoCtrl.text.trim(),
      if (_chaseDriverId != null) 'chaseDriverId': _chaseDriverId,
      ..._text('launchSite', _launchSiteCtrl),
      ..._text('landingSite', _landingSiteCtrl),
      ..._text('groundCrew', _crewCtrl),
      ..._number('launchLat', _launchLatCtrl),
      ..._number('launchLng', _launchLngCtrl),
      ..._number('landingLat', _landingLatCtrl),
      ..._number('landingLng', _landingLngCtrl),
      ..._number('maxAltitudeM', _altitudeCtrl),
      ..._number('actualDurationMin', _durationCtrl),
      ..._number('recordedWindKph', _windCtrl),
    };

    try {
      if (_isEdit) {
        await AdminApiService.updateFlight(widget.flight!['id'].toString(), body);
      } else {
        await AdminApiService.createFlight(body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AdminColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: AdminColors.border, height: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balloons = _forOperator(widget.balloons);
    final pilots = _forOperator(widget.pilots);
    final packages = _forOperator(widget.packages);

    return AlertDialog(
      backgroundColor: AdminColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Edit ${widget.flight!['flightNumber']}' : 'Add Flight',
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.error),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AdminColors.error, fontSize: 12)),
                ),
              AdminTextField(label: 'Flight Number', controller: _numberCtrl),
              AdminDropdown(
                label: 'Operator',
                value: _operatorId,
                items: itemsFrom(widget.operators),
                onChanged: (v) => setState(() {
                  _operatorId = v;
                  // Scoped lists change, so clear picks that no longer belong.
                  _balloonId = null;
                  _pilotId = null;
                }),
              ),
              AdminDropdown(
                label: 'Package',
                value: _packageId,
                items: itemsFrom(packages),
                onChanged: (v) => setState(() => _packageId = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: InputDecorator(
                          decoration: adminInput('Flight Date'),
                          child: Text(
                            DateFormat('EEE, d MMM yyyy').format(_date),
                            style: const TextStyle(
                                color: AdminColors.textPrimary, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminTextField(
                      label: 'Departure Time',
                      controller: _timeCtrl,
                      hint: '06:15:00',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                      label: 'Capacity',
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminTextField(
                      label: 'Price (EGP)',
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              AdminDropdown(
                label: 'Balloon (optional)',
                value: _balloonId,
                items: itemsFrom(balloons),
                onChanged: (v) => setState(() => _balloonId = v),
              ),
              AdminDropdown(
                label: 'Pilot (optional)',
                value: _pilotId,
                items: itemsFrom(pilots),
                onChanged: (v) => setState(() => _pilotId = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminDropdown(
                      label: 'Status',
                      value: _status,
                      items: _statuses
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.replaceAll('_', ' ').toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminDropdown(
                      label: 'Weather',
                      value: _weather,
                      items: _weathers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _weather = v ?? _weather),
                    ),
                  ),
                ],
              ),
              _section('Launch & landing'),
              AdminTextField(
                label: 'Launch site',
                controller: _launchSiteCtrl,
                hint: 'e.g. Al Dabbaya launch field, West Bank',
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                      label: 'Launch latitude',
                      controller: _launchLatCtrl,
                      keyboardType: TextInputType.number,
                      hint: '25.7201',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminTextField(
                      label: 'Launch longitude',
                      controller: _launchLngCtrl,
                      keyboardType: TextInputType.number,
                      hint: '32.6100',
                    ),
                  ),
                ],
              ),
              AdminTextField(
                label: 'Landing site',
                controller: _landingSiteCtrl,
                hint: 'Filled in after the flight',
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                      label: 'Landing latitude',
                      controller: _landingLatCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminTextField(
                      label: 'Landing longitude',
                      controller: _landingLngCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              _section('Ground crew & chase vehicle'),
              AdminDropdown(
                label: 'Chase driver',
                value: _chaseDriverId,
                items: itemsFrom(_forOperator(widget.drivers),
                    labelKeys: const ['name']),
                onChanged: (v) => setState(() => _chaseDriverId = v),
              ),
              AdminTextField(
                label: 'Ground crew',
                controller: _crewCtrl,
                hint: 'e.g. Ahmed (crew chief), Mostafa, Sayed',
                maxLines: 2,
              ),

              _section('After the flight'),
              Row(
                children: [
                  Expanded(
                    child: AdminTextField(
                      label: 'Max altitude (m)',
                      controller: _altitudeCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminTextField(
                      label: 'Duration (min)',
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminTextField(
                      label: 'Wind (km/h)',
                      controller: _windCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              _section('Media'),
              MediaManager(
                urls: _photos,
                folder: 'flights',
                onChanged: (next) => setState(() => _photos = next),
              ),
              AdminTextField(
                label: 'Video URL (optional)',
                controller: _videoCtrl,
                hint: 'https://…',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AdminColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primary,
            foregroundColor: Colors.black,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
