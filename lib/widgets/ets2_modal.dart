import 'package:flutter/material.dart';
import '../config/app_icons.dart';
import '../services/sound_manager.dart';

/// Shared ETS2-style modal dialog wrapper.
/// All modal screens use this as their root widget instead of Scaffold.
class ETS2Modal extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final List<Widget>? actions;

  const ETS2Modal({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 8,
        vertical: isDesktop ? 40 : 20,
      ),
      child: Container(
        width: isDesktop ? 620 : size.width * 0.94,
        height: isDesktop ? 620 : size.height * 0.78,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF444444)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2C),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF444444), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFFF5C542), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFD0D0D0),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions!,
                      IconButton(
                        icon: const Icon(AppIcons.close, color: Color(0xFF999999), size: 20),
                        onPressed: () { SoundManager.instance.tap(); Navigator.pop(context); },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: Container(
                    color: const Color(0xFF1A1A1A),
                    child: child,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

