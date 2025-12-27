# Guide de Migration Firebase - evenvo-ba568

## ✅ Modifications effectuées

### 1. Configuration Flutter mise à jour
- `lib/firebase_options.dart` ✅
- `firebase_options.dart` (racine) ✅
- `lib/screens/firebase_options.dart` ✅
- `firebase.json` ✅
- `android/app/google-services.json` ✅
- `ios/Runner/GoogleService-Info.plist` ✅

### 2. Configuration serveur Node.js mise à jour
- `Evenvo-Demo/server.js` ✅
- Fichier service account temporaire créé ✅

## 🔧 Actions requises

### 1. Obtenir le vrai fichier de service account

**Étapes à suivre :**

1. **Aller sur la Console Firebase**
   - Ouvrir https://console.firebase.google.com/
   - Sélectionner le projet `evenvo-ba568`

2. **Accéder aux paramètres du projet**
   - Cliquer sur l'icône ⚙️ (Paramètres du projet)
   - Aller dans l'onglet "Comptes de service"

3. **Générer une nouvelle clé privée**
   - Cliquer sur "Générer une nouvelle clé privée"
   - Télécharger le fichier JSON

4. **Remplacer le fichier temporaire**
   - Renommer le fichier téléchargé en `evenvo-ba568-firebase-adminsdk.json`
   - Remplacer le fichier dans `Evenvo-Demo/evenvo-ba568-firebase-adminsdk.json`

### 2. Configurer les applications mobiles (si nécessaire)

**Pour Android :**
- Aller dans Console Firebase > Paramètres du projet > Applications
- Ajouter une application Android si pas encore fait
- Télécharger le nouveau `google-services.json`
- Remplacer dans `android/app/google-services.json`

**Pour iOS :**
- Ajouter une application iOS si pas encore fait
- Télécharger le nouveau `GoogleService-Info.plist`
- Remplacer dans `ios/Runner/GoogleService-Info.plist`

## 🧪 Test de la configuration

### 1. Tester l'application Flutter
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-renderer html
```

### 2. Tester le serveur Node.js
```bash
cd Evenvo-Demo
node server.js
```

### 3. Vérifications
- ✅ Application Flutter se connecte à la nouvelle base
- ✅ Serveur Node.js démarre sans erreur
- ✅ Authentification fonctionne
- ✅ Données Firestore accessibles

## 📋 Nouvelle configuration Firebase

**Projet :** evenvo-ba568
**ID du projet :** evenvo-ba568
**Numéro du projet :** 647067484176

**Configuration web :**
```javascript
{
  apiKey: "AIzaSyDpLgR7glKjSIsgT66wSxMn8FhX_4hddLM",
  authDomain: "evenvo-ba568.firebaseapp.com",
  projectId: "evenvo-ba568",
  storageBucket: "evenvo-ba568.firebasestorage.app",
  messagingSenderId: "647067484176",
  appId: "1:647067484176:web:c9d3ec3e2d116a53528a95",
  measurementId: "G-429KZ0X69X"
}
```

## ⚠️ Important

1. **Sauvegarder les données** de l'ancien projet si nécessaire
2. **Migrer les données** vers le nouveau projet si requis
3. **Mettre à jour les règles de sécurité** Firestore dans le nouveau projet
4. **Configurer l'authentification** dans la console Firebase
5. **Tester toutes les fonctionnalités** après migration

## 🔄 Rollback (si problème)

Si des problèmes surviennent, vous pouvez revenir à l'ancienne configuration en :
1. Remettant les anciens fichiers de configuration
2. Utilisant l'ancien service account
3. Redéployant avec l'ancienne configuration

La migration est maintenant prête ! Il suffit d'obtenir le vrai fichier de service account depuis la console Firebase.