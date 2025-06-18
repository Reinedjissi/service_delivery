import 'package:flutter/material.dart';
import 'package:service_delivery/app/auth/view/Login_page.dart';
import 'package:service_delivery/core/utils/asset_path.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MyOnboarding extends StatefulWidget {
  static const String routeName = '/onboarding';

  const MyOnboarding({super.key});

  @override
  State<MyOnboarding> createState() => _MyOnboardingState();
}

class _MyOnboardingState extends State<MyOnboarding> {
  final PageController controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: controller,
          onPageChanged: (index) {
            setState(() {
              isLastPage = index == 3;
            });
          },
          children: [
            // First page
            buildImageContainer(
              Colors.white,
              'Bienvenue dans notre marketplace de services !',
              "Nous sommes ravis de vous accueillir parmi nous, votre plateforme de choix pour découvrir et accéder à une multitude de services de qualité. Que vous soyez à la recherche d'un professionnel pour réaliser un projet ou que vous souhaitiez proposer vos compétences, vous êtes au bon endroit. Explorez nos offres et découvrez comment nous pouvons répondre à vos besoins.",
              AssetPath.onboardingImg1,
            ),
            // Second page
            buildImageContainer(
              Colors.white,
              "Profitez d'une expérience inégalée",
              "En nous rejoignant, vous accédez à de nombreux avantages. Clients, profitez de services de qualité, d'un processus de réservation simple et de la possibilité de comparer plusieurs offres. Prestataires, bénéficiez d'une visibilité accrue, d'outils pour gérer vos offres et d'une communauté de clients prêts à découvrir vos talents. Notre marketplace favorise des relations de confiance et de collaboration entre clients et prestataires.",
              AssetPath.onboardingImg2,
            ),
            // Third page
            buildImageContainer(
              Colors.white,
              'Des fonctionnalités conçues pour vous !',
              "Bénéficiez d'une expérience unique pour découvrir et offrir des services variés. Parcourez facilement notre catalogue de services, de la conception graphique à la rédaction, en passant par le coaching et le développement web. Utilisez notre moteur de recherche pour trouver le professionnel idéal, consultez les avis des clients et discutez directement avec les prestataires avant de faire votre choix. Notre plateforme est conçue pour faciliter chaque étape de votre expérience.",
              AssetPath.onboardingImg3,
            ),
            // Last page
            buildImageContainer(
              Colors.white,
              "Prêt à commencer ?",
              "Ne perdez pas de temps ! Inscrivez-vous dès maintenant pour explorer notre vaste sélection de services ou pour proposer vos compétences. En nous rejoignant, vous aurez accès à des opportunités passionnantes, des projets stimulants et une communauté engagée. Faites le premier pas vers une expérience de service enrichissante et connectez-vous avec des professionnels qui partagent votre vision !",
              AssetPath.onboardingImg3,
            ),
          ],
        ),
      ),
      bottomSheet: isLastPage
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.deepPurple[300],
            minimumSize: const Size.fromHeight(70),
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, LoginPage.routeName);
          },
          child: const Text(
            "Commencer",
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      )
          : Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TextButton for skip
            TextButton(
              onPressed: () {
                controller.jumpToPage(3);
              },
              child: const Text(
                "Passer",
                style: TextStyle(fontSize: 18),
              ),
            ),
            // Smooth page indicator
            SmoothPageIndicator(
              controller: controller,
              count: 4,
              effect: WormEffect(
                spacing: 15,
                dotColor: Colors.purple.shade300,
                activeDotColor: Colors.purple,
              ),
              onDotClicked: (index) {
                controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
            ),
            // TextButton for next
            TextButton(
              onPressed: () {
                controller.nextPage(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text(
                "Suivant",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImageContainer(Color color, String title, String description, String imagePath) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Utilisation d'Expanded pour que l'image prenne l'espace disponible
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover, // Adapter l'image pour couvrir tout l'espace
              width: double.infinity, // Prendre toute la largeur disponible
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(description, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}