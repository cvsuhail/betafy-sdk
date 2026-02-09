import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Default claim code input screen used by wrapper widgets
class DefaultClaimScreen extends StatefulWidget {
  final Future<void> Function(BuildContext, String) onClaim;

  const DefaultClaimScreen({super.key, required this.onClaim});

  @override
  State<DefaultClaimScreen> createState() => _DefaultClaimScreenState();
}

class _DefaultClaimScreenState extends State<DefaultClaimScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _verify(BuildContext scaffoldContext) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a claim code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      await widget.onClaim(scaffoldContext, code);
    } catch (e) {
      // Handle error display - use ScaffoldMessenger key or show in UI
      if (mounted) {
        // Schedule callback to ensure ScaffoldMessenger is ready
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Try using ScaffoldMessenger key
            if (_scaffoldMessengerKey.currentState != null) {
              _scaffoldMessengerKey.currentState!.showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            } else {
              // If ScaffoldMessenger key is still not ready, show error in UI
              if (mounted) {
                setState(() {
                  _error = 'Error: $e';
                });
              }
            }
          }
        });
        // Also show error in UI immediately as fallback
        setState(() {
          _error = 'Error: $e';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (scaffoldContext) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFFA855F7).withValues(alpha: 0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with gradient background
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Title
                      const Text(
                        'Beta Testing',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      const Text(
                        'Enter your unique claim code\nto join the test',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Code Input Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _codeController,
                              focusNode: _focusNode,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'XXXX-XXXX',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  letterSpacing: 4,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16,
                                ),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 24,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              onSubmitted: (_) => _verify(scaffoldContext),
                              maxLength: 9,
                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            ),
                            
                            // Error Message
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: _error != null ? null : 0,
                              child: _error != null
                                  ? Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isVerifying ? null : () => _verify(scaffoldContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                              elevation: 0,
                              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                            ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Verify Code',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Help text
                      Text(
                        'Don\'t have a code? Contact your test coordinator',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
