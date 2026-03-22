import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _bgController;

  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _bgScale;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Premium Supplements',
      'description':
      'Discover high-quality fitness supplements trusted by athletes. From proteins to vitamins, we have everything you need.',
      'icon': Icons.fitness_center,
      'color': Color(0xFF3B82F6),
      'bgColor': Color(0xFFEFF6FF),
      'emoji': '💪',
    },
    {
      'title': 'Huge Product Range',
      'description':
      'Browse hundreds of products across 8+ categories including Protein, Creatine, Pre-Workout, Vitamins, and more.',
      'icon': Icons.category_outlined,
      'color': Color(0xFF10B981),
      'bgColor': Color(0xFFECFDF5),
      'emoji': '🛒',
    },
    {
      'title': 'Easy Ordering',
      'description':
      'Place orders in seconds, track them in real-time, and get them delivered straight to your door.',
      'icon': Icons.local_shipping_outlined,
      'color': Color(0xFFF59E0B),
      'bgColor': Color(0xFFFFFBEB),
      'emoji': '🚀',
    },
    {
      'title': 'Your Fitness Journey',
      'description':
      'Save your favorites, write reviews, and build your perfect supplement stack with Hero Fitness.',
      'icon': Icons.stars_outlined,
      'color': Color(0xFF8B5CF6),
      'bgColor': Color(0xFFF5F3FF),
      'emoji': '🏆',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runEntryAnimation();
  }

  void _initAnimations() {
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconScale = CurvedAnimation(
        parent: _iconController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    _iconRotate = CurvedAnimation(
        parent: _iconController, curve: Curves.easeOut)
        .drive(Tween(begin: -0.1, end: 0.0));

    _textFade = CurvedAnimation(
        parent: _textController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _textSlide = CurvedAnimation(
        parent: _textController, curve: Curves.easeOut)
        .drive(Tween(
        begin: const Offset(0, 0.3), end: Offset.zero));

    _bgScale = CurvedAnimation(
        parent: _bgController, curve: Curves.easeOut)
        .drive(Tween(begin: 0.8, end: 1.0));
  }

  void _runEntryAnimation() {
    _bgController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _iconController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  void _runPageChangeAnimation() {
    _iconController.reset();
    _textController.reset();
    _bgController.reset();
    _runEntryAnimation();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _bgController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final color = page['color'] as Color;
    final bgColor = page['bgColor'] as Color;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Row ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text('Hero Fitness',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[500]),
                      child: const Text('Skip',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),

              // ── Page Content ──────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _runPageChangeAnimation();
                  },
                  itemBuilder: (context, index) {
                    final p = _pages[index];
                    final c = p['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Background circle
                          ScaleTransition(
                            scale: _bgScale,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // Emoji icon
                          Transform.translate(
                            offset: const Offset(0, -110),
                            child: ScaleTransition(
                              scale: _iconScale,
                              child: RotationTransition(
                                turns: _iconRotate,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: c.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: c.withOpacity(0.3),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      p['emoji'] as String,
                                      style: const TextStyle(fontSize: 64),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Transform.translate(
                            offset: const Offset(0, -80),
                            child: Column(
                              children: [
                                FadeTransition(
                                  opacity: _textFade,
                                  child: SlideTransition(
                                    position: _textSlide,
                                    child: Text(
                                      p['title'] as String,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: c,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: _textFade,
                                  child: SlideTransition(
                                    position: _textSlide,
                                    child: Text(
                                      p['description'] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                        height: 1.6,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom Section ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isActive = _currentPage == index;
                        final dotColor =
                        _pages[index]['color'] as Color;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? dotColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        if (_currentPage > 0)
                          AnimatedOpacity(
                            opacity: _currentPage > 0 ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: OutlinedButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(
                                        milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: color,
                                  side: BorderSide(color: color),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14)),
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 18),
                              ),
                            ),
                          ),

                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPage < _pages.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(
                                        milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _finishOnboarding();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: AnimatedSwitcher(
                                duration:
                                const Duration(milliseconds: 300),
                                child: Row(
                                  key: ValueKey(_currentPage),
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentPage < _pages.length - 1
                                          ? 'Next'
                                          : 'Get Started',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentPage < _pages.length - 1
                                          ? Icons.arrow_forward_ios
                                          : Icons.rocket_launch,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '${_currentPage + 1} of ${_pages.length}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400]),
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