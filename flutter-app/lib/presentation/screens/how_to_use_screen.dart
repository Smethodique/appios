import 'package:flutter/material.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2EC),
        foregroundColor: const Color(0xFF2C2B22),
        elevation: 0,
        title: const Text('Comment utiliser l’application',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Bienvenue dans votre espace médical familial. '
              'Voici un aperçu simple pour profiter de toutes nos fonctionnalités.',
              style: TextStyle(color: Color(0xFF4B443A), fontSize: 14, height: 1.55),
            ),
          ),
          _section('1. Créer votre compte',
              'Inscrivez-vous avec votre adresse e-mail et un mot de passe sécurisé, '
              'puis vérifiez votre e-mail en cliquant sur le lien reçu. Connectez-vous '
              'ensuite pour accéder à votre espace personnel.'),
          _section('2. Ajouter vos enfants',
              'Depuis l\'onglet « Enfants », appuyez sur « + » pour créer le profil de '
              'votre enfant : nom, prénom, date de naissance et sexe. Vous pourrez ensuite '
              'suivre sa santé en détail.'),
          _section('3. Suivre la croissance',
              'Dans le dossier de votre enfant, ajoutez régulièrement son poids, sa taille '
              'et son périmètre crânien. Les courbes de croissance se mettent à jour '
              'automatiquement et vous alertent en cas d\'anomalie.'),
          _section('4. Gérer les vaccinations',
              'Retrouvez le calendrier vaccinal recommandé pour chaque âge, cochez les '
              'vaccins effectués et recevez des rappels pour les doses à venir.'),
          _section('5. Consulter le dossier médical',
              'Accédez aux consultations, ordonnances, documents et notes médicales de '
              'votre enfant, centralisés en un seul endroit sécurisé.'),
          _section('6. Prendre rendez-vous',
              'Depuis l\'onglet « Rendez-vous », choisissez un créneau disponible et '
              'réservez une consultation avec votre médecin en quelques clics.'),
          _section('7. Regarder vidéos et ressources',
              'Parcourez la bibliothèque de vidéos éducatives et de ressources PDF. Utilisez '
              'la barre de recherche ou les catégories pour trouver le contenu adapté à '
              'votre enfant.'),
          _section('8. Appels vidéo & lives',
              'Recevez les appels vidéo privés de votre médecin depuis l\'onglet « Appels », '
              'et participez aux lives interactifs pour poser vos questions en direct.'),
          _section('9. Passer au plan Family',
              'Débloquez les vidéos exclusives, les ressources avancées, le chat avec les médecins '
              'et les lives en souscrivant à un plan Family ou Family Plus.'),
          _section('10. Besoin d\'aide ?',
              'Si vous avez une question, contactez notre support à l\'adresse : '
              'support@medcin.ma. Nous sommes là pour vous aider.'),
          const SizedBox(height: 8),
          const Text(
            'Prendre soin de vos enfants, simplement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA69D8F), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF9C5B3E).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF9C5B3E), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFF4B443A), fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }
}
