#!/usr/bin/env python3
import http.server
import socketserver
import os
import webbrowser
from pathlib import Path

# Changer vers le répertoire build/web
build_dir = Path("build/web")
if not build_dir.exists():
    print("❌ Le répertoire build/web n'existe pas.")
    print("🔧 Exécutez d'abord: flutter build web --release")
    exit(1)

os.chdir(build_dir)

PORT = 8080

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Désactiver le cache pour forcer le rechargement
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    print(f"🚀 Serveur de test démarré sur http://localhost:{PORT}")
    print("📱 Testez l'application mobile localement avec la dernière version")
    print("🔧 Cache désactivé pour forcer le rechargement")
    print("⏹️  Appuyez sur Ctrl+C pour arrêter")
    
    # Ouvrir automatiquement le navigateur
    webbrowser.open(f"http://localhost:{PORT}")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Serveur arrêté")