# Configuration de Déploiement - Evenvo Mobile Vote

## 🚨 Configuration Requise pour la Production

### Étape 1: Déployer le Backend (Evenvo-Demo)

Votre backend doit être déployé sur une plateforme cloud. Options recommandées :

1. **Render** (recommandé)
   - Créer un nouveau service Web sur Render
   - Connecter le repository `Evenvo-Demo`
   - Configurer les variables d'environnement Firebase
   - Noter l'URL générée (ex: `https://evenvo-demo-xyz.onrender.com`)

2. **Heroku**
   - Déployer le dossier `Evenvo-Demo`
   - Configurer les variables d'environnement
   - Noter l'URL générée

### Étape 2: Configurer l'URL du Backend

1. **Ouvrir** `lib/config/api_config.dart`
2. **Remplacer** la ligne :
   ```dart
   return 'https://CHANGEZ-MOI-URL-BACKEND.onrender.com';
   ```
   
   Par votre vraie URL backend :
   ```dart
   return 'https://votre-backend-reel.onrender.com';
   ```

### Étape 3: Recompiler et Redéployer

```bash
# Nettoyer et recompiler
flutter clean
flutter build web

# Redéployer sur Render ou votre plateforme
# Les fichiers à déployer sont dans build/web/
```

## 🔧 URLs Actuelles

- **Frontend (Mobile Web)** : https://evenvo-mobile-vote.onrender.com
- **Backend (Dashboard)** : ❌ **NON CONFIGURÉ** - À déployer !

## 🐛 Erreurs Communes

### "failed to fetch" en production
- ✅ **Cause** : Backend pas déployé ou URL incorrecte
- ✅ **Solution** : Déployer le backend et configurer l'URL

### "CORS error" 
- ✅ **Cause** : Backend ne permet pas les requêtes cross-origin
- ✅ **Solution** : Vérifier la configuration CORS dans `server.js`

### "404 Not Found"
- ✅ **Cause** : Routes API non disponibles sur le backend déployé
- ✅ **Solution** : Vérifier que toutes les routes sont déployées

## 📋 Checklist de Déploiement

- [ ] Backend déployé sur une plateforme cloud
- [ ] URL du backend configurée dans `api_config.dart`
- [ ] Variables d'environnement Firebase configurées
- [ ] Application recompilée avec `flutter build web`
- [ ] Frontend redéployé avec la nouvelle configuration
- [ ] Test complet du système en production

## 🆘 Support

Si vous avez des problèmes :
1. Vérifiez les logs du backend déployé
2. Testez les APIs directement avec l'URL backend
3. Vérifiez la console du navigateur pour les erreurs détaillées