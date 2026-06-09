import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_icons.dart';

/// A step-by-step tutorial overlay shown on first login.
/// Wraps a child widget with tutorial tooltips pointing at relevant UI areas.
class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => TutorialOverlayState();
}

class TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;
  bool _isShowing = false;

  static const _steps = [
    _TutorialStep(
      title: 'Добро пожаловать!',
      description: 'Это карта Европы. Города — точки маршрутов, дороги между ними — линии.',
      icon: AppIcons.map,
    ),
    _TutorialStep(
      title: 'Города',
      description: 'Нажмите на город, чтобы увидеть доступные контракты и склады.',
      icon: AppIcons.locationCity,
    ),
    _TutorialStep(
      title: 'Автопарк',
      description: 'Откройте автопарк в меню слева. Купите грузовик чтобы начать!',
      icon: AppIcons.truck,
    ),
    _TutorialStep(
      title: 'Контракты',
      description: 'Примите контракт — грузовик автоматически отправится в рейс.',
      icon: AppIcons.description,
    ),
    _TutorialStep(
      title: 'Журнал событий',
      description: 'Отслеживайте прогресс и уведомления в журнале событий.',
      icon: AppIcons.history,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('tutorial_completed') ?? false;
    if (!completed && mounted) {
      setState(() => _isShowing = true);
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    setState(() => _isShowing = false);
    widget.onComplete();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _skip() => _complete();

  @override
  Widget build(BuildContext context) {
    if (!_isShowing) return widget.child;

    final step = _steps[_currentStep];

    return Stack(
      children: [
        // Dim background
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ),

        // The actual content (non-interactive during tutorial)
        IgnorePointer(
          ignoring: false,
          child: widget.child,
        ),

        // Tutorial tooltip card
        Positioned(
          bottom: _currentStep.isEven ? 120 : 160,
          left: _currentStep.isEven ? null : 20,
          right: _currentStep.isEven ? 20 : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_currentStep),
              width: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5C542).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Row(
                    children: [
                      ...List.generate(_steps.length, (i) => Container(
                        width: i == _currentStep ? 24 : 8,
                        height: 4,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: i == _currentStep
                              ? const Color(0xFFF5C542)
                              : const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Icon
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C542).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step.icon, color: const Color(0xFFF5C542), size: 22),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(step.title, style: const TextStyle(
                    color: Color(0xFFD0D0D0),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 6),
                  // Description
                  Text(step.description, style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 13,
                    height: 1.4,
                  )),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _skip,
                          child: const Text('Пропустить', style: TextStyle(color: Color(0xFF888888))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _next,
                          icon: Icon(
                            _currentStep < _steps.length - 1 ? AppIcons.arrowForward : AppIcons.check,
                            size: 16,
                          ),
                          label: Text(_currentStep < _steps.length - 1 ? 'Далее' : 'Начать'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5C542),
                            foregroundColor: const Color(0xFF1A1A1A),
                            minimumSize: const Size(double.infinity, 38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
