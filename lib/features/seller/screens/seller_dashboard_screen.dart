import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_dashboard_home.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_menu_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_order_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_settings_screen.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/profile_image_picker.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/widgets/auth_components.dart';
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
  String? _restaurantName;
  String? _restaurantLogo;
  SellerMenuCuisineSelection? _selectedMenuCuisine;
  bool _loadingRestaurant = false;

  String get _displayRestaurantName {
    final fetchedName = _restaurantName?.trim();
    if (fetchedName != null && fetchedName.isNotEmpty) return fetchedName;
    return widget.restaurantName;
  }

  String get _displayInitials => _restaurantInitials(_displayRestaurantName);

  @override
  void initState() {
    super.initState();
    _restaurantName = widget.restaurantName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurant();
    });
  }

  Future<void> _loadRestaurant() async {
    if (_loadingRestaurant) return;

    setState(() => _loadingRestaurant = true);
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();
      if (token == null || token.trim().isEmpty) return;

      final restaurant = await widget.authApi.fetchRestaurant(
        token: token,
        tokenType: tokenType,
      );
      if (!mounted) return;

      setState(() {
        final restaurantName = restaurant.restaurantName?.trim();
        if (restaurantName != null && restaurantName.isNotEmpty) {
          _restaurantName = restaurantName;
        }
        _restaurantLogo = _publicImageUrl(restaurant.restaurantLogo);
      });
    } on SellerAuthException {
      // Keep the dashboard usable with the values passed by the auth flow.
    } finally {
      if (mounted) setState(() => _loadingRestaurant = false);
    }
  }

  void _openAddMenuList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddMenuListScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
          selectedCuisine: _selectedMenuCuisine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final body = switch (_tab) {
      SellerDashboardTab.dashboard => SellerDashboardHome(
        restaurantName: _displayRestaurantName,
        initials: _displayInitials,
        logoUrl: _restaurantLogo,
      ),
      SellerDashboardTab.orders => const SellerOrdersScreen(),
      SellerDashboardTab.menu => SellerMenuScreen(
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        onCuisineChanged: (selection) {
          if (_selectedMenuCuisine == selection) return;
          setState(() => _selectedMenuCuisine = selection);
        },
      ),
      SellerDashboardTab.settings => SellerSettingsScreen(
        authApi: widget.authApi,
        tokenStorage: widget.tokenStorage,
        restaurantName: _displayRestaurantName,
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
              bottom: 18,
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
                  onPressed: _openAddMenuList,
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

class AddMenuListScreen extends StatefulWidget {
  const AddMenuListScreen({
    SellerAuthApi? authApi,
    SellerAuthTokenStorage? tokenStorage,
    this.selectedCuisine,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       tokenStorage = tokenStorage ?? const SellerAuthTokenStorage();

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerMenuCuisineSelection? selectedCuisine;

  @override
  State<AddMenuListScreen> createState() => _SellerMenuListEditorState();
}

class _SellerMenuListEditorState extends State<AddMenuListScreen> {
  final _imagePicker = const ProfileImagePicker();
  final _nameController = TextEditingController();
  final List<SellerMenu> _menus = [];

  SellerMenuCuisineSelection? _fallbackCuisine;
  String? _imagePath;
  bool _status = true;
  bool _saving = false;
  bool _pickingImage = false;
  bool _loadingFallbackCuisine = false;
  bool _loadingMenus = false;
  String? _menuLoadError;
  int? _editingMenuId;

  SellerMenuCuisineSelection? get _selectedCuisine =>
      widget.selectedCuisine ?? _fallbackCuisine;

  bool get _isEditing => _editingMenuId != null;

  @override
  void initState() {
    super.initState();
    final cuisine = widget.selectedCuisine;
    if (cuisine != null) {
      _setDefaultName(cuisine);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenus());
    } else {
      _loadFallbackCuisine();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setDefaultName(SellerMenuCuisineSelection cuisine) {
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = '${cuisine.name} Menu';
    }
  }

  Future<void> _loadFallbackCuisine() async {
    if (_loadingFallbackCuisine) return;
    setState(() => _loadingFallbackCuisine = true);

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
      SellerCuisine? firstCuisine;
      for (final cuisine in cuisines) {
        if (cuisine.status) {
          firstCuisine = cuisine;
          break;
        }
      }
      if (firstCuisine == null || !mounted) return;

      final selection = SellerMenuCuisineSelection(
        id: firstCuisine.id,
        name: firstCuisine.translatedName,
        emoji: '🍽',
        imageUrl: firstCuisine.imageUrl,
        status: firstCuisine.status,
      );
      setState(() {
        _fallbackCuisine = selection;
        _setDefaultName(selection);
      });
      await _loadMenus();
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to fetch selected cuisine: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _loadingFallbackCuisine = false);
    }
  }

  Future<void> _loadMenus() async {
    if (_loadingMenus) return;

    final cuisineId = _selectedCuisine?.id;
    if (cuisineId == null) return;

    setState(() {
      _loadingMenus = true;
      _menuLoadError = null;
    });

    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();
      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final menus = await widget.authApi.fetchMenus(
        token: token,
        tokenType: tokenType,
        cuisineId: cuisineId,
        perPage: 50,
      );

      if (!mounted) return;
      setState(() => _menus
        ..clear()
        ..addAll(menus));
    } on SellerAuthException catch (error) {
      if (!mounted) return;
      setState(() => _menuLoadError = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _menuLoadError = 'Unable to fetch menus: $error');
    } finally {
      if (mounted) setState(() => _loadingMenus = false);
    }
  }

  Future<void> _pickMenuImage() async {
    if (_pickingImage) return;

    final source = await showModalBottomSheet<PickedImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => const _MenuImageSourceSheet(),
    );
    if (source == null || !mounted) return;

    setState(() => _pickingImage = true);
    try {
      final path = await _imagePicker.pickImage(source: source);
      if (path == null || !mounted) return;
      setState(() => _imagePath = path);
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(
          error.message ?? 'Unable to select image. Please try again.',
          error: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to select image. Please try again.', error: true);
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _saveMenu() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter menu name.', error: true);
      return;
    }

    final cuisine = _selectedCuisine;
    final cuisineId = cuisine?.id;
    if (cuisineId == null) {
      _showMessage('Select a cuisine before creating a menu.', error: true);
      return;
    }

    final token = await widget.tokenStorage.loadToken();
    final tokenType = await widget.tokenStorage.loadTokenType();
    if (token == null || token.trim().isEmpty) {
      _showMessage('Authentication failed. Login again.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final request = SellerMenuRequest(
        translatedName: name,
        cuisineId: cuisineId,
        imagePath: _imagePath,
        status: _status,
      );

      final wasEditing = _isEditing;
      final saved = wasEditing
          ? await widget.authApi.updateMenu(
              _editingMenuId!,
              request,
              token: token,
              tokenType: tokenType,
            )
          : await widget.authApi.createMenu(
              request,
              token: token,
              tokenType: tokenType,
            );

      if (!mounted) return;
      _resetForm(keepCuisineDefault: true);
      await _loadMenus();
      if (!mounted) return;
      _showMessage(wasEditing ? 'Menu updated.' : 'Menu created.');
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) _showMessage('Unable to save menu: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _editMenu(SellerMenu menu) {
    setState(() {
      _editingMenuId = menu.id;
      _nameController.text = menu.displayName;
      _imagePath = menu.image;
      _status = menu.status;
    });
  }

  Future<void> _deleteMenu(SellerMenu menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu'),
        content: const Text('Are you sure you want to delete this menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (menu.id == null) {
      setState(() => _menus.remove(menu));
      _showMessage('Menu removed locally.');
      return;
    }

    final token = await widget.tokenStorage.loadToken();
    final tokenType = await widget.tokenStorage.loadTokenType();
    if (token == null || token.trim().isEmpty) {
      _showMessage('Authentication failed. Login again.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.authApi.deleteMenu(
        menuId: menu.id!,
        token: token,
        tokenType: tokenType,
      );
      if (!mounted) return;
      if (_editingMenuId == menu.id) _resetForm(keepCuisineDefault: true);
      await _loadMenus();
      if (!mounted) return;
      _showMessage('Menu deleted.');
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) _showMessage('Unable to delete menu: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openAddProduct(SellerMenu menu) {
    final cuisine = _selectedCuisine;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddProductScreen(
          cuisineName: cuisine?.name ?? 'Cuisine',
          menuName: menu.displayName,
          menuEmoji: cuisine?.emoji ?? '🍽',
          menuImageUrl: menu.image ?? cuisine?.imageUrl,
        ),
      ),
    );
  }

  void _resetForm({bool keepCuisineDefault = false}) {
    _editingMenuId = null;
    _imagePath = null;
    _status = true;
    _nameController.clear();
    final cuisine = _selectedCuisine;
    if (keepCuisineDefault && cuisine != null) _setDefaultName(cuisine);
  }

  void _showMessage(String message, {bool error = false}) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : palette.greenDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final cuisine = _selectedCuisine;

    return Scaffold(
      backgroundColor: palette.screen,
      body: SellerWorkScaffold(
        title: _isEditing ? 'Update Menu' : 'Add Menu',
        subtitle: cuisine == null
            ? (_loadingFallbackCuisine ? 'Loading selected cuisine' : 'No cuisine selected')
            : '${cuisine.name} cuisine',
        trailing: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const SellerHeaderIcon(Icons.close_rounded),
        ),
        bottomPadding: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SellerEntrance(
              child: cuisine == null
                  ? _MenuListStatusCard(
                      title: 'Cuisine not selected',
                      message: _loadingFallbackCuisine
                          ? 'Finding your selected cuisine.'
                          : 'Open Menu and select a cuisine before adding a list.',
                      loading: _loadingFallbackCuisine,
                      onRetry: _loadFallbackCuisine,
                    )
                  : SellerCard(
                      highlight: true,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SellerCuisineImageBadge(
                            emoji: cuisine.emoji,
                            imageUrl: cuisine.imageUrl,
                            size: 64,
                            background: palette.softGreen.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cuisine.name,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 17,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SellerMutedText(
                                  'Create menu lists inside this cuisine',
                                  fontSize: 12,
                                ),
                              ],
                            ),
                          ),
                          _MenuStatusPill(active: cuisine.status),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SellerEntrance(
              delay: const Duration(milliseconds: 50),
              child: _MenuImagePickerCard(
                imagePath: _imagePath,
                picking: _pickingImage,
                onTap: _pickMenuImage,
              ),
            ),
            const SizedBox(height: 18),
            SellerEntrance(
              delay: const Duration(milliseconds: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SellerFieldLabel('MENU TITLE'),
                  const SizedBox(height: 8),
                  _MenuTextField(
                    controller: _nameController,
                    hintText: cuisine == null ? 'Menu name' : '${cuisine.name} Menu',
                    icon: Icons.restaurant_menu_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SellerEntrance(
              delay: const Duration(milliseconds: 110),
              child: SellerCard(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                child: Row(
                  children: [
                    SellerIconBadge(
                      size: 38,
                      background: palette.softGreen.withValues(alpha: 0.9),
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        color: palette.greenDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Status',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SellerMutedText(
                            _status ? 'Visible to customers' : 'Hidden for now',
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _status,
                      activeColor: palette.greenDark,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SellerEntrance(
              delay: const Duration(milliseconds: 140),
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: cuisine == null || _saving ? null : _saveMenu,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Menu' : 'Create Menu',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _resetForm(keepCuisineDefault: true)),
                child: const Text('Cancel editing'),
              ),
            ],
            const SizedBox(height: 26),
            SellerEntrance(
              delay: const Duration(milliseconds: 170),
              child: Row(
                children: [
                  const Expanded(child: SellerSectionTitle('Stored Menus')),
                  if (_loadingMenus)
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.greenDark,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _selectedCuisine?.id == null ? null : _loadMenus,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: palette.greenDark,
                        size: 20,
                      ),
                      tooltip: 'Refresh menus',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingMenus && _menus.isEmpty)
              SellerEntrance(
                delay: const Duration(milliseconds: 200),
                child: _MenuListStatusCard(
                  title: 'Loading menus',
                  message: 'Fetching menu lists for the selected cuisine.',
                  loading: true,
                  onRetry: _loadMenus,
                ),
              )
            else if (_menuLoadError != null && _menus.isEmpty)
              SellerEntrance(
                delay: const Duration(milliseconds: 200),
                child: _MenuListStatusCard(
                  title: 'Unable to load menus',
                  message: _menuLoadError!,
                  loading: false,
                  onRetry: _loadMenus,
                ),
              )
            else if (_menus.isEmpty)
              SellerEntrance(
                delay: const Duration(milliseconds: 200),
                child: SellerCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      SellerIconBadge(
                        size: 44,
                        background: palette.softGreen.withValues(alpha: 0.9),
                        child: Icon(
                          Icons.playlist_add_check_rounded,
                          color: palette.greenDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: SellerMutedText(
                          'No menu lists yet for this cuisine. Create one above.',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_menus.length, (index) {
                final menu = _menus[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _menus.length - 1 ? 0 : 10),
                  child: SellerEntrance(
                    delay: Duration(milliseconds: 200 + (index * 35)),
                    child: _StoredMenuCard(
                      menu: menu,
                      cuisine: cuisine,
                      onEdit: () => _editMenu(menu),
                      onDelete: () => _deleteMenu(menu),
                      onAddProduct: () => _openAddProduct(menu),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

String? _menuNetworkImageUrl(String? value) {
  return resolveSellerMediaUrl(value);
}

class _MenuStatusPill extends StatelessWidget {
  const _MenuStatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? palette.softGreen.withValues(alpha: 0.85)
            : palette.fieldBorder.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Off',
        style: TextStyle(
          color: active ? palette.greenDark : palette.mutedText,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MenuImagePickerCard extends StatelessWidget {
  const _MenuImagePickerCard({
    required this.imagePath,
    required this.picking,
    required this.onTap,
  });

  final String? imagePath;
  final bool picking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: picking ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.fieldFill.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage
                  ? palette.greenDark.withValues(alpha: 0.45)
                  : palette.fieldBorder,
              width: hasImage ? 1.4 : 1.05,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage) _MenuImagePreview(path: imagePath!),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: hasImage
                        ? [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.28),
                          ]
                        : [
                            palette.softGreen.withValues(alpha: 0.18),
                            palette.fieldFill.withValues(alpha: 0.72),
                          ],
                  ),
                ),
              ),
              Center(
                child: picking
                    ? CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.greenDark,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SellerIconBadge(
                            size: 44,
                            background: Colors.white.withValues(alpha: 0.88),
                            child: Icon(
                              hasImage
                                  ? Icons.edit_rounded
                                  : Icons.add_photo_alternate_rounded,
                              color: palette.greenDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hasImage ? 'Change menu image' : 'Add menu image',
                            style: TextStyle(
                              color: hasImage ? Colors.white : palette.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Camera, gallery, or file',
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : palette.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

class _MenuImagePreview extends StatelessWidget {
  const _MenuImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(path);
    final isHttp =
        uri != null && uri.hasScheme && uri.scheme.toLowerCase().startsWith('http');
    final isFile =
        uri != null && uri.hasScheme && uri.scheme.toLowerCase() == 'file';

    if (isHttp || (!isFile && !path.contains(':\\'))) {
      final networkUrl = resolveSellerMediaUrl(path) ?? path;
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    return Image.file(
      uri != null && uri.scheme.toLowerCase() == 'file'
          ? File.fromUri(uri)
          : File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _MenuTextField extends StatelessWidget {
  const _MenuTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(
        color: palette.text,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: palette.greenDark, size: 19),
        hintText: hintText,
        hintStyle: TextStyle(
          color: palette.mutedText.withValues(alpha: 0.58),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: palette.fieldFill.withValues(alpha: 0.98),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.fieldBorder, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.green, width: 1.5),
        ),
      ),
    );
  }
}

class _StoredMenuCard extends StatelessWidget {
  const _StoredMenuCard({
    required this.menu,
    required this.cuisine,
    required this.onEdit,
    required this.onDelete,
    required this.onAddProduct,
  });

  final SellerMenu menu;
  final SellerMenuCuisineSelection? cuisine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final image = menu.image ?? cuisine?.imageUrl;

    return SellerCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SellerCuisineImageBadge(
            emoji: cuisine?.emoji ?? '🍽',
            imageUrl: image,
            size: 72,
            background: palette.softGreen.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 15,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _MenuStatusPill(active: menu.status),
                  ],
                ),
                const SizedBox(height: 6),
                SellerMutedText(
                  '${cuisine?.name ?? 'Cuisine'} menu list',
                  fontSize: 12,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MenuCardAction(
                      icon: Icons.add_rounded,
                      label: 'Product',
                      onTap: onAddProduct,
                    ),
                    _MenuCardAction(
                      icon: Icons.edit_rounded,
                      label: 'Update',
                      onTap: onEdit,
                    ),
                    _MenuCardAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      danger: true,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCardAction extends StatelessWidget {
  const _MenuCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final color = danger ? Colors.redAccent : palette.greenDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuImageSourceSheet extends StatelessWidget {
  const _MenuImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Material(
          color: palette.screen,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Menu Image',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.mutedText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _MenuImageSourceOptionTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Camera',
                  subtitle: 'Capture a fresh image',
                  onTap: () => Navigator.pop(context, PickedImageSource.camera),
                ),
                const SizedBox(height: 8),
                _MenuImageSourceOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Gallery',
                  subtitle: 'Pick from photos',
                  onTap: () => Navigator.pop(context, PickedImageSource.gallery),
                ),
                const SizedBox(height: 8),
                _MenuImageSourceOptionTile(
                  icon: Icons.folder_open_rounded,
                  title: 'File',
                  subtitle: 'Browse image files',
                  onTap: () => Navigator.pop(context, PickedImageSource.file),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuImageSourceOptionTile extends StatelessWidget {
  const _MenuImageSourceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: palette.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SellerIconBadge(
                size: 36,
                background: palette.softGreen.withValues(alpha: 0.9),
                child: Icon(icon, color: palette.greenDark, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SellerMutedText(subtitle, fontSize: 12),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyAddMenuListScreen extends StatefulWidget {
  const _LegacyAddMenuListScreen({
    SellerAuthApi? authApi,
    SellerAuthTokenStorage? tokenStorage,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       tokenStorage = tokenStorage ?? const SellerAuthTokenStorage();

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;

  @override
  State<_LegacyAddMenuListScreen> createState() => _AddMenuListScreenState();
}

class _AddMenuListScreenState extends State<_LegacyAddMenuListScreen> {
  final _menuNameController = TextEditingController();
  int _selectedIndex = 0;
  bool _loadingCuisines = true;
  String? _cuisineError;
  List<_MenuListOption> _options = const [];

  static const _cuisineEmojis = ['🍛', '🥗', '🥟', '🍚', '🍲', '🥘'];
  static const _previewOptions = [
    _MenuListOption(
      emoji: '🍛',
      cuisineName: 'Indian',
      menuName: 'Mains',
      subtitle: 'Curries, tandoor, biryani',
      count: 12,
    ),
    _MenuListOption(
      emoji: '🥗',
      cuisineName: 'Tajik',
      menuName: 'Traditional',
      subtitle: 'Plov, shashlik, sambusa',
      count: 8,
    ),
    _MenuListOption(
      emoji: '🥟',
      cuisineName: 'Russian',
      menuName: 'Comfort',
      subtitle: 'Pelmeni, soups, blini',
      count: 7,
    ),
    _MenuListOption(
      emoji: '🍚',
      cuisineName: 'Rice Bowls',
      menuName: 'Lunch Bowls',
      subtitle: 'Fast moving rice meals',
      count: 5,
    ),
  ];

  _MenuListOption? get _selectedOption =>
      _options.isEmpty ? null : _options[_selectedIndex];

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

      final options = cuisines.asMap().entries.map((entry) {
        final name = entry.value.translatedName.trim();
        final cuisineName = name.isEmpty ? 'Cuisine ${entry.key + 1}' : name;
        return _MenuListOption(
          emoji: _cuisineEmojis[entry.key % _cuisineEmojis.length],
          cuisineName: cuisineName,
          menuName: cuisineName,
          subtitle: 'Create menu lists for $cuisineName',
          imageUrl: entry.value.imageUrl,
          status: entry.value.status,
          count: 0,
        );
      }).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _options = options;
        if (options.isEmpty) {
          _selectedIndex = 0;
        } else if (_selectedIndex >= options.length ||
            !options[_selectedIndex].status) {
          final firstActive = options.indexWhere((option) => option.status);
          _selectedIndex = firstActive == -1 ? 0 : firstActive;
        }
      });
    } on SellerAuthException catch (error) {
      if (!mounted) return;
      setState(() => _cuisineError = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _cuisineError = 'Unable to fetch cuisines: $error');
    } finally {
      if (mounted) setState(() => _loadingCuisines = false);
    }
  }

  @override
  void dispose() {
    _menuNameController.dispose();
    super.dispose();
  }

  void _continueToProduct() {
    final selected = _selectedOption;
    if (selected == null) return;
    final customName = _menuNameController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddProductScreen(
          cuisineName: selected.cuisineName,
          menuName: customName.isEmpty ? selected.menuName : customName,
          menuEmoji: selected.emoji,
          menuImageUrl: selected.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final selected = _selectedOption;

    return Scaffold(
      backgroundColor: palette.screen,
      body: SellerWorkScaffold(
        title: 'Add Menu List',
        subtitle: selected == null
            ? (_loadingCuisines ? 'Loading cuisines' : 'Select cuisine')
            : '${selected.cuisineName} · ${selected.menuName}',
        trailing: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const SellerHeaderIcon(Icons.close_rounded),
        ),
        bottomPadding: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SellerEntrance(
              child: selected == null
                  ? _MenuListStatusCard(
                      title: _cuisineError ?? 'No cuisines found',
                      message: _loadingCuisines
                          ? 'Fetching cuisine list from /auth/cuisines.'
                          : _cuisineError == null
                          ? 'The cuisine API returned an empty list.'
                          : 'Could not load cuisine list.',
                      loading: _loadingCuisines,
                      onRetry: _loadCuisines,
                    )
                  : SellerCard(
                      highlight: true,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SellerCuisineImageBadge(
                            emoji: selected.emoji,
                            imageUrl: selected.imageUrl,
                            size: 48,
                            background: palette.softGreen.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.cuisineName,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 17,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SellerMutedText(selected.subtitle, fontSize: 12),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.playlist_add_rounded,
                            color: palette.greenDark,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            SellerEntrance(
              delay: const Duration(milliseconds: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SellerFieldLabel('MENU LIST NAME'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _menuNameController,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      hintText: selected?.menuName ?? 'Menu list name',
                      hintStyle: TextStyle(
                        color: palette.mutedText.withValues(alpha: 0.55),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: palette.fieldFill.withValues(alpha: 0.98),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: palette.fieldBorder,
                          width: 1.1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.green, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SellerEntrance(
              delay: const Duration(milliseconds: 110),
              child: SellerSectionTitle('Cuisine Lists'),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _loadingCuisines ? _previewOptions.length : _options.length,
              (index) {
              final option = _loadingCuisines
                  ? _previewOptions[index]
                  : _options[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index ==
                          (_loadingCuisines
                                  ? _previewOptions.length
                                  : _options.length) -
                              1
                      ? 0
                      : 10,
                ),
                child: SellerEntrance(
                  delay: Duration(milliseconds: 140 + (index * 35)),
                  child: _MenuListOptionCard(
                    option: option,
                    selected: !_loadingCuisines && _selectedIndex == index,
                    loading: _loadingCuisines,
                    onTap: () {
                      if (_loadingCuisines) return;
                      setState(() => _selectedIndex = index);
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SellerEntrance(
              delay: const Duration(milliseconds: 240),
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: selected == null || !selected.status
                      ? null
                      : _continueToProduct,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuListOption {
  const _MenuListOption({
    required this.emoji,
    required this.cuisineName,
    required this.menuName,
    required this.subtitle,
    required this.count,
    this.imageUrl,
    this.status = true,
  });

  final String emoji;
  final String cuisineName;
  final String menuName;
  final String subtitle;
  final int count;
  final String? imageUrl;
  final bool status;
}

class _MenuListOptionCard extends StatelessWidget {
  const _MenuListOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  final _MenuListOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: loading || !option.status ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? palette.softGreen.withValues(alpha: 0.95)
                : palette.fieldFill.withValues(
                    alpha: loading || !option.status ? 0.58 : 0.96,
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.greenDark : palette.fieldBorder,
              width: selected ? 1.4 : 1.05,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? palette.greenDark.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              SellerCuisineImageBadge(
                emoji: option.emoji,
                imageUrl: option.imageUrl,
                size: 44,
                background: palette.softGreen.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.menuName,
                      style: TextStyle(
                        color: option.status ? palette.text : palette.mutedText,
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
                          : option.status
                          ? '${option.cuisineName} · ${option.count} products'
                          : '${option.cuisineName} · inactive',
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: option.status
                          ? palette.softGreen.withValues(alpha: 0.9)
                          : palette.fieldBorder.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      option.status ? 'Active' : 'Off',
                      style: TextStyle(
                        color: option.status
                            ? palette.greenDark
                            : palette.mutedText,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? palette.greenDark : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? palette.greenDark : palette.fieldBorder,
                        width: 1.4,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuListStatusCard extends StatelessWidget {
  const _MenuListStatusCard({
    required this.title,
    required this.message,
    required this.loading,
    required this.onRetry,
  });

  final String title;
  final String message;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SellerCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SellerIconBadge(
            size: 46,
            background: palette.softGreen.withValues(alpha: 0.9),
            child: loading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.greenDark,
                      ),
                    ),
                  )
                : Icon(
                    Icons.restaurant_menu_rounded,
                    color: palette.greenDark,
                    size: 22,
                  ),
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
          if (!loading) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: palette.greenDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    this.cuisineName = 'Indian',
    this.menuName = 'Rice',
    this.menuEmoji = '🍚',
    this.menuImageUrl,
    super.key,
  });

  final String cuisineName;
  final String menuName;
  final String menuEmoji;
  final String? menuImageUrl;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const _maxImages = 5;
  final _imagePicker = const ProfileImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _stockController = TextEditingController();
  final List<String> _imagePaths = [];

  bool _available = true;
  bool _pickingImage = false;
  String _foodType = 'veg';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _prepTimeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickProductImage() async {
    if (_pickingImage || _imagePaths.length >= _maxImages) return;

    final source = await showModalBottomSheet<PickedImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => const _MenuImageSourceSheet(),
    );
    if (source == null || !mounted) return;

    setState(() => _pickingImage = true);
    try {
      final path = await _imagePicker.pickImage(source: source);
      if (path == null || !mounted) return;
      setState(() => _imagePaths.add(path));
    } on PlatformException catch (error) {
      if (mounted) _showMessage(error.message ?? 'Unable to select image.');
    } catch (_) {
      if (mounted) _showMessage('Unable to select image.');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        opacity: 0.06,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      BackTextButton(
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      Text(
                        'Save',
                        style: TextStyle(
                          color: palette.greenDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add Product',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.menuName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SellerCard(
                  highlight: true,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SellerCuisineImageBadge(
                        emoji: widget.menuEmoji,
                        imageUrl: widget.menuImageUrl,
                        size: 52,
                        background: palette.softGreen.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.menuName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SellerMutedText(
                              widget.cuisineName,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProductImagesPicker(
                  imagePaths: _imagePaths,
                  maxImages: _maxImages,
                  picking: _pickingImage,
                  onAdd: _pickProductImage,
                  onRemove: _removeImage,
                ),
                const SizedBox(height: 16),
                ProductTextField(
                  label: 'PRODUCT NAME',
                  controller: _nameController,
                  hintText: 'Enter product name',
                ),
                const SizedBox(height: 14),
                ProductTextField(
                  label: 'DESCRIPTION',
                  controller: _descriptionController,
                  hintText: 'Short description (optional)',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ProductTextField(
                        label: 'PRICE',
                        controller: _priceController,
                        hintText: '₹0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ProductTextField(
                        label: 'DISCOUNT',
                        controller: _discountPriceController,
                        hintText: '₹0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const SellerFieldLabel('FOOD TYPE'),
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
                        label: 'Non-Veg',
                        dot: const Color(0xFFFF4338),
                        selected: _foodType == 'non-veg',
                        onTap: () => setState(() => _foodType = 'non-veg'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ProductTextField(
                        label: 'PREP TIME',
                        controller: _prepTimeController,
                        hintText: 'min',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ProductTextField(
                        label: 'STOCK',
                        controller: _stockController,
                        hintText: 'qty',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SellerCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SellerMutedText(
                              'Visible to customers',
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                      SellerSwitch(
                        value: _available,
                        onChanged: (value) => setState(() => _available = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Product',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImagesPicker extends StatelessWidget {
  const _ProductImagesPicker({
    required this.imagePaths,
    required this.maxImages,
    required this.picking,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> imagePaths;
  final int maxImages;
  final bool picking;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final canAdd = imagePaths.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SellerFieldLabel('PRODUCT IMAGES'),
            const Spacer(),
            Text(
              '${imagePaths.length}/$maxImages',
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (imagePaths.isEmpty)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: picking ? null : onAdd,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.fieldFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: palette.fieldBorder,
                    width: 1.2,
                  ),
                ),
                child: picking
                    ? CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: palette.greenDark,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: palette.greenDark,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add photos',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SellerMutedText('Up to $maxImages images', fontSize: 11),
                        ],
                      ),
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: imagePaths.length + (canAdd ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (canAdd && index == imagePaths.length) {
                  return _ProductAddImageTile(
                    picking: picking,
                    onTap: onAdd,
                  );
                }
                return _ProductImageThumb(
                  path: imagePaths[index],
                  onRemove: () => onRemove(index),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProductImageThumb extends StatelessWidget {
  const _ProductImageThumb({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final isNetwork = path.startsWith('http');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 108,
            height: 108,
            child: isNetwork
                ? Image.network(path, fit: BoxFit.cover)
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4338),
                shape: BoxShape.circle,
                border: Border.all(color: palette.screen, width: 2),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductAddImageTile extends StatelessWidget {
  const _ProductAddImageTile({required this.picking, required this.onTap});

  final bool picking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: palette.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: picking ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: palette.greenDark.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: picking
              ? Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.greenDark,
                    ),
                  ),
                )
              : Icon(Icons.add_rounded, color: palette.greenDark, size: 28),
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

class ProductTextField extends StatelessWidget {
  const ProductTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellerFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          style: TextStyle(
            color: palette.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: palette.mutedText.withValues(alpha: 0.65),
              fontSize: 14,
            ),
            filled: true,
            fillColor: palette.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.green, width: 1.3),
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
        height: 44,
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
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : palette.text,
                  fontSize: 12,
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

String _restaurantInitials(String restaurantName) {
  final words = restaurantName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'S';
  return words.map((word) => word[0]).join().toUpperCase();
}

String? _publicImageUrl(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) return text;
  if (text.startsWith('/')) return 'https://restro.devhimanshu.com$text';
  return 'https://restro.devhimanshu.com/$text';
}
