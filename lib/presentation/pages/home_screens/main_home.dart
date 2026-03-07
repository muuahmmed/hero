import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hero/core/utils/app_tab_notifier.dart';
import 'package:hero/data/services/category_service.dart';
import 'package:hero/data/services/product_service.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_cubit/cart_cubit.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_cubit/cart_states.dart';
import 'package:hero/presentation/pages/home_screens/cart_screen/cart_screen.dart';
import 'package:hero/presentation/pages/home_screens/categories/categories_cubit/categories_cubit.dart';
import 'package:hero/presentation/pages/home_screens/categories/categories_screen.dart';
import 'package:hero/presentation/pages/home_screens/personal/personal_screen.dart';

import 'home/home_cubit/home_cubit.dart';
import 'home/home_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  late final HomeCubit _homeCubit;
  late final CategoriesCubit _categoriesCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit(ProductService());
    _categoriesCubit = CategoriesCubit(CategoryService());
    appTabIndex.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final idx = appTabIndex.value;
    if (mounted && _currentIndex != idx) {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  void dispose() {
    appTabIndex.removeListener(_onTabChanged);
    _homeCubit.close();
    _categoriesCubit.close();
    super.dispose();
  }

  final List<Widget> _labels = const [
    Text('Home'),
    Text('Categories'),
    Text('Cart'),
    Text('Profile'),
  ];

  final List<IconData> _icons = const [
    Icons.home_outlined,
    Icons.category_outlined,
    Icons.shopping_cart_outlined,
    Icons.person_outline,
  ];

  final List<IconData> _activeIcons = const [
    Icons.home,
    Icons.category,
    Icons.shopping_cart,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider.value(value: _categoriesCubit),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            CategoriesScreen(),
            CartScreen(),
            PersonalScreen(),
          ],
        ),
        bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final cartCount = cartState is CartLoaded
                ? cartState.items.fold<int>(0, (s, i) => s + i.quantity)
                : 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(4, (index) {
                      final isSelected = _currentIndex == index;
                      final showBadge = index == 2 && cartCount > 0;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentIndex = index);
                          appTabIndex.value = index;
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isSelected
                                          ? _activeIcons[index]
                                          : _icons[index],
                                      key: ValueKey(isSelected),
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : Colors.grey[500],
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : Colors.grey[500],
                                    ),
                                    child: _labels[index],
                                  ),
                                ],
                              ),
                              if (showBadge)
                                Positioned(
                                  top: -6,
                                  right: -10,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        cartCount > 9 ? '9+' : '$cartCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
