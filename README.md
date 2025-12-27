# Evenvo Mobile - Formulaire de Vote

Application mobile Flutter avec backend Node.js pour la gestion de formulaires de vote lors d'événements.

## 🚀 Fonctionnalités

- **Authentification par QR Code** : Scan de QR codes pour l'authentification des utilisateurs
- **Formulaires de vote dynamiques** : Création et gestion de formulaires de vote personnalisés
- **Interface responsive** : Compatible mobile et web
- **Backend Node.js** : API REST pour la gestion des données
- **Firebase Integration** : Authentification et base de données Firestore

## 📱 Technologies utilisées

### Frontend (Flutter)
- Flutter Web & Mobile
- Firebase Authentication
- HTTP requests
- QR Code Scanner
- Responsive Design

### Backend (Node.js)
- Express.js
- Firebase Admin SDK
- Firestore Database
- EJS Templates
- CSV Import/Export

## 🛠️ Installation et Configuration

### Prérequis
- Flutter SDK
- Node.js et npm
- Compte Firebase

### Configuration Firebase
1. Créez un projet Firebase
2. Activez Authentication et Firestore
3. Générez les clés de configuration :
   - `firebase_options.dart` pour Flutter
   - Service account JSON pour Node.js

### Installation Flutter
```bash
flutter pub get
flutter run -d chrome --web-port=63998
```

### Installation Backend
```bash
cd Evenvo-Demo
npm install
npm start
```

Le serveur démarre sur le port 4001.

## 🔧 Configuration

### Variables d'environnement
Créez un fichier `.env` dans le dossier `Evenvo-Demo/` :
```env
DEFAULT_ADMIN_EMAIL=admin@example.com
DEFAULT_ADMIN_PASSWORD=your_password
GOOGLE_APPLICATION_CREDENTIALS=./path-to-service-account.json
```

### Domaines autorisés Firebase
Ajoutez vos domaines dans Firebase Console → Authentication → Settings → Authorized domains :
- `localhost` (pour le développement)
- Votre domaine de production

## 📚 Structure du projet

```
evenvo_mobile_web/
├── lib/                          # Code Flutter
│   ├── screens/                  # Écrans de l'application
│   └── ...
├── Evenvo-Demo/                  # Backend Node.js
│   ├── server.js                 # Serveur principal
│   ├── views/                    # Templates EJS
│   └── ...
├── web/                          # Configuration web Flutter
├── firebase_options.dart         # Configuration Firebase Flutter
└── README.md
```

## 🚀 Déploiement

### Flutter Web
```bash
flutter build web
```

### Backend Node.js
Le backend peut être déployé sur des plateformes comme :
- Render
- Heroku
- Google Cloud Run
- AWS

## 🔐 Sécurité

⚠️ **Important** : Les fichiers suivants contiennent des informations sensibles et ne doivent pas être commités :
- `**/evenvo-ba568-firebase-adminsdk-*.json`
- `service-account.json`
- `.env`

Ces fichiers sont exclus via `.gitignore`.

## 📖 Utilisation

1. **Authentification** : Scannez un QR code contenant les informations utilisateur
2. **Sélection d'événement** : Choisissez l'événement auquel participer
3. **Formulaires de vote** : Accédez aux formulaires de vote actifs
4. **Soumission** : Remplissez et soumettez vos réponses

## 🤝 Contribution

1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT.

## 📞 Support

Pour toute question ou problème, ouvrez une issue sur GitHub.