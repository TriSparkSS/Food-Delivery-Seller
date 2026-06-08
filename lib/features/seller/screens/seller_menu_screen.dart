import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/data/seller_auth_token_storage.dart';
import '../../auth/widgets/auth_components.dart';

class SellerMenuCuisineSelection {
  const SellerMenuCuisineSelection({
    required this.name,
    required this.emoji,
    this.id,
    this.imageUrl,
    this.status = true,
  });

  final int? id;
  final String name;
  final String emoji;
  final String? imageUrl;
  final bool status;
}

class _MenuCuisine {
  const _MenuCuisine({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.items,
    this.id,
    this.imageUrl,
    this.status = true,
  });

  final int? id;
  final String emoji;
  final String name;
  final String subtitle;
  final List<_MenuItem> items;
  final String? imageUrl;
  final bool status;
}

class _MenuItem {
  const _MenuItem({
    required this.emoji,
    required this.title,
    required this.price,
    this.oldPrice,
    this.nonVeg = false,
  });

  final String emoji;
  final String title;
  final String price;
  final String? oldPrice;
  final bool nonVeg;
}

class SellerMenuScreen extends StatefulWidget {
  const SellerMenuScreen({
    SellerAuthApi? authApi,
    SellerAuthTokenStorage? tokenStorage,
    this.onCuisineChanged,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       tokenStorage = tokenStorage ?? const SellerAuthTokenStorage();

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final ValueChanged<SellerMenuCuisineSelection?>? onCuisineChanged;

  @override
  State<SellerMenuScreen> createState() => _SellerMenuScreenState();
}

class _SellerMenuScreenState extends State<SellerMenuScreen> {
  int _selectedCuisine = 0;
  bool _loadingCuisines = true;
  String? _cuisineError;
  List<_MenuCuisine> _cuisines = const [];
  List<List<bool>> _available = const [];

  static const _cuisineEmojis = ['🍛', '🥗', '🥟', '🍚', '🍲', '🥘'];
  static const List<_MenuCuisine> _previewCuisines = [
    _MenuCuisine(
      emoji: '🍛',
      name: 'Indian',
      subtitle: 'Curries, biryani, breads',
      items: [
        _MenuItem(
          emoji: '🍛',
          title: 'Butter Chicken',
          price: r'$12.99',
          oldPrice: r'$15.99',
          nonVeg: true,
        ),
        _MenuItem(emoji: '🥘', title: 'Paneer Tikka', price: r'$10.49'),
        _MenuItem(
          emoji: '🍗',
          title: 'Tandoori Chicken',
          price: r'$13.99',
          nonVeg: true,
        ),
        _MenuItem(emoji: '🍲', title: 'Dal Makhani', price: r'$8.99'),
      ],
    ),
    _MenuCuisine(
      emoji: '🥗',
      name: 'Tajik',
      subtitle: 'Plov, soups, grill',
      items: [
        _MenuItem(emoji: '🍚', title: 'Qurutob Bowl', price: r'$9.49'),
        _MenuItem(
          emoji: '🍖',
          title: 'Shashlik Plate',
          price: r'$15.99',
          nonVeg: true,
        ),
        _MenuItem(emoji: '🥟', title: 'Sambusa', price: r'$6.49'),
      ],
    ),
    _MenuCuisine(
      emoji: '🥟',
      name: 'Russian',
      subtitle: 'Dumplings, soups, comfort food',
      items: [
        _MenuItem(emoji: '🥟', title: 'Pelmeni', price: r'$11.49'),
        _MenuItem(emoji: '🍲', title: 'Borscht', price: r'$8.99'),
        _MenuItem(emoji: '🥞', title: 'Blini', price: r'$7.49'),
      ],
    ),
    _MenuCuisine(
      emoji: '🍚',
      name: 'Rice Bowls',
      subtitle: 'Fast moving lunch sets',
      items: [
        _MenuItem(
          emoji: '🍚',
          title: 'Biryani Special',
          price: r'$14.99',
          nonVeg: true,
        ),
        _MenuItem(emoji: '🍜', title: 'Veg Pulao Bowl', price: r'$8.99'),
      ],
    ),
  ];
  int get _totalProducts =>
      _cuisines.fold(0, (total, cuisine) => total + cuisine.items.length);

  _MenuCuisine? get _currentCuisine =>
      _cuisines.isEmpty ? null : _cuisines[_selectedCuisine];

  SellerMenuCuisineSelection? _selectionFrom(_MenuCuisine? cuisine) {
    if (cuisine == null) return null;
    return SellerMenuCuisineSelection(
      id: cuisine.id,
      name: cuisine.name,
      emoji: cuisine.emoji,
      imageUrl: cuisine.imageUrl,
      status: cuisine.status,
    );
  }

  void _notifyCuisineChanged() {
    widget.onCuisineChanged?.call(_selectionFrom(_currentCuisine));
  }

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    setState(() {
      _loadingCuisines = true;
      _cuisineError = null;
    });

    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();
      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final cuisines = await widget.authApi.fetchCuisines(
        token: token,
        tokenType: tokenType,
        perPage: 50,
      );
      final mapped = cuisines.asMap().entries.map((entry) {
        final name = entry.value.translatedName.trim();
        final emoji = _cuisineEmojis[entry.key % _cuisineEmojis.length];
        return _MenuCuisine(
          id: entry.value.id,
          emoji: emoji,
          name: name.isEmpty ? 'Cuisine ${entry.key + 1}' : name,
          subtitle: 'Add menu lists and products',
          imageUrl: entry.value.imageUrl,
          status: entry.value.status,
          items: const [],
        );
      }).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _cuisines = mapped;
        _available = mapped
            .map((cuisine) => List<bool>.filled(cuisine.items.length, true))
            .toList(growable: false);
        _selectedCuisine = mapped.isEmpty ? 0 : _selectedCuisine;
        if (_selectedCuisine >= mapped.length && mapped.isNotEmpty) {
          _selectedCuisine = mapped.length - 1;
        }
      });
      _notifyCuisineChanged();
    } on SellerAuthException catch (error) {
      if (!mounted) return;
      setState(() => _cuisineError = error.message);
      widget.onCuisineChanged?.call(null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _cuisineError = 'Unable to fetch cuisines: $error');
      widget.onCuisineChanged?.call(null);
    } finally {
      if (mounted) setState(() => _loadingCuisines = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final currentCuisine = _currentCuisine;
    final currentItems = currentCuisine?.items ?? const <_MenuItem>[];
    final currentAvailability = _available.isEmpty
        ? const <bool>[]
        : _available[_selectedCuisine];

    return SellerWorkScaffold(
      title: 'Menu',
      subtitle: _loadingCuisines
          ? 'Loading cuisines'
          : '${_cuisines.length} cuisines · $_totalProducts products',
      trailing: const SellerHeaderIcon(Icons.search_rounded),
      bottomPadding: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellerEntrance(
            child: _buildCuisineList(),
          ),
          const SizedBox(height: 22),
          SellerEntrance(
            delay: const Duration(milliseconds: 70),
            child: currentCuisine == null
                ? _CuisineStatusCard(
                    icon: Icons.restaurant_menu_rounded,
                    title: _cuisineError ?? 'No cuisines found',
                    message: _cuisineError == null
                        ? 'Cuisine types from /auth/cuisines will appear here.'
                        : 'Pull fresh data and try again.',
                    actionText: 'Retry',
                    onAction: _loadCuisines,
                  )
                : Row(
                    children: [
                      SellerCuisineImageBadge(
                        emoji: currentCuisine.emoji,
                        imageUrl: currentCuisine.imageUrl,
                        size: 58,
                        background: palette.softGreen.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentCuisine.name} Menu',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 16,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SellerMutedText(
                              currentItems.isEmpty
                                  ? 'No products yet · add your first item'
                                  : '${currentItems.length} products · ${currentCuisine.subtitle}',
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: currentCuisine.status
                              ? palette.softGreen.withValues(alpha: 0.78)
                              : palette.fieldBorder.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          currentCuisine.status
                              ? (currentItems.isEmpty ? 'New' : 'Live')
                              : 'Off',
                          style: TextStyle(
                            color: currentCuisine.status
                                ? palette.greenDark
                                : palette.mutedText,
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          SellerEntrance(
            delay: const Duration(milliseconds: 90),
            child: currentCuisine == null || currentItems.isEmpty
                ? _EmptyCuisineProducts(cuisine: currentCuisine)
                : SellerCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: Column(
                      children: List.generate(currentItems.length * 2 - 1, (
                        index,
                      ) {
                        if (index.isOdd) return const SellerDivider();

                        final itemIndex = index ~/ 2;
                        final item = currentItems[itemIndex];
                        return _MenuProductRow(
                          emoji: item.emoji,
                          title: item.title,
                          price: item.price,
                          oldPrice: item.oldPrice,
                          nonVeg: item.nonVeg,
                          available: currentAvailability[itemIndex],
                          onChanged: (value) {
                            setState(() {
                              currentAvailability[itemIndex] = value;
                            });
                          },
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineList() {
    if (_loadingCuisines) {
      return SizedBox(
        height: 158,
        child: ListView.separated(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final cuisine = _previewCuisines[index];
            return _CuisineListCard(
              cuisine: cuisine,
              selected: index == 0,
              loading: true,
              onTap: () {},
            );
          },
        ),
      );
    }

    if (_cuisines.isEmpty) {
      return _CuisineStatusCard(
        icon: Icons.no_food_rounded,
        title: _cuisineError ?? 'No cuisines available',
        message: _cuisineError == null
            ? 'The cuisine API returned an empty list.'
            : 'Could not load cuisine list from /auth/cuisines.',
        actionText: 'Retry',
        onAction: _loadCuisines,
      );
    }

    return SizedBox(
      height: 158,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _cuisines.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cuisine = _cuisines[index];
          return _CuisineListCard(
            cuisine: cuisine,
            selected: _selectedCuisine == index,
            onTap: () {
              setState(() => _selectedCuisine = index);
              _notifyCuisineChanged();
            },
          );
        },
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
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return LightAuthTextureBackground(
      opacity: Theme.of(context).brightness == Brightness.dark ? 0.025 : 0.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.green.withValues(alpha: 0.055),
              palette.screen.withValues(alpha: 0.02),
              palette.screen.withValues(alpha: 0),
            ],
            stops: const [0, 0.34, 1],
          ),
        ),
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
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.985 + (0.015 * value),
                      child: child,
                    ),
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
      ),
    );
  }
}

class SellerEntrance extends StatelessWidget {
  const SellerEntrance({
    required this.child,
    this.delay = Duration.zero,
    this.dy = 14,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double dy;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: 430 + delay.inMilliseconds);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final start = delay.inMilliseconds / duration.inMilliseconds;
        final adjusted = ((value - start) / (1 - start))
            .clamp(0.0, 1.0)
            .toDouble();

        return Opacity(
          opacity: adjusted,
          child: Transform.translate(
            offset: Offset(0, dy * (1 - adjusted)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * adjusted),
              child: child,
            ),
          ),
        );
      },
      child: child,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.screen.withValues(alpha: 0.98),
            palette.fieldFill.withValues(alpha: 0.94),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: palette.fieldBorder.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: palette.greenDark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: palette.text, size: 20),
    );
  }
}

class _CuisineListCard extends StatelessWidget {
  const _CuisineListCard({
    required this.cuisine,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  final _MenuCuisine cuisine;
  final bool selected;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.softGreen,
                        palette.green.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
              color: selected
                  ? null
                  : palette.fieldFill.withValues(alpha: loading ? 0.58 : 0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? palette.greenDark.withValues(alpha: 0.42)
                    : palette.fieldBorder,
                width: selected ? 1.35 : 1.05,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? palette.greenDark.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: selected ? 24 : 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SellerCuisineImageBadge(
                      emoji: cuisine.emoji,
                      imageUrl: cuisine.imageUrl,
                      size: 56,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cuisine.status
                            ? palette.softGreen.withValues(alpha: 0.9)
                            : palette.fieldBorder.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        cuisine.status ? 'Active' : 'Off',
                        style: TextStyle(
                          color: cuisine.status
                              ? palette.greenDark
                              : palette.mutedText,
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  loading ? 'Loading' : cuisine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                SellerMutedText(
                  loading
                      ? 'Fetching cuisines'
                      : cuisine.status
                      ? '${cuisine.items.length} products'
                      : 'Currently inactive',
                  fontSize: 11,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CuisineStatusCard extends StatelessWidget {
  const _CuisineStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SellerCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SellerIconBadge(
            size: 46,
            background: palette.softGreen.withValues(alpha: 0.9),
            child: Icon(icon, color: palette.greenDark, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                SellerMutedText(message, fontSize: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: TextStyle(
                color: palette.greenDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SellerCuisineImageBadge extends StatelessWidget {
  const SellerCuisineImageBadge({
    required this.emoji,
    this.imageUrl,
    this.size = 44,
    this.background,
    super.key,
  });

  final String emoji;
  final String? imageUrl;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final image = imageUrl?.trim();

    return SellerIconBadge(
      size: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: image == null || image.isEmpty
            ? _CuisineEmojiFallback(emoji: emoji, size: size)
            : Image.network(
                image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox.square(
                    dimension: size * 0.42,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.greenDark,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _CuisineEmojiFallback(emoji: emoji, size: size);
                },
              ),
      ),
    );
  }
}

class _CuisineEmojiFallback extends StatelessWidget {
  const _CuisineEmojiFallback({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: TextStyle(fontSize: size * 0.46));
  }
}

class _EmptyCuisineProducts extends StatelessWidget {
  const _EmptyCuisineProducts({required this.cuisine});

  final _MenuCuisine? cuisine;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final cuisineName = cuisine?.name ?? 'this cuisine';

    return SellerCard(
      highlight: true,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        children: [
          SellerIconBadge(
            size: 54,
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: palette.greenDark,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No products yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.text,
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          SellerMutedText(
            'Tap the plus button to create a menu list and add products in $cuisineName.',
            fontSize: 12,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background ?? palette.softGreen,
            (background ?? palette.greenDark).withValues(alpha: 0.72),
          ],
        ),
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
      child: AnimatedScale(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        scale: selected ? 1 : 0.96,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.fieldFill.withValues(alpha: 0.985),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? palette.greenDark.withValues(alpha: 0.2)
              : palette.fieldBorder.withValues(alpha: 0.9),
          width: 1.05,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.greenDark.withValues(
              alpha: highlight ? 0.08 : 0.035,
            ),
            blurRadius: highlight ? 28 : 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.04,
            ),
            blurRadius: 26,
            offset: const Offset(0, 14),
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: available ? 1 : 0.58,
      child: Row(
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
      ),
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
  const SellerMutedText(
    this.text, {
    required this.fontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final double fontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines == null ? null : TextOverflow.ellipsis),
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
