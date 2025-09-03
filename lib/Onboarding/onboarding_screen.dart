import 'package:flutter/material.dart';
import 'package:qoute_gallery_app/constants/colors.dart';
import 'package:qoute_gallery_app/constants/images.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qoute_gallery_app/homepages/homescreen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Homescreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          Center(child: Image.asset(AppImages.logo, width: 200, height: 200,)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitThreeBounce(
                    color: AppColors.textColor,
                    size: 24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please wait for a moment...',
                    style: TextStyle(color: AppColors.textColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}