import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import './widgets/pin_dots_widget.dart';
import './widgets/pin_keypad_widget.dart';

enum _LockStep { unlock, verifyOld, create, confirm }

/// Used in two ways:
///  - normal mode: shown when the app is locked, user enters PIN to open it.
///  - setupMode: opened from Settings to create or change the PIN.
class AppLockScreen extends StatefulWidget {
  final bool setupMode;

  const AppLockScreen({super.key, this.setupMode = false});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final AppStore _store = AppStore.instance;

  late _LockStep _step;
  String _enteredPin = '';
  String _firstPin = '';
  String _message = '';
  bool _isError = false;
  int _attemptsLeft = 5;
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.setupMode) {
      _step = _store.hasPin ? _LockStep.verifyOld : _LockStep.create;
    } else {
      _step = _LockStep.unlock;
    }

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _isError = false;
          });
        }
      }
    });

    if (_step == _LockStep.unlock && _store.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  String get _title {
    switch (_step) {
      case _LockStep.unlock:
        return 'Enter your PIN to continue';
      case _LockStep.verifyOld:
        return 'Enter your current PIN';
      case _LockStep.create:
        return 'Create a new 4-digit PIN';
      case _LockStep.confirm:
        return 'Confirm your new PIN';
    }
  }

  void _onKeyTap(String key) {
    if (_lockSecondsLeft > 0 || _shakeController.isAnimating) return;
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += key;
      _isError = false;
      _message = '';
    });
    if (_enteredPin.length == 4) {
      // small delay so the 4th dot is visible
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _onPinComplete();
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _isError = false;
    });
  }

  void _onPinComplete() {
    switch (_step) {
      case _LockStep.unlock:
      case _LockStep.verifyOld:
        if (_store.verifyPin(_enteredPin)) {
          HapticFeedback.mediumImpact();
          if (_step == _LockStep.unlock) {
            _store.unlock();
            context.go(AppRoutes.homeScreen);
          } else {
            setState(() {
              _step = _LockStep.create;
              _enteredPin = '';
              _attemptsLeft = 5;
            });
          }
        } else {
          _wrongPin();
        }
        break;
      case _LockStep.create:
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _step = _LockStep.confirm;
        });
        break;
      case _LockStep.confirm:
        if (_enteredPin == _firstPin) {
          HapticFeedback.mediumImpact();
          final messenger = ScaffoldMessenger.of(context);
          _store.setPin(_enteredPin);
          if (context.canPop()) context.pop();
          messenger.showSnackBar(
            const SnackBar(content: Text('PIN saved. App Lock is ON')),
          );
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _isError = true;
            _message = 'PINs did not match. Try again';
            _firstPin = '';
            _step = _LockStep.create;
          });
          _shakeController.forward();
        }
        break;
    }
  }

  void _wrongPin() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isError = true;
      _attemptsLeft--;
      _message = _attemptsLeft > 0
          ? 'Incorrect PIN — $_attemptsLeft attempts left'
          : '';
    });
    _shakeController.forward();
    if (_attemptsLeft <= 0) _startLockout();
  }

  void _startLockout() {
    setState(() => _lockSecondsLeft = 30);
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _lockSecondsLeft--);
      if (_lockSecondsLeft <= 0) {
        t.cancel();
        setState(() {
          _attemptsLeft = 5;
          _isError = false;
          _message = '';
          _enteredPin = '';
        });
      }
    });
  }

  Future<void> _tryBiometric() async {
    if (_step != _LockStep.unlock || !_store.biometricEnabled) return;
    _store.authInProgress = true;
    final ok = await BiometricService.authenticate('Unlock SmartNotepad');
    // keep the flag for a moment so the resume event does not re-lock
    Future.delayed(const Duration(seconds: 1), () {
      _store.authInProgress = false;
    });
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      _store.unlock();
      context.go(AppRoutes.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final showBio = !widget.setupMode && _store.biometricEnabled;

    Widget content = Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'lock',
              color: theme.colorScheme.primary,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SmartNotepad',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _lockSecondsLeft > 0
              ? 'Too many attempts. Try again in $_lockSecondsLeft s'
              : _title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: _lockSecondsLeft > 0
                ? AppTheme.errorColor
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shakeOffset = _shakeController.isAnimating
                ? (8 *
                          (_shakeAnimation.value % 0.25 < 0.125
                              ? _shakeAnimation.value % 0.25 / 0.125
                              : 1 -
                                    (_shakeAnimation.value % 0.25 - 0.125) /
                                        0.125) -
                      4)
                : 0.0;
            return Transform.translate(
              offset: Offset(shakeOffset * 6, 0),
              child: child,
            );
          },
          child: PinDotsWidget(
            pinLength: 4,
            filledCount: _enteredPin.length,
            isError: _isError,
          ),
        ),
        SizedBox(
          height: 36,
          child: _message.isNotEmpty
              ? Center(
                  child: Text(
                    _message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : null,
        ),
        const Spacer(flex: 1),
        PinKeypadWidget(
          onKeyTap: _onKeyTap,
          onBackspace: _onBackspace,
          onBiometric: _tryBiometric,
          showBiometric: showBio,
        ),
        const Spacer(flex: 2),
      ],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            isTablet
                ? Center(child: SizedBox(width: 400, child: content))
                : content,
            if (widget.setupMode)
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
