import 'package:flutter/material.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_dashboard_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_menu_screen.dart';

import '../../../theme/app_theme.dart';

class SellerDashboardHome extends StatelessWidget {
  const SellerDashboardHome({
    required this.restaurantName,
    required this.initials,
    this.logoUrl,
    super.key,
  });

  final String restaurantName;
  final String initials;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SellerWorkScaffold(
      title: '$restaurantName 🌿',
      subtitle: '${_dashboardGreeting()},',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SellerHeaderIcon(Icons.notifications_rounded),
          const SizedBox(width: 12),
          _RestaurantHeaderLogo(
            logoUrl: logoUrl,
            initials: initials,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellerEntrance(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth < 360 ? 8.0 : 12.0;

                return Row(
                  children: [
                    const Expanded(
                      child: _MetricCard(
                        icon: '📦',
                        value: '47',
                        label: 'Orders Today',
                        accent: Color(0xFF10B981),
                        trend: '+12%',
                      ),
                    ),
                    SizedBox(width: gap),
                    const Expanded(
                      child: _MetricCard(
                        icon: '💰',
                        value: r'$1,284',
                        label: 'Revenue',
                        accent: Color(0xFF3B82F6),
                        trend: '+18%',
                      ),
                    ),
                    SizedBox(width: gap),
                    const Expanded(
                      child: _MetricCard(
                        icon: '⭐',
                        value: '4.8',
                        label: 'Rating',
                        accent: Color(0xFFFF9F0A),
                        trend: 'Top',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          SellerEntrance(
            delay: const Duration(milliseconds: 70),
            child: SellerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SellerSectionTitle('Order Status'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _StatusPill(
                        icon: '⌛',
                        label: 'Pending 5',
                        color: Color(0xFFFF9F0A),
                        background: Color(0xFFFFF1D8),
                      ),
                      _StatusPill(
                        icon: '🔥',
                        label: 'Preparing 8',
                        color: Color(0xFF4C8DFF),
                        background: Color(0xFFE6F0FF),
                      ),
                      _StatusPill(
                        icon: '✓',
                        label: 'Done 32',
                        color: Color(0xFF069464),
                        background: Color(0xFFDDF7EF),
                      ),
                      _StatusPill(
                        icon: '×',
                        label: 'Cancelled 2',
                        color: Color(0xFFFF4338),
                        background: Color(0xFFFFE2E4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SellerEntrance(
            delay: const Duration(milliseconds: 120),
            child: SellerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: SellerSectionTitle('Weekly Revenue')),
                      Text(
                        '+18% ↑',
                        style: TextStyle(
                          color: palette.greenDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _WeeklyBars(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SellerEntrance(
            delay: Duration(milliseconds: 170),
            child: _PopularItemsCard(),
          ),
        ],
      ),
    );
  }
}

class _RestaurantHeaderLogo extends StatelessWidget {
  const _RestaurantHeaderLogo({
    required this.logoUrl,
    required this.initials,
  });

  final String? logoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final imageUrl = logoUrl;

    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.greenDark,
        shape: BoxShape.circle,
      ),
      child: imageUrl == null
          ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                );
              },
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.trend,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;
  final String trend;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SellerCard(
      highlight: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SellerIconBadge(
                size: 34,
                background: accent.withValues(alpha: 0.12),
                child: Text(icon, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: palette.text,
                fontSize: 18,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 11.5,
              height: 1.15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final String icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$icon  $label',
        style: TextStyle(
          color: color,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [0.52, 0.72, 0.46, 0.92, 0.79, 1.0, 0.65];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final active = days[index] == 'Sat';
              final animatedValue = values[index] * value;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: animatedValue
                              .clamp(0.04, 1.0)
                              .toDouble(),
                          widthFactor: active ? 0.84 : 0.74,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: active
                                    ? [palette.green, palette.greenDark]
                                    : [
                                        const Color(0xFF10B981),
                                        const Color(0xFF078B63),
                                      ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: palette.greenDark.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      days[index],
                      style: TextStyle(
                        color: active ? palette.greenDark : palette.mutedText,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _PopularItemsCard extends StatelessWidget {
  const _PopularItemsCard();

  @override
  Widget build(BuildContext context) {
    return SellerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SellerSectionTitle('Popular Items'),
          SizedBox(height: 20),
          _PopularItem(
            emoji: '🍛',
            title: 'Butter Chicken',
            subtitle: '124 orders this week',
            price: r'$12.99',
          ),
          SellerDivider(),
          _PopularItem(
            emoji: '🥘',
            title: 'Paneer Tikka',
            subtitle: '98 orders this week',
            price: r'$10.49',
          ),
          SellerDivider(),
          _PopularItem(
            emoji: '🍚',
            title: 'Biryani Special',
            subtitle: '87 orders this week',
            price: r'$14.99',
          ),
        ],
      ),
    );
  }
}

class _PopularItem extends StatelessWidget {
  const _PopularItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String price;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.softGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              SellerMutedText(subtitle, fontSize: 12),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            color: palette.greenDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

String _dashboardGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
