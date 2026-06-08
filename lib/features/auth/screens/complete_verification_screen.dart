import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../seller/screens/seller_dashboard_screen.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';

class CompleteVerificationScreen extends StatefulWidget {
  const CompleteVerificationScreen({
    SellerAuthApi? authApi,
    SellerAuthTokenStorage? tokenStorage,
    this.message,
    this.restaurantName = 'Spice Garden',
    this.initials = 'RK',
    this.onLoggedOut,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       tokenStorage = tokenStorage ?? const SellerAuthTokenStorage();

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final String? message;
  final String restaurantName;
  final String initials;
  final VoidCallback? onLoggedOut;

  @override
  State<CompleteVerificationScreen> createState() =>
      _CompleteVerificationScreenState();
}

class _CompleteVerificationScreenState
    extends State<CompleteVerificationScreen> {
  String? _verificationMessage;
  String _verificationStatus = 'approved';
  SellerVerificationStatusResponse? _verificationStatusResponse;
  bool _loadingStatus = false;

  @override
  void initState() {
    super.initState();
    _verificationMessage = widget.message;
    _loadVerificationStatus();
  }

  void _openDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SellerDashboardScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
          restaurantName: widget.restaurantName,
          initials: widget.initials,
          onLoggedOut: widget.onLoggedOut,
        ),
      ),
    );
  }

  Future<void> _loadVerificationStatus() async {
    if (_loadingStatus) return;

    setState(() => _loadingStatus = true);
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final status = await widget.authApi.fetchVerificationStatus(
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() {
        _verificationStatusResponse = status;
        _verificationStatus = status.combinedStatusLabel;
        _verificationMessage = status.displayMessage;
      });
    } on SellerAuthException catch (error) {
      if (!mounted) return;
      setState(() => _verificationMessage = error.message);
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final verification = _verificationStatusResponse;
    final statusValue = verification?.status ?? _verificationStatus;
    final restaurantStatusValue = verification?.restaurantStatus;
    final tone = _VerificationTone.fromStatus(statusValue, palette);
    final restaurantTone = _VerificationTone.fromStatus(
      restaurantStatusValue,
      palette,
    );
    final faceMatch = verification?.faceMatch;
    final livenessCheck = verification?.livenessCheck;
    final faceTone = _VerificationTone.fromStatus(
      faceMatch?.status ?? statusValue,
      palette,
    );
    final livenessTone = _VerificationTone.fromStatus(
      livenessCheck?.status ?? (verification?.isApproved == true ? 'approved' : statusValue),
      palette,
    );
    final livenessScore = livenessCheck == null
        ? '✓'
        : livenessCheck.isApproved
        ? '✓'
        : livenessCheck.scoreLabel;

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: AuthEntrance(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Verification Status',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 22,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Identity & restaurant review progress',
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.softGreen.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        color: palette.greenDark,
                        height: 72,
                        width: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DualStatusCard(
                    diditStatus: verification?.status ?? statusValue,
                    restaurantStatus: restaurantStatusValue,
                    diditTone: tone,
                    restaurantTone: restaurantTone,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle('Timeline'),
                  const SizedBox(height: 14),
                  _VerificationTimeline(
                    response: verification,
                    tone: tone,
                    restaurantTone: restaurantTone,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle('Scores'),
                  const SizedBox(height: 12),
                  _ScoreCard(
                    scoreText: faceMatch?.scoreLabel ?? '-',
                    title: 'Face Match',
                    subtitle: faceMatch?.subtitle ?? 'Waiting for face match result',
                    accentColor: faceTone.color,
                    highlightedSubtitle: faceMatch != null,
                  ),
                  const SizedBox(height: 12),
                  _ScoreCard(
                    scoreText: livenessScore,
                    title: 'Liveness Check',
                    subtitle:
                        livenessCheck?.subtitle ?? 'Waiting for liveness result',
                    accentColor: livenessTone.color,
                    highlightedSubtitle: livenessCheck != null,
                  ),
                  const SizedBox(height: 12),
                  _RiskScoreCard(response: verification, tone: tone),
                  const SizedBox(height: 28),
                  _SlideToDashboardButton(onCompleted: _openDashboard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationTone {
  const _VerificationTone({
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final Color color;
  final Color softColor;
  final IconData icon;

  static _VerificationTone fromStatus(String? status, AuthPalette palette) {
    final value = status?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
    if (value == 'failed' ||
        value == 'rejected' ||
        value == 'declined' ||
        value == 'denied' ||
        value == 'expired' ||
        value == 'cancelled' ||
        value == 'canceled') {
      return const _VerificationTone(
        color: Color(0xFFFF3B30),
        softColor: Color(0xFFFFE8E6),
        icon: Icons.close_rounded,
      );
    }

    if (value == 'in_review' ||
        value == 'under_review' ||
        value == 'pending' ||
        value == 'pending_review' ||
        value.isEmpty) {
      return const _VerificationTone(
        color: Color(0xFFFF9F0A),
        softColor: Color(0xFFFFF3D8),
        icon: Icons.hourglass_top_rounded,
      );
    }

    return _VerificationTone(
      color: palette.greenDark,
      softColor: palette.softGreen,
      icon: Icons.check_rounded,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.loading,
    required this.tone,
    this.message,
  });

  final String status;
  final bool loading;
  final _VerificationTone tone;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final subtitle = message?.trim().isNotEmpty == true
        ? message!.trim()
        : 'Your restaurant is verified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: palette.fieldFill.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.fieldBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.softColor,
              shape: BoxShape.circle,
            ),
            child: loading
                ? SizedBox.square(
                    dimension: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tone.color,
                      ),
                    ),
                  )
                : Icon(tone.icon, color: tone.color, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tone.color,
              fontSize: 18,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DualStatusCard extends StatelessWidget {
  const _DualStatusCard({
    required this.diditStatus,
    required this.restaurantStatus,
    required this.diditTone,
    required this.restaurantTone,
  });

  final String? diditStatus;
  final String? restaurantStatus;
  final _VerificationTone diditTone;
  final _VerificationTone restaurantTone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusPill(
            title: 'Didit',
            status: _statusLabelFrom(diditStatus),
            tone: diditTone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusPill(
            title: 'Restaurant',
            status: _statusLabelFrom(restaurantStatus),
            tone: restaurantTone,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.title,
    required this.status,
    required this.tone,
  });

  final String title;
  final String status;
  final _VerificationTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.softColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.color,
              shape: BoxShape.circle,
            ),
            child: Icon(tone.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tone.color,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideToDashboardButton extends StatefulWidget {
  const _SlideToDashboardButton({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<_SlideToDashboardButton> createState() =>
      _SlideToDashboardButtonState();
}

class _SlideToDashboardButtonState extends State<_SlideToDashboardButton> {
  double _progress = 0;
  bool _completed = false;

  void _updateProgress(double delta, double width) {
    if (_completed) return;
    final travelWidth = (width - 58).clamp(1.0, double.infinity).toDouble();
    setState(() {
      _progress = (_progress + delta / travelWidth)
          .clamp(0.0, 1.0)
          .toDouble();
    });
  }

  void _finishSlide() {
    if (_completed) return;
    if (_progress >= 0.86) {
      setState(() {
        _completed = true;
        _progress = 1;
      });
      widget.onCompleted();
      return;
    }

    setState(() => _progress = 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final knobTravel = (width - 58).clamp(0.0, double.infinity).toDouble();

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            _updateProgress(details.delta.dx, width);
          },
          onHorizontalDragEnd: (_) => _finishSlide(),
          child: Container(
            height: 58,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: palette.greenDark,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: palette.greenDark.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - _progress * 0.55).clamp(0.45, 1),
                  child: const Text(
                    'Slide to Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Positioned(
                  left: knobTravel * _progress,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: palette.greenDark,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      style: TextStyle(
        color: palette.text.withValues(alpha: 0.82),
        fontSize: 14,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({
    required this.response,
    required this.tone,
    required this.restaurantTone,
  });

  final SellerVerificationStatusResponse? response;
  final _VerificationTone tone;
  final _VerificationTone restaurantTone;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final submittedTime = _formatTimelineDate(response?.submittedAt);
    final isApproved = response?.isApproved == true;
    final isFailed = response?.isFailed == true;
    final isRestaurantApproved = response?.isRestaurantApproved == true;
    final isRestaurantFailed = response?.isRestaurantFailed == true;
    final statusLabel = response?.statusLabel ?? 'Pending Review';
    final restaurantStatusLabel =
        response?.restaurantStatusLabel ?? 'Pending Review';

    return Column(
      children: [
        _TimelineItem(
          title: 'Documents Submitted',
          time: submittedTime,
          first: true,
          dotColor: palette.green,
        ),
        _TimelineItem(
          title: isFailed
              ? 'Identity Needs Review'
              : isApproved
              ? 'Identity Verified'
              : 'Identity In Review',
          time: isApproved || isFailed ? submittedTime : statusLabel,
          dotColor: tone.color,
        ),
        _TimelineItem(
          title: isApproved ? 'Documents Verified' : 'Documents Pending',
          time: isApproved ? submittedTime : 'Waiting for approval',
          dotColor: isApproved ? palette.green : palette.fieldBorder,
          muted: !isApproved,
        ),
        _TimelineItem(
          title: isRestaurantFailed
              ? 'Restaurant Needs Review'
              : isRestaurantApproved
              ? 'Restaurant Approved'
              : 'Restaurant Review',
          time: isRestaurantApproved
              ? submittedTime
              : isRestaurantFailed
              ? restaurantStatusLabel
              : 'Restaurant status: $restaurantStatusLabel',
          dotColor: isRestaurantApproved
              ? palette.green
              : isRestaurantFailed
              ? restaurantTone.color
              : palette.fieldBorder,
          muted: !isRestaurantApproved && !isRestaurantFailed,
        ),
        _TimelineItem(
          title: isApproved && isRestaurantApproved
              ? 'Dashboard Ready'
              : 'Dashboard Access',
          time: isApproved && isRestaurantApproved
              ? 'Ready to continue'
              : 'You can continue while review is pending',
          dotColor: isApproved
              ? palette.green
              : isFailed
              ? tone.color
              : palette.fieldBorder,
          muted: !isApproved && !isFailed,
          last: true,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.time,
    required this.dotColor,
    this.first = false,
    this.last = false,
    this.muted = false,
  });

  final String title;
  final String time;
  final Color dotColor;
  final bool first;
  final bool last;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: first ? 18 : 0,
                  bottom: last ? 26 : 0,
                  child: Container(width: 2, color: palette.fieldBorder),
                ),
                Container(
                  width: 21,
                  height: 21,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: muted ? palette.mutedText : palette.text,
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.scoreText,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.highlightedSubtitle = false,
  });

  final String scoreText;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool highlightedSubtitle;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return _ResultCard(
      child: Row(
        children: [
          _ScoreCircle(text: scoreText, accentColor: accentColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: highlightedSubtitle ? accentColor : palette.mutedText,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({required this.text, required this.accentColor});

  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor, width: 4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RiskScoreCard extends StatelessWidget {
  const _RiskScoreCard({required this.response, required this.tone});

  final SellerVerificationStatusResponse? response;
  final _VerificationTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final score = response?.faceMatch?.score;
    final activeSegments = response == null
        ? 1
        : response!.isApproved
        ? 2
        : response!.isFailed
        ? 7
        : 4;
    final label = response == null
        ? 'Pending'
        : response!.isApproved
        ? 'Low Risk'
        : response!.isFailed
        ? 'High Risk'
        : 'In Review';
    final scoreText = score == null
        ? 'Status: ${response?.statusLabel ?? 'Pending'}'
        : 'Score: ${score.toStringAsFixed(2)}';

    return _ResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Risk Score',
            style: TextStyle(
              color: palette.text,
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          _RiskBar(
            activeSegments: activeSegments,
            totalSegments: 8,
            accentColor: tone.color,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: tone.color,
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                scoreText,
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  const _RiskBar({
    required this.activeSegments,
    required this.totalSegments,
    required this.accentColor,
  });

  final int activeSegments;
  final int totalSegments;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: List.generate(totalSegments, (index) {
        final active = index < activeSegments;
        return Expanded(
          child: Container(
            height: 11,
            margin: EdgeInsets.only(right: index == totalSegments - 1 ? 0 : 5),
            decoration: BoxDecoration(
              color: active ? accentColor : palette.fieldBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.fieldFill.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.fieldBorder, width: 1.2),
      ),
      child: child,
    );
  }
}

String _formatTimelineDate(DateTime? value) {
  if (value == null) {
    return 'Waiting for submission';
  }

  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${months[local.month - 1]} ${local.day}, ${local.year} - $hour:$minute $period';
}

String _statusLabelFrom(String? status) {
  final normalized = status?.trim().replaceAll(RegExp(r'[_-]+'), ' ') ?? '';
  if (normalized.isEmpty) return 'Pending Review';

  return normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}
