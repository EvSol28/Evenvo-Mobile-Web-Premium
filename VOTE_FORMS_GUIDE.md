# Guide des Formulaires de Vote Dynamiques - Evenvo

## Vue d'ensemble

Ce système permet de créer des formulaires de vote personnalisés via le dashboard administrateur et de les afficher dans l'application mobile pour que les utilisateurs puissent voter.

## Architecture

### 1. Dashboard (Evenvo-Demo)
- **Page de gestion** : `views/gestion_event.ejs` - Nouvelle carte "Formulaire de Vote"
- **Form Builder** : `views/vote_form_builder.ejs` - Interface drag & drop pour créer des formulaires
- **Routes serveur** : `server.js` - APIs pour gérer les formulaires

### 2. Application Mobile (evenvo_mobile_web)
- **Écran de vote simple** : `lib/screens/vote_screen.dart` - Vote Oui/Non/Abstention existant
- **Écran de formulaires dynamiques** : `lib/screens/dynamic_vote_screen.dart` - Affiche les formulaires créés
- **Navigation** : `lib/screens/user_profile_screen.dart` - Boutons pour accéder aux deux types de vote

## Fonctionnalités du Form Builder

### Types de champs supportés :
1. **Texte court** - Champ de saisie simple
2. **Texte long** - Zone de texte multiligne
3. **Choix unique** - Boutons radio
4. **Choix multiple** - Cases à cocher
5. **Liste déroulante** - Menu de sélection
6. **Nombre** - Champ numérique
7. **Date** - Sélecteur de date
8. **Évaluation** - Système d'étoiles (1-5)

### Fonctionnalités :
- **Drag & Drop** : Glisser-déposer des éléments
- **Édition en ligne** : Modifier les libellés et propriétés
- **Aperçu** : Voir le formulaire avant sauvegarde
- **Gestion** : Activer/désactiver/supprimer les formulaires
- **Validation** : Champs obligatoires

## Base de données Firestore

### Collections créées :

#### `vote_forms`
```javascript
{
  id: "auto-generated",
  eventId: "event_id",
  name: "Nom du formulaire",
  description: "Description optionnelle",
  fields: [
    {
      id: "field_1",
      type: "radio",
      label: "Question 1",
      required: true,
      options: ["Option 1", "Option 2"]
    }
  ],
  isActive: true,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### `vote_responses`
```javascript
{
  id: "auto-generated",
  eventId: "event_id",
  formId: "form_id",
  userId: "user_id",
  responses: {
    "field_1": "Option 1",
    "field_2": ["Choix A", "Choix B"],
    "field_3": 4
  },
  submittedAt: timestamp
}
```

## APIs créées

### Dashboard (Node.js/Express)

1. **GET** `/event/:eventId/vote_form_builder`
   - Affiche la page du form builder
   - Récupère les formulaires existants

2. **POST** `/event/:eventId/save_vote_form`
   - Sauvegarde un nouveau formulaire
   - Body: `{ formName, formDescription, formFields, isActive }`

3. **POST** `/event/:eventId/toggle_vote_form/:formId`
   - Active/désactive un formulaire
   - Body: `{ isActive }`

4. **DELETE** `/event/:eventId/delete_vote_form/:formId`
   - Supprime un formulaire

### Application Mobile

1. **GET** `/api/event/:eventId/active_vote_forms`
   - Récupère les formulaires actifs pour un événement
   - Utilisé par l'app mobile

2. **POST** `/api/event/:eventId/submit_vote`
   - Soumet une réponse de vote
   - Body: `{ formId, userId, responses }`
   - Vérifie les doublons (un vote par utilisateur par formulaire)

## Utilisation

### Côté Administrateur (Dashboard)

1. **Accéder à la gestion d'événement**
   - Aller sur `/event/{eventId}/gestion_event`
   - Cliquer sur la nouvelle carte "Formulaire de Vote"

2. **Créer un formulaire**
   - Glisser-déposer des éléments depuis la barre latérale
   - Configurer les libellés et options
   - Prévisualiser le formulaire
   - Sauvegarder

3. **Gérer les formulaires**
   - Activer/désactiver selon les besoins
   - Modifier ou supprimer les formulaires existants

### Côté Utilisateur (App Mobile)

1. **Accéder aux votes**
   - Se connecter via QR code
   - Aller sur l'écran de profil utilisateur
   - Choisir entre "Vote Simple" ou "Formulaires de Vote"

2. **Répondre aux formulaires**
   - Voir tous les formulaires actifs
   - Remplir les champs requis
   - Soumettre les réponses

## Configuration requise

### Dashboard
- Node.js avec Express
- Firebase Admin SDK
- EJS pour les templates
- Bootstrap 5 + Font Awesome pour l'UI

### Application Mobile
- Flutter
- Firebase (Auth + Firestore)
- Package HTTP pour les appels API

## Sécurité

- **Authentification** : Vérification des utilisateurs via Firebase Auth
- **Permissions** : Contrôle des droits de vote par rôle
- **Validation** : Vérification des doublons de vote
- **Sanitisation** : Nettoyage des données d'entrée

## Améliorations futures

1. **Logique conditionnelle** : Afficher des champs selon les réponses précédentes
2. **Templates** : Formulaires pré-définis réutilisables
3. **Statistiques** : Graphiques des résultats en temps réel
4. **Export** : Téléchargement des résultats en CSV/PDF
5. **Notifications** : Alertes pour nouveaux formulaires
6. **Validation avancée** : Règles de validation personnalisées

## Dépannage

### Erreurs communes

1. **"Erreur de connexion au serveur"**
   - Vérifier que le serveur Node.js est démarré
   - Vérifier l'URL dans `dynamic_vote_screen.dart` (localhost:4000)

2. **"Aucun formulaire disponible"**
   - Vérifier que des formulaires sont créés et activés dans le dashboard
   - Vérifier les règles Firestore

3. **"Vous avez déjà voté"**
   - Normal, un utilisateur ne peut voter qu'une fois par formulaire
   - Pour tester, supprimer les entrées dans `vote_responses`

### Logs utiles
- Console du navigateur (dashboard)
- Logs Flutter (app mobile)
- Logs serveur Node.js
- Console Firebase (Firestore)