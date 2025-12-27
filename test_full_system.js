// Script de test complet du système de formulaires de vote
const http = require('http');

console.log('🧪 Test complet du système de formulaires de vote\n');

// Test 1: Vérifier que le serveur backend fonctionne
console.log('1️⃣ Test du serveur backend (port 4001)...');
http.get('http://localhost:4001/api/event/Event_1/active_vote_forms', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        if (res.statusCode === 200) {
            const json = JSON.parse(data);
            console.log('✅ Backend OK - Formulaires trouvés:', json.voteForms.length);
            
            // Test 2: Vérifier l'application web
            console.log('\n2️⃣ Test de l\'application web (port 8080)...');
            http.get('http://localhost:8080/', (webRes) => {
                if (webRes.statusCode === 200) {
                    console.log('✅ Application web OK');
                    console.log('\n🎉 Système complet fonctionnel !');
                    console.log('\n📋 Instructions:');
                    console.log('1. Ouvrez http://localhost:8080 dans votre navigateur');
                    console.log('2. Connectez-vous avec un QR code');
                    console.log('3. Cliquez sur "Formulaires de Vote"');
                    console.log('4. Vous devriez voir les formulaires sans erreur');
                } else {
                    console.log('❌ Application web non accessible');
                }
                process.exit(0);
            }).on('error', () => {
                console.log('❌ Application web non accessible (port 8080)');
                console.log('💡 Lancez: python -m http.server 8080 dans le dossier build/web');
                process.exit(1);
            });
        } else {
            console.log('❌ Backend non accessible');
        }
    });
}).on('error', () => {
    console.log('❌ Backend non accessible (port 4001)');
    console.log('💡 Lancez: node server.js dans le dossier Evenvo-Demo');
    process.exit(1);
});