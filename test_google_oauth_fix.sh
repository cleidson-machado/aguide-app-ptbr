#!/bin/bash

# 🧪 Script de Teste - Google OAuth Redirect Fix
# Executa rebuild completo e testa login com Google
# Data: 14/02/2026

set -e  # Parar em caso de erro

echo "🧹 Passo 1/4: Limpando build anterior..."
flutter clean

echo "📦 Passo 2/4: Obtendo dependências Flutter..."
flutter pub get

echo "🗑️ Passo 3/4: Removendo Pods iOS e reinstalando..."
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

echo "🚀 Passo 4/4: Iniciando app no simulador..."
echo ""
echo "============================================"
echo "✅ BUILD CONCLUÍDO"
echo "============================================"
echo ""
echo "📱 AGORA:"
echo "1. App vai abrir no simulador"
echo "2. Clique em 'Login com Google'"
echo "3. Siga o fluxo de autenticação"
echo ""
echo "✅ RESULTADO ESPERADO:"
echo "- Safari/WebView FECHA automaticamente após autorização"
echo "- App volta para tela de login"
echo "- Mostra loading 'Autenticando...'"
echo "- Erro de conexão com backend (NORMAL - endpoint não implementado)"
echo ""
echo "❌ SE NÃO FUNCIONAR:"
echo "- Verifique logs no terminal"
echo "- Copie mensagens de erro"
echo "- Consulte: x_temp_files/DIAGNOSTICO_GOOGLE_OAUTH_403_REDIRECT.md"
echo ""
echo "============================================"
echo ""

flutter run -v
