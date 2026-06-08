import 'package:flutter/material.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_dashboard_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_menu_screen.dart';

import '../../../theme/app_theme.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return SellerWorkScaffold(
      title: 'Orders',
      subtitle: '13 active orders',
      trailing: const SellerHeaderIcon(Icons.notifications_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellerEntrance(
            child: SellerSegmentedControl(
              labels: const ['New (5)', 'Active (8)', 'Done', 'Cancelled'],
              selectedIndex: _segment,
              onChanged: (index) => setState(() => _segment = index),
            ),
          ),
          const SizedBox(height: 18),
          const SellerEntrance(
            delay: Duration(milliseconds: 70),
            child: _OrderCard(
              orderId: '#ORD-2847',
              customerInitials: 'AK',
              customerName: 'Amit Kumar',
              items: '2x Butter Chicken, 1x Naan, 1x Raita',
              note: 'Extra spicy, no onion',
              amount: r'$28.47',
              minutesAgo: '2 min ago',
              statusColor: Color(0xFFFF9F0A),
              showActions: true,
            ),
          ),
          const SizedBox(height: 14),
          const SellerEntrance(
            delay: Duration(milliseconds: 120),
            child: _OrderCard(
              orderId: '#ORD-2846',
              customerInitials: 'SP',
              customerName: 'Sneha Patel',
              items: '1x Paneer Tikka, 2x Biryani Special, 1x Mango Lassi',
              amount: r'$42.96',
              minutesAgo: '5 min ago',
              statusColor: Color(0xFFFF9F0A),
              showActions: true,
            ),
          ),
          const SizedBox(height: 14),
          const SellerEntrance(
            delay: Duration(milliseconds: 170),
            child: _OrderCard(
              orderId: '#ORD-2840',
              customerInitials: 'MR',
              customerName: 'Maya Reddy',
              items: '3x Tandoori Platter, 2x Garlic Naan',
              amount: r'$36.50',
              badge: 'Preparing',
              statusColor: Color(0xFF10B981),
              progress: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.customerInitials,
    required this.customerName,
    required this.items,
    required this.amount,
    required this.statusColor,
    this.note,
    this.minutesAgo,
    this.badge,
    this.showActions = false,
    this.progress,
  });

  final String orderId;
  final String customerInitials;
  final String customerName;
  final String items;
  final String amount;
  final Color statusColor;
  final String? note;
  final String? minutesAgo;
  final String? badge;
  final bool showActions;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.fieldBorder, width: 1.1),
        color: palette.fieldFill.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 5, color: statusColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          orderId,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 17,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (minutesAgo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF9F0A,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '⏱ $minutesAgo',
                            style: const TextStyle(
                              color: Color(0xFFFF9F0A),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: palette.softGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: palette.greenDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.greenDark,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          customerInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          customerName,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    items,
                    style: TextStyle(
                      color: palette.text.withValues(alpha: 0.78),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 7),
                    SellerMutedText('📝 $note', fontSize: 12),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          amount,
                          style: TextStyle(
                            color: palette.greenDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (showActions) ...[
                        _OrderActionButton(
                          label: 'Reject',
                          color: const Color(0xFFFF4338),
                          background: const Color(0xFFFFE1E4),
                        ),
                        const SizedBox(width: 10),
                        _OrderActionButton(
                          label: 'Accept',
                          color: Colors.white,
                          background: palette.greenDark,
                        ),
                      ] else
                        _OrderActionButton(
                          label: 'Mark Ready ✓',
                          color: Colors.white,
                          background: palette.greenDark,
                          width: 142,
                        ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress ?? 0),
                        duration: const Duration(milliseconds: 680),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: palette.fieldBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              palette.greenDark,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SellerMutedText('Est. 8 min remaining', fontSize: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({
    required this.label,
    required this.color,
    required this.background,
    this.width = 88,
  });

  final String label;
  final Color color;
  final Color background;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
