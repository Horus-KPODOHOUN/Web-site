import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nonvis/screens/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();
  void _onIntroEnd(BuildContext context) async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  Widget _buildImage(String imageName, [double width = 250]) {
    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/$imageName',
          width: width,
          height: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo,
                    size: 60,
                    color: const Color(0xFFE91E63),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image non trouvée',
                    style: TextStyle(
                      color: const Color(0xFFE91E63),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4A148C),
        fontFamily: 'Poppins',
      ),
      bodyTextStyle: TextStyle(
        fontSize: 16.0,
        color: Colors.black87,
        height: 1.5,
        fontFamily: 'Poppins',
      ),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
      contentMargin: EdgeInsets.all(16),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: IntroductionScreen(
        key: introKey,
        globalBackgroundColor: Colors.white,
        pages: [
          PageViewModel(
            title: "Bienvenue sur NONVI",
            body:
                "Ton alliée confidentielle pour ta santé féminine. Suis ton cycle, comprends ton corps et prends soin de toi avec notre accompagnement personnalisé.",
            image: _buildImage('logo1.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Quel est ton objectif ?",
            body:
                "Choisis ce qui correspond le mieux à tes besoins actuels. Tu pourras modifier cela plus tard selon ton évolution.",
            image: _buildImage('logo.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Parle-moi de ton cycle",
            body:
                "Ces informations nous aideront à personnaliser ton expérience et à te donner des prédictions précises de ton cycle menstruel.",
            image: _buildImage('logo.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Configure tes rappels",
            body:
                "Choisis comment tu veux être notifiée. Tes données restent 100% confidentielles et sécurisées.",
            image: _buildImage('logo.png'),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onIntroEnd(context),
        onSkip: () => _onIntroEnd(context),
        showSkipButton: true,
        skipOrBackFlex: 0,
        nextFlex: 0,
        showBackButton: false,
        skip: const Text(
          'Passer',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        next: const Icon(
          Icons.arrow_forward,
          color: Color(0xFFE91E63),
        ),
        done: const Text(
          'Commencer',
          style: TextStyle(
            color: Color(0xFFE91E63),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        dotsDecorator: const DotsDecorator(
          size: Size(10.0, 10.0),
          color: Color(0xFFBDBDBD),
          activeSize: Size(22.0, 10.0),
          activeColor: Color(0xFFE91E63),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
        dotsContainerDecorator: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
        ),
      );
  }
}