import 'package:flutter/material.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_dashboard_home.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_menu_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_order_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_settings_screen.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/data/seller_auth_token_storage.dart';

enum SellerDashboardTab { dashboard, orders, menu, settings }

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({
    SellerAuthApi? authApi,
    SellerAuthTokenStorage? tokenStorage,
    this.restaurantName = 'Spice Garden',
    this.initials = 'RK',
    this.onLoggedOut,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       tokenStorage = tokenStorage ?? const SellerAuthTokenStorage();

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final String restaurantName;
  final String initials;
  final VoidCallback? onLoggedOut;

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  SellerDashboardTab _tab = SellerDashboardTab.dashboard;

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const AddProductScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final body = switch (_tab) {
      SellerDashboardTab.dashboard => SellerDashboardHome(
        restaurantName: widget.restaurantName,
        initials: widget.initials,
      ),
      SellerDashboardTab.orders => const SellerOrdersScreen(),
      SellerDashboardTab.menu => const SellerMenuScreen(),
      SellerDashboardTab.settings => SellerSettingsScreen(
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        restaurantName: widget.restaurantName,
        onLoggedOut: widget.onLoggedOut,
      ),
    };

    return Scaffold(
      backgroundColor: palette.screen,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(key: ValueKey(_tab), child: body),
          ),
          if (_tab == SellerDashboardTab.menu)
            Positioned(
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 96,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: palette.greenDark.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'add-product',
                  elevation: 0,
                  backgroundColor: palette.greenDark,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  onPressed: _openAddProduct,
                  child: const Icon(Icons.add_rounded, size: 34),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SellerBottomNavigation(
        currentTab: _tab,
        onChanged: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool _available = true;
  String _foodType = 'non-veg';

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Scaffold(
      backgroundColor: palette.screen,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: palette.mutedText,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: palette.mutedText,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Add Product',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Save',
                    style: TextStyle(
                      color: palette.greenDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: palette.fieldBorder,
                    width: 1.8,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: 12),
                    SellerMutedText('Upload product images', fontSize: 15),
                    const SizedBox(height: 5),
                    SellerMutedText('Max 5 images · JPG, PNG', fontSize: 13),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const ProductInput(
                label: 'PRODUCT NAME',
                value: 'Chicken Biryani',
              ),
              const SizedBox(height: 18),
              const ProductInput(
                label: 'DESCRIPTION',
                value:
                    'Aromatic basmati rice layered with tender chicken, saffron, and traditional spices',
                height: 86,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: ProductInput(label: 'PRICE', value: r'$14.99'),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: ProductInput(
                      label: 'DISCOUNT PRICE',
                      value: r'$12.49',
                      valueColor: Color(0xFF069464),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: ProductInput(label: 'CATEGORY', value: 'Rice ▼'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SellerFieldLabel('FOOD TYPE'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FoodTypeSelectChip(
                                label: 'Veg',
                                dot: const Color(0xFF72B843),
                                selected: _foodType == 'veg',
                                onTap: () => setState(() => _foodType = 'veg'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FoodTypeSelectChip(
                                label: 'Non-\nVeg',
                                dot: const Color(0xFFFF4338),
                                selected: _foodType == 'non-veg',
                                onTap: () {
                                  setState(() => _foodType = 'non-veg');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SellerFieldLabel('ADD-ONS'),
              const SizedBox(height: 8),
              SellerCard(
                child: Column(
                  children: [
                    const _AddonRow(label: 'Extra Raita', price: r'+$1.50'),
                    const SellerDivider(),
                    const _AddonRow(label: 'Boiled Egg', price: r'+$1.00'),
                    const SellerDivider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+ Add more',
                        style: TextStyle(
                          color: palette.greenDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SellerFieldLabel('VARIANTS'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _VariantChip(r'Half - $8.99', selected: true),
                  _VariantChip(r'Full - $14.99', selected: true),
                  _VariantChip('+ Add'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: ProductInput(label: 'PREP TIME', value: '30 min'),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: ProductInput(label: 'STOCK', value: '50 qty'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 5),
                        SellerMutedText('Show on customer app', fontSize: 13),
                      ],
                    ),
                  ),
                  SellerSwitch(
                    value: _available,
                    onChanged: (value) => setState(() => _available = value),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Product',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SellerBottomNavigation extends StatelessWidget {
  const SellerBottomNavigation({
    required this.currentTab,
    required this.onChanged,
    super.key,
  });

  final SellerDashboardTab currentTab;
  final ValueChanged<SellerDashboardTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottom > 0 ? 8 : 14),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: palette.fieldFill.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.fieldBorder, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.28
                      : 0.09,
                ),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: palette.greenDark.withValues(alpha: 0.07),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _BottomNavItem(
                tab: SellerDashboardTab.dashboard,
                currentTab: currentTab,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                onTap: onChanged,
              ),
              _BottomNavItem(
                tab: SellerDashboardTab.orders,
                currentTab: currentTab,
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                onTap: onChanged,
              ),
              _BottomNavItem(
                tab: SellerDashboardTab.menu,
                currentTab: currentTab,
                icon: Icons.restaurant_menu_rounded,
                label: 'Menu',
                onTap: onChanged,
              ),
              _BottomNavItem(
                tab: SellerDashboardTab.settings,
                currentTab: currentTab,
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tab,
    required this.currentTab,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final SellerDashboardTab tab;
  final SellerDashboardTab currentTab;
  final IconData icon;
  final String label;
  final ValueChanged<SellerDashboardTab> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final selected = tab == currentTab;
    final color = selected ? palette.greenDark : palette.mutedText;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () => onTap(tab),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: selected ? 34 : 28,
                    height: selected ? 30 : 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? palette.greenDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: palette.greenDark.withValues(
                                  alpha: 0.24,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : color,
                      size: selected ? 19 : 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      height: 1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: selected ? 18 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: palette.greenDark,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SellerScreenTitle extends StatelessWidget {
  const SellerScreenTitle(this.text, {this.fontSize = 24, super.key});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      style: TextStyle(
        color: palette.text,
        fontSize: fontSize,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class SellerSectionTitle extends StatelessWidget {
  const SellerSectionTitle(this.text, {this.fontSize = 16, super.key});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      style: TextStyle(
        color: palette.text,
        fontSize: fontSize,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class SellerFieldLabel extends StatelessWidget {
  const SellerFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      style: TextStyle(
        color: palette.mutedText,
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class SellerSegmentedControl extends StatelessWidget {
  const SellerSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: palette.fieldFill.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(13),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.greenDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: palette.greenDark.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected ? Colors.white : palette.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ProductInput extends StatelessWidget {
  const ProductInput({
    required this.label,
    required this.value,
    this.height = 56,
    this.maxLines = 1,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final double height;
  final int maxLines;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellerFieldLabel(label),
        const SizedBox(height: 8),
        Container(
          height: height,
          alignment: maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: palette.fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.fieldBorder, width: 1.1),
          ),
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? palette.text,
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class FoodTypeSelectChip extends StatelessWidget {
  const FoodTypeSelectChip({
    required this.label,
    required this.dot,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Color dot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.greenDark : palette.screen,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.greenDark : palette.fieldBorder,
            width: 1.1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : palette.text,
                  fontSize: 13,
                  height: 1.05,
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

class _AddonRow extends StatelessWidget {
  const _AddonRow({required this.label, required this.price});

  final String label;
  final String price;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          price,
          style: TextStyle(
            color: palette.greenDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? palette.greenDark : palette.screen,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? palette.greenDark : palette.fieldBorder,
          width: 1.1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : palette.text.withValues(alpha: 0.72),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
