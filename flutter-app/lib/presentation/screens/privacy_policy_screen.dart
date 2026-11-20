import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Politique de confidentialité',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _section('1. Qui sommes-nous ?',
              'L\'application Medcin est un espace médical familial permettant de suivre la santé de vos '
              'enfants : profils enfants, rendez-vous, vaccinations, courbes de croissance, documents '
              'médicaux, vidéos éducatives, consultations et abonnements.'),
          _section('2. Données collectées',
              'Nous collectons uniquement les données nécessaires au bon fonctionnement du service :\n'
              '• Identité : nom, email et mot de passe (chiffré).\n'
              '• Données de santé déclarées : informations santé des enfants (vaccinations, mesures de '
              'croissance, documents médicaux) que vous nous transmettez volontairement.\n'
              '• Données d\'utilisation : échanges avec le service client et préférences de navigations.'),
          _section('3. Finalités du traitement',
              'Vos données sont utilisées pour :\n'
              '• Créer et gérer votre compte.\n'
              '• Assurer le suivi médical de vos enfants (carnet de santé numérique).\n'
              '• Gérer vos abonnements et facturations.\n'
              '• Vous envoyer des notifications liées à votre activité.\n'
              '• Améliorer nos services et notre expérience utilisateur.'),
          _section('4. Base légale',
              'Le traitement de vos données repose sur :\n'
              '• Votre consentement lors de la création du compte.\n'
              '• L\'exécution du contrat de service que vous acceptez en vous inscrivant.'),
          _section('5. Conservation des données',
              'Vos données sont conservées aussi longtemps que nécessaire à la fourniture du service. '
              'À la suppression de votre compte, vos données sont supprimées ou anonymisées dans un '
              'délai maximal de 30 jours, sauf obligation légale contraire.'),
          _section('6. Partage des données',
              'Vos données ne sont jamais vendues à des tiers. Elles peuvent être partagées uniquement '
              'avec des prestataires techniques (hébergement, paiement, notifications) agissant sous '
              'notre contrôle et dans le respect de la confidentialité.'),
          _section('7. Sécurité',
              'Nous mettons en œuvre des mesures techniques et organisationnelles pour protéger vos '
              'données : chiffrement des mots de passe, connexion sécurisée (HTTPS), contrôle d\'accès '
              'strict et audits réguliers.'),
          _section('8. Vos droits',
              'Conformément à la loi 09-08 (Maroc) et au RGPD (UE), vous disposez des droits suivants :\n'
              '• Droit d\'accès, de rectification et d\'effacement.\n'
              '• Droit à la portabilité de vos données.\n'
              '• Droit d\'opposition ou de limitation du traitement.\n'
              '• Droit de retirer votre consentement à tout moment.'),
          _section('9. Contact',
              'Pour toute question ou demande relative à vos données personnelles, contactez-nous à : '
              'support@medcin.ma'),
          _section('10. Modifications',
              'La présente politique peut être mise à jour. Toute modification significative vous sera '
              'notifiée via l\'application.'),
          const SizedBox(height: 8),
          const Text(
            'Dernière mise à jour : septembre 2026',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA69D8F), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFBD7F66), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFF4B443A), fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }
}