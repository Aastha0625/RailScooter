import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _trainAnimController;

  @override
  void initState() {
    super.initState();
    // Seamless floating loop animation
    _trainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _trainAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The specific colors from the provided design
    const Color bgColor = Color(0xFF0A1118); // Deep navy background
    const Color glowColor = Color(0xFFF97316); // Orange glow
    const Color bronzeColor = Color(0xFFA68064); // Train figure color
    const Color buttonDark = Color(0xFF111E2D); // Dark button color

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background grid/line effect
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          // Subtle center glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.05),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // TOP HEADER: PiSolve Logo (Bypass width constraints to make it massive)
                  Center(
                    child: Transform.scale(
                      scale: 3.6, // Doubled from 1.8
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80, // Increased raw height
                        fit: BoxFit.fitHeight, // Forces it to grow vertically, pushing transparent edges off-screen
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // MAIN FIGURE: Animated Floating Transit Icon
                  SizedBox(
                    height: 150, // Fixed layout height so surrounding text NEVER moves
                    child: AnimatedBuilder(
                      animation: _trainAnimController,
                      builder: (context, child) {
                        final animValue = _trainAnimController.value;
                        
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ground Railway Tracks (Static, fading into darkness)
                            Transform.translate(
                              offset: const Offset(0, 80),
                              child: CustomPaint(
                                size: const Size(120, 60),
                                painter: _TrackPainter(color: bronzeColor.withValues(alpha: 0.15)),
                              ),
                            ),
                            
                            // Ground Reflection Glow
                            Transform.translate(
                              offset: const Offset(0, 60),
                              child: Container(
                                width: 100 - (30 * animValue),
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: bronzeColor.withValues(alpha: 0.5 - (0.3 * animValue)),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Train and Aura
                            Transform.translate(
                              offset: Offset(0, -20 * animValue), // Floats up 20px
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Inner Intense Glow (Static size so it doesn't break layout)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: bronzeColor.withValues(alpha: 0.4 + (0.2 * animValue)),
                                          blurRadius: 40,
                                          spreadRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Train Icon itself
                                  const Icon(
                                    Icons.directions_transit_rounded,
                                    color: bronzeColor,
                                    size: 110,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // TITLE: PiScoot
                  const Text(
                    'PiScoot',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // SUBTITLE: Next-Gen Railway...
                  const Text(
                    'Next-Gen Railway Fleet\nManagement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFB923C), // Orange text
                      fontSize: 22,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // DESCRIPTION
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Optimize track maintenance operations\nwith real-time GPS tracking and automated\nassignments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // BUTTONS
                  // Get Started Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(initialSignUp: true),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: glowColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF431407)),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Color(0xFF431407), size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Log In Button (Replaced Watch Demo)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(initialSignUp: false),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.withValues(alpha: 0.1), width: 1),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the faint vertical center line and subtle dots
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    // Faint vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Subtle background dots
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 0.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for the subtle perspective railway tracks
class _TrackPainter extends CustomPainter {
  final Color color;

  _TrackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a fading gradient for the tracks
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color,
        color.withValues(alpha: 0.0), // Fade into darkness at the bottom
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Perspective rails (narrow at top, wide at bottom)
    final path = Path();
    
    // Left rail
    final topXLeft = size.width * 0.35;
    final topXRight = size.width * 0.65;
    final bottomXLeft = size.width * 0.1;
    final bottomXRight = size.width * 0.9;
    
    path.moveTo(topXLeft, 0);
    path.lineTo(bottomXLeft, size.height);
    
    // Right rail
    path.moveTo(topXRight, 0);
    path.lineTo(bottomXRight, size.height);

    canvas.drawPath(path, paint);

    // Horizontal wooden ties
    paint.strokeWidth = 2.0;
    
    // Draw 4 ties with increasing spacing and width to simulate 3D perspective
    const tiesCount = 4;
    for (int i = 0; i < tiesCount; i++) {
      // Non-linear spacing for 3D effect (closer together at the top)
      final progress = (i / (tiesCount - 1));
      final easedProgress = progress * progress; // Quadratic ease-in for perspective
      
      final y = size.height * easedProgress;
      
      // Calculate X positions for this Y
      final currentLeftX = topXLeft + (bottomXLeft - topXLeft) * easedProgress;
      final currentRightX = topXRight + (bottomXRight - topXRight) * easedProgress;
      
      // Extend ties slightly past the rails
      final extension = 10.0 * (0.5 + easedProgress);
      
      canvas.drawLine(
        Offset(currentLeftX - extension, y), 
        Offset(currentRightX + extension, y), 
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
