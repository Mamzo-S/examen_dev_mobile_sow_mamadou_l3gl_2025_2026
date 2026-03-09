import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/OnboardingItem.dart';
import 'package:sunu_task/providers/app_provider.dart';
import 'package:sunu_task/screens/home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
        icon: Icons.task_alt,
        title: AppStrings.onboardingTitle1,
        description: AppStrings.onboardingDesc1,
        color: AppColors.primary
    ),
    OnboardingItem(
      icon: Icons.people,
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      color: AppColors.secondary,
    ),
    OnboardingItem(
      icon: Icons.calendar_today,
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      color: AppColors.warningLight,
    ),
  ];

  //====== Cycle de vie =========
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  //====== Methodes ========
  void _nextPage() {
    if(_currentPage < _pages.length - 1){
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await context.read<AppProvider>().completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipButton(),

            _buildPages(),

            _buildNavigationButtons()
          ],
        )
      )
    );
  }

  Widget _buildSkipButton() {
    if(_currentPage != _pages.length -1) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
            onPressed: _completeOnboarding,
            child: Text(
                AppStrings.skip,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                )
            )
        ),
      );
    }

    return SizedBox();
  }

  Widget _buildPages() {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemBuilder: (context, index){
          return _buildPage(_pages[index]);
        },
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
                color: item.color.withAlpha(100),
                shape: BoxShape.circle,
              //shape: BoxShape.circle
            ),
            child: Icon(
              item.icon,
              size: 80,
              color: item.color,
            ),
          ),

          SizedBox(height: 48,),

          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 16,),

          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button - visible when not on first page
          Visibility(
              visible: _currentPage > 0,
              child: TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut
                    );
                  },
                  child: Text(
                      AppStrings.previous,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      )
                  )
              )
          ),

          ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                  isLastPage ? AppStrings.getStarted : AppStrings.next,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  )
              )
          ),
        ],
      ),
    );
  }

}
