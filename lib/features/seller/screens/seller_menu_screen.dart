import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/widgets/auth_components.dart';

class SellerMenuScreen extends StatefulWidget {
  const SellerMenuScreen({super.key});

  @override
  State<SellerMenuScreen> createState() => _SellerMenuScreenState();
}

class _SellerMenuScreenState extends State<SellerMenuScreen> {
  int _category = 0;
  final List<bool> _available = [true, true, true, false, true];

  @override
  Widget build(BuildContext context) {
    return SellerWorkScaffold(
      title: 'Menu',
      subtitle: '24 products · 6 categories',
      trailing: const SellerHeaderIcon(Icons.search_rounded),
      bottomPadding: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CategoryTile(
                  emoji: '🍛',
                  label: 'Mains',
                  selected: _category == 0,
                  onTap: () => setState(() => _category = 0),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CategoryTile(
                  emoji: '🥗',
                  label: 'Starters',
                  selected: _category == 1,
                  onTap: () => setState(() => _category = 1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CategoryTile(
                  emoji: '🍞',
                  label: 'Breads',
                  selected: _category == 2,
                  onTap: () => setState(() => _category = 2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CategoryTile(
                  emoji: '🍚',
                  label: 'Rice',
                  selected: _category == 3,
                  onTap: () => setState(() => _category = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SellerCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                _MenuProductRow(
                  emoji: '🍛',
                  title: 'Butter Chicken',
                  price: r'$12.99',
                  oldPrice: r'$15.99',
                  nonVeg: true,
                  available: _available[0],
                  onChanged: (value) => setState(() => _available[0] = value),
                ),
                const SellerDivider(),
                _MenuProductRow(
                  emoji: '🥘',
                  title: 'Paneer Tikka',
                  price: r'$10.49',
                  available: _available[1],
                  onChanged: (value) => setState(() => _available[1] = value),
                ),
                const SellerDivider(),
                _MenuProductRow(
                  emoji: '🍗',
                  title: 'Tandoori Chicken',
                  price: r'$13.99',
                  nonVeg: true,
                  available: _available[2],
                  onChanged: (value) => setState(() => _available[2] = value),
                ),
                const SellerDivider(),
                _MenuProductRow(
                  emoji: '🍲',
                  title: 'Dal Makhani',
                  price: r'$8.99',
                  available: _available[3],
                  onChanged: (value) => setState(() => _available[3] = value),
                ),
                const SellerDivider(),
                _MenuProductRow(
                  emoji: '🍖',
                  title: 'Lamb Rogan Josh',
                  price: r'$16.99',
                  nonVeg: true,
                  available: _available[4],
                  onChanged: (value) => setState(() => _available[4] = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SellerWorkScaffold extends StatelessWidget {
  const SellerWorkScaffold({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.horizontalPadding = 24,
    this.bottomPadding = 126,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final double horizontalPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return LightAuthTextureBackground(
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.025 : 0.08,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            28,
            horizontalPadding,
            bottomPadding,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  _SellerPageHeader(
                    title: title!,
                    subtitle: subtitle,
                    trailing: trailing,
                  ),
                  const SizedBox(height: 22),
                ] else ...[
                  SizedBox(
                    height: 28,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerPageHeader extends StatelessWidget {
  const _SellerPageHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 24,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                SellerMutedText(subtitle!, fontSize: 13),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 14),
          trailing!,
        ],
      ],
    );
  }
}

class SellerHeaderIcon extends StatelessWidget {
  const SellerHeaderIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: palette.fieldFill.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(color: palette.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: palette.text, size: 20),
    );
  }
}

class SellerIconBadge extends StatelessWidget {
  const SellerIconBadge({
    required this.child,
    this.size = 42,
    this.background,
    super.key,
  });

  final Widget child;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? palette.softGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.greenDark.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (background ?? palette.greenDark).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.softGreen : palette.fieldFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? palette.greenDark : palette.fieldBorder,
                width: selected ? 1.5 : 1.1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: palette.greenDark.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? palette.greenDark : palette.mutedText,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SellerCard extends StatelessWidget {
  const SellerCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlight = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.fieldFill.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? palette.greenDark.withValues(alpha: 0.22)
              : palette.fieldBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.045,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MenuProductRow extends StatelessWidget {
  const _MenuProductRow({
    required this.emoji,
    required this.title,
    required this.price,
    required this.available,
    required this.onChanged,
    this.oldPrice,
    this.nonVeg = false,
  });

  final String emoji;
  final String title;
  final String price;
  final bool available;
  final ValueChanged<bool> onChanged;
  final String? oldPrice;
  final bool nonVeg;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: [
        SellerIconBadge(
          size: 62,
          background: palette.softGreen.withValues(alpha: 0.9),
          child: Text(emoji, style: const TextStyle(fontSize: 25)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: nonVeg
                          ? const Color(0xFFFF4338)
                          : const Color(0xFF72B843),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: palette.greenDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (oldPrice != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      oldPrice!,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: palette.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SellerSwitch(value: available, onChanged: onChanged),
      ],
    );
  }
}

class SellerDivider extends StatelessWidget {
  const SellerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Divider(height: 1, thickness: 1, color: palette.fieldBorder),
    );
  }
}

class SellerSwitch extends StatelessWidget {
  const SellerSwitch({
    required this.value,
    required this.onChanged,
    this.active,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? active;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: active ?? palette.greenDark,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFD8DADD),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class SellerMutedText extends StatelessWidget {
  const SellerMutedText(this.text, {required this.fontSize, super.key});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      style: TextStyle(
        color: palette.mutedText,
        fontSize: fontSize,
        height: 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}
