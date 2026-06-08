import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/data/seller_auth_token_storage.dart';
import '../../auth/widgets/auth_components.dart';
import 'seller_menu_screen.dart';

class BusinessHoursScreen extends StatefulWidget {
  const BusinessHoursScreen({
    required this.authApi,
    required this.tokenStorage,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  final List<_EditableBusinessDay> _days = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBusinessHours());
  }

  Future<void> _loadBusinessHours() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();
      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final hours = await widget.authApi.fetchBusinessHours(
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() => _applyHours(hours));
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to load business hours: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyHours(List<SellerBusinessHour> hours) {
    final sorted = [...hours]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    _days
      ..clear()
      ..addAll(sorted.map(_EditableBusinessDay.fromApi));
  }

  Future<void> _saveBusinessHours() async {
    if (_saving || _loading) return;

    final token = await widget.tokenStorage.loadToken();
    final tokenType = await widget.tokenStorage.loadTokenType();
    if (token == null || token.trim().isEmpty) {
      _showMessage('Authentication failed. Login again.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await widget.authApi.updateBusinessHours(
        SellerBusinessHoursUpdateRequest(
          businessHours: _days.map((day) => day.toApi()).toList(growable: false),
        ),
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      _showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Business hours updated successfully.',
      );
      Navigator.of(context).pop(true);
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to save business hours: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({
    required bool isOpening,
    required _EditableBusinessDay day,
  }) async {
    if (day.isClosed || day.is24Hours) return;

    final initial = isOpening ? day.openingTime : day.closingTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isOpening) {
        day.openingTime = picked;
        if (!_isAfter(picked, day.closingTime)) {
          day.closingTime = _nextValidCloseTime(picked);
        }
      } else {
        if (!_isAfter(day.openingTime, picked)) {
          _showMessage('Close time must be after opening time.', error: true);
          return;
        }
        day.closingTime = picked;
      }
    });
  }

  void _showMessage(String message, {bool error = false}) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? palette.error : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    BackTextButton(onPressed: () => Navigator.maybePop(context)),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving || _loading ? null : _saveBusinessHours,
                      child: _saving
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.greenDark,
                                ),
                              ),
                            )
                          : Text(
                              'Save',
                              style: TextStyle(
                                color: palette.greenDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading && _days.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(color: palette.green),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        children: [
                          Text(
                            'Business Hours',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set when your restaurant accepts orders each day.',
                            style: TextStyle(
                              color: palette.mutedText,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SellerCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SellerIconBadge(
                                  size: 44,
                                  background:
                                      palette.softGreen.withValues(alpha: 0.9),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    color: palette.greenDark,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Weekly schedule',
                                        style: TextStyle(
                                          color: palette.text,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SellerMutedText(
                                        'Customers only see your store when it is open.',
                                        fontSize: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(_days.length, (index) {
                            final day = _days[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _days.length - 1 ? 0 : 10,
                              ),
                              child: _BusinessDayCard(
                                day: day,
                                onClosedChanged: (value) {
                                  setState(() => day.isClosed = value);
                                },
                                on24HoursChanged: (value) {
                                  setState(() => day.is24Hours = value);
                                },
                                onPickOpening: () => _pickTime(
                                  isOpening: true,
                                  day: day,
                                ),
                                onPickClosing: () => _pickTime(
                                  isOpening: false,
                                  day: day,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableBusinessDay {
  _EditableBusinessDay({
    required this.dayOfWeek,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
    required this.is24Hours,
  });

  final int dayOfWeek;
  TimeOfDay openingTime;
  TimeOfDay closingTime;
  bool isClosed;
  bool is24Hours;

  factory _EditableBusinessDay.fromApi(SellerBusinessHour hour) {
    return _EditableBusinessDay(
      dayOfWeek: hour.dayOfWeek,
      openingTime:
          _parseBusinessTime(hour.openingTime) ?? const TimeOfDay(hour: 9, minute: 0),
      closingTime:
          _parseBusinessTime(hour.closingTime) ?? const TimeOfDay(hour: 23, minute: 0),
      isClosed: hour.isClosed,
      is24Hours: hour.is24Hours,
    );
  }

  SellerBusinessHour toApi() {
    return SellerBusinessHour(
      dayOfWeek: dayOfWeek,
      openingTime: _formatApiBusinessTime(openingTime),
      closingTime: _formatApiBusinessTime(closingTime),
      isClosed: isClosed,
      is24Hours: is24Hours,
    );
  }
}

class _BusinessDayCard extends StatelessWidget {
  const _BusinessDayCard({
    required this.day,
    required this.onClosedChanged,
    required this.on24HoursChanged,
    required this.onPickOpening,
    required this.onPickClosing,
  });

  final _EditableBusinessDay day;
  final ValueChanged<bool> onClosedChanged;
  final ValueChanged<bool> on24HoursChanged;
  final VoidCallback onPickOpening;
  final VoidCallback onPickClosing;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final disabled = day.isClosed || day.is24Hours;

    return SellerCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _businessDayLabel(day.dayOfWeek),
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _BusinessHourChip(
                label: 'Closed',
                selected: day.isClosed,
                onTap: () => onClosedChanged(!day.isClosed),
                palette: palette,
              ),
              const SizedBox(width: 6),
              _BusinessHourChip(
                label: '24h',
                selected: day.is24Hours,
                onTap: () => on24HoursChanged(!day.is24Hours),
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (day.isClosed)
            SellerMutedText('Closed all day', fontSize: 13)
          else if (day.is24Hours)
            Text(
              'Open 24 hours',
              style: TextStyle(
                color: palette.greenDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _BusinessTimeTile(
                    label: 'Opens',
                    value: _formatDisplayBusinessTime(day.openingTime),
                    enabled: !disabled,
                    onTap: onPickOpening,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BusinessTimeTile(
                    label: 'Closes',
                    value: _formatDisplayBusinessTime(day.closingTime),
                    enabled: !disabled,
                    onTap: onPickClosing,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BusinessHourChip extends StatelessWidget {
  const _BusinessHourChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AuthPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? palette.greenDark
          : palette.fieldFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? palette.greenDark : palette.fieldBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : palette.text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessTimeTile extends StatelessWidget {
  const _BusinessTimeTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: palette.fieldFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: enabled ? palette.text : palette.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _businessDayLabel(int dayOfWeek) {
  const labels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final index = (dayOfWeek - 1).clamp(0, 6);
  return labels[index];
}

TimeOfDay? _parseBusinessTime(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final twentyFourHour = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
  if (twentyFourHour != null) {
    final hour = int.tryParse(twentyFourHour.group(1)!);
    final minute = int.tryParse(twentyFourHour.group(2)!);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  final twelveHour = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (twelveHour == null) return null;

  final hour = int.tryParse(twelveHour.group(1)!);
  final minute = int.tryParse(twelveHour.group(2)!);
  final period = twelveHour.group(3)!.toUpperCase();
  if (hour == null || minute == null) return null;

  final normalizedHour = switch (period) {
    'AM' => hour == 12 ? 0 : hour,
    'PM' => hour == 12 ? 12 : hour + 12,
    _ => hour,
  };
  return TimeOfDay(hour: normalizedHour, minute: minute);
}

String _formatDisplayBusinessTime(TimeOfDay time) {
  final period = time.hour >= 12 ? 'PM' : 'AM';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
}

String _formatApiBusinessTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

bool _isAfter(TimeOfDay start, TimeOfDay end) {
  return _minutesOfDay(end) > _minutesOfDay(start);
}

TimeOfDay _nextValidCloseTime(TimeOfDay openTime) {
  final nextMinutes = (_minutesOfDay(openTime) + 60).clamp(0, 23 * 60 + 59);
  return TimeOfDay(hour: nextMinutes ~/ 60, minute: nextMinutes % 60);
}

int _minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

String summarizeBusinessHours(List<SellerBusinessHour> hours) {
  if (hours.isEmpty) return 'Schedule not set';

  final openDays = hours.where((hour) => !hour.isClosed).length;
  if (openDays == 0) return 'Currently closed all week';

  final today = DateTime.now().weekday;
  SellerBusinessHour? todayHour;
  for (final hour in hours) {
    if (hour.dayOfWeek == today) {
      todayHour = hour;
      break;
    }
  }
  if (todayHour != null) {
    if (todayHour.isClosed) return 'Closed today · $openDays days open';
    if (todayHour.is24Hours) return 'Open 24h today · $openDays days/week';
    final open = _formatDisplayBusinessTime(
      _parseBusinessTime(todayHour.openingTime) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    final close = _formatDisplayBusinessTime(
      _parseBusinessTime(todayHour.closingTime) ??
          const TimeOfDay(hour: 23, minute: 0),
    );
    return 'Today $open – $close · $openDays days/week';
  }

  return '$openDays days open per week';
}
