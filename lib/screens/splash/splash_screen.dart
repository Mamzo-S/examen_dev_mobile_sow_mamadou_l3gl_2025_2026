import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/screens/auth/login_screen.dart';
import 'package:sunu_task/screens/home/home_screen.dart';
import 'package:sunu_task/providers/app_provider.dart';
import 'package:sunu_task/screens/onboarding/onboarding_screen.dart';
import 'package:sunu_task/services/storage_service.dart';

import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _showLogo = false;
  bool _showText = false;

  // === Cycle de vie =====
  @override
  void initState() {
    super.initState();
    _startAnimations();
    _startTimer();
  }

  @override
  void dispose() {
    // Important: annuler le timer pour eviter les fuites de memoire
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 100), () {
      //mounted vérifie toujours si le widget est toujours actif
      // dans l'arbre de widget
      if(mounted) {
        setState(() => _showLogo = true);
      }
    });

    Future.delayed(Duration(milliseconds: 1500), () {
      if(mounted) {
        setState(() => _showText = true);
      }
    });
  }

  void _startTimer() {
    _timer = Timer( Duration(seconds: 3), _navigateToNextScreen);
  }

  void _navigateToNextScreen() async {
    final appProvider = context.read<AppProvider>();

    await appProvider.init();

    final bool onboardingComplete = appProvider.isOnboardingComplete;

    if(!mounted) return;
    /*Navigator.pushReplacement(context,
      MaterialPageRoute<void>(
      builder: (context) => onboardingComplete
          ? const HomeScreen()
          : const OnboardingScreen(),
    ),
    );*/

    // Navigation avec animation
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          onboardingComplete
              ? const LoginScreen()
              : const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
                opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300)
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // logo
            _buildLogo(),
            SizedBox(height: 24,),
            // Nom App
            _buildAppName(),
            SizedBox(height: 8,),
            // Slogan
            _buildAppSlogan(),

            SizedBox(height: 48,),
            //Chargement
            _buildLoadingIndicator()
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedOpacity( // Rendu fondu : Démarrage Lent puis accéleration progressive
      opacity: _showLogo ? 1 : 0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeIn,
      child: AnimatedScale( // Démarrage rapide puis décélération
        scale: _showLogo ? 1 : 0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(180),
                blurRadius: 20,
                offset: Offset(0, 10)
              )
            ]
            //shape: BoxShape.circle
          ),
          child: Icon(
            Icons.task_alt,
            size: 65,
            color: AppColors.white.withAlpha(200),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return AnimatedOpacity(
      opacity: _showText ? 1 : 0,
      duration: Duration(milliseconds: 500),
      child: Text(
        AppStrings.appName,
        style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildAppSlogan() {
    return AnimatedOpacity(
      opacity: _showText ? 1 : 0,
      duration: Duration(milliseconds: 500),
      child: Text(
        AppStrings.appSlogan,
        style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedOpacity(
      opacity: _showText ? 1 : 0,
      duration: Duration(milliseconds: 500),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 8.0,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}