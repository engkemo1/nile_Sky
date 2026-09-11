import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/flight.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/date_helper.dart';
import 'booking_confirmation_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final FlightModel flight;

  const BookingFlowScreen({super.key, required this.flight});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0; // 0: Trip & Passenger, 1: Payment & Confirm
  int _guestCount = 2;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedHotel = 'Steigenberger Nile Palace';
  final _nameController = TextEditingController(text: 'John Smith');
  final _phoneController = TextEditingController(text: '+20 101 234 5678');
  final _specialRequestsController = TextEditingController();
  final _couponController = TextEditingController(text: 'WELCOME10');
  double _discountPercent = 0.10;
  String? _couponStatusText;
  bool _isProcessing = false;
  String _paymentMethod = 'card';

  final List<String> _popularHotels = [
    'Steigenberger Nile Palace',
    'Hilton Luxor Resort & Spa',
    'Sofitel Winter Palace Luxor',
    'Sonesta St. George Hotel',
    'Marriott Luxor Resort',
    'MS Nile Goddess Cruise (Dock 4)',
    'MS Mayfair Nile Cruise',
    'Other / Custom Address',
  ];

  @override
  void initState() {
    super.initState();
    _couponStatusText = '✅ 10% Discount Applied!';
    if (widget.flight.flightDate.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.flight.flightDate);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await DateHelper.pickFlightDate(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _couponStatusText = 'Validating coupon...';
    });

    try {
      final res = await ApiService.validateCoupon(code);
      if (res != null && (res['valid'] == true || res['isValid'] == true)) {
        final val = (res['discountValue'] ?? res['discount'] ?? 10).toDouble();
        final type = res['type'] ?? res['discountType'] ?? 'percentage';
        setState(() {
          _discountPercent = type == 'percentage' ? (val / 100.0) : 0.10;
          _couponStatusText = '✅ $code: ${type == 'percentage' ? "${val.toInt()}%" : "${val.toInt()} EGP"} Discount Applied!';
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _discountPercent = 0.0;
      _couponStatusText = context.tr('invalidCoupon');
    });
  }

  Future<void> _completeBooking() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final booking = await ApiService.createBooking(
      flightId: widget.flight.id,
      guestCount: _guestCount,
      pickupHotelName: _selectedHotel,
      couponCode: _discountPercent > 0 ? _couponController.text.trim().toUpperCase() : null,
      specialRequests: _specialRequestsController.text.trim().isNotEmpty
          ? _specialRequestsController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            booking: booking,
            flight: widget.flight,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.flight.priceEgp * _guestCount;
    final discount = subtotal * _discountPercent;
    final total = subtotal - discount;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentStep == 0 ? context.tr('step1Title') : context.tr('step2Title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Progress Indicator
                _buildStepProgressBar(),
                const SizedBox(height: 20),

                // Flight Mini Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.flight.coverPhotoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.flight.packageName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NileSky Fleet • ${widget.flight.departureTime} AM Takeoff',
                              style: const TextStyle(color: AppColors.secondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_currentStep == 0) ...[
                  // ================= STEP 1: TRIP & PASSENGERS =================
                  // Flight Date Selector
                  Text(
                    context.tr('flightDate'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primaryDark, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateHelper.formatFlightDate(context, DateHelper.toApiDateString(_selectedDate)),
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Guest Count Stepper
                  Text(
                    context.tr('guestsCount'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '$_guestCount ${context.tr('persons')}',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_guestCount > 1) setState(() => _guestCount--);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                if (_guestCount < widget.flight.remainingSeats) {
                                  setState(() => _guestCount++);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldenGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add, size: 16, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hotel Pickup Location Dropdown
                  Text(
                    context.tr('pickupPoint'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedHotel,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                        items: _popularHotels.map((hotel) {
                          return DropdownMenuItem(
                            value: hotel,
                            child: Row(
                              children: [
                                const Icon(Icons.hotel, color: AppColors.primaryDark, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(hotel, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedHotel = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lead Passenger Contact Name
                  Text(
                    context.tr('leadPassengerName'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                      hintText: 'Full Name as in Passport',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp / Phone Number
                  Text(
                    context.tr('whatsappNumber'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                      hintText: '+20 100 000 0000',
                    ),
                  ),
                ] else ...[
                  // ================= STEP 2: PAYMENT & CONFIRMATION =================
                  // Promo Coupon Code
                  Text(
                    context.tr('promoCode'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.local_offer_outlined, color: AppColors.primaryDark),
                            hintText: 'WELCOME10',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        ),
                        child: Text(context.tr('apply')),
                      ),
                    ],
                  ),
                  if (_couponStatusText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _couponStatusText!,
                      style: TextStyle(
                        color: _discountPercent > 0 ? AppColors.success : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Payment Method Selector
                  Text(
                    context.tr('paymentMethod'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodTile('card', 'Credit / Debit Card (Visa, MC)', Icons.credit_card),
                  const SizedBox(height: 8),
                  _buildPaymentMethodTile('apple', 'Apple Pay / Google Pay', Icons.apple),
                  const SizedBox(height: 8),
                  _buildPaymentMethodTile('cash', 'Cash Upon Hotel Pickup (EGP/USD/EUR)', Icons.payments_outlined),
                  const SizedBox(height: 20),

                  // Price Breakdown Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow('${widget.flight.packageName} (x$_guestCount)', ApiService.formatPrice(subtotal)),
                        if (_discountPercent > 0) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow(
                            'Promo Discount (10%)',
                            '-${ApiService.formatPrice(discount)}',
                            valueColor: AppColors.success,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildPriceRow('VIP Pickup & Boat Crossing', 'Included', valueColor: AppColors.success),
                        const SizedBox(height: 8),
                        _buildPriceRow('Aviation Taxes & Insurance', 'Included', valueColor: AppColors.success),
                        const Divider(color: AppColors.border, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('totalDue'),
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              ApiService.formatPrice(total),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep == 1) ...[
                      OutlinedButton(
                        onPressed: () => setState(() => _currentStep = 0),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  if (_currentStep == 0) {
                                    setState(() => _currentStep = 1);
                                  } else {
                                    _completeBooking();
                                  }
                                },
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                )
                              : Text(
                                  _currentStep == 0
                                      ? '${context.tr('continueToPayment')} • ${ApiService.formatPrice(total)}'
                                      : context.tr('confirmBookingBtn'),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Row(
      children: [
        _buildStepBadge('1', context.tr('step1'), _currentStep >= 0),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1 ? AppColors.primary : AppColors.border,
          ),
        ),
        _buildStepBadge('2', context.tr('step2'), _currentStep >= 1),
      ],
    );
  }

  Widget _buildStepBadge(String number, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.goldenGradient : null,
            color: isActive ? null : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.black : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String id, String label, IconData icon) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryDark : AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryDark : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
