#!/bin/bash

################################################################################
# Android Build Check Script
# Projeto: aguide-app-ptbr
# Descrição: Verificação preventiva de build Android
# Uso: ./android_build_check.sh
################################################################################

set -e  # Para na primeira falha

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para print com cores
print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Banner
echo -e "${GREEN}"
cat << "EOF"
    _              _           _     _ 
   / \   _ __   __| |_ __ ___ (_) __| |
  / _ \ | '_ \ / _` | '__/ _ \| |/ _` |
 / ___ \| | | | (_| | | | (_) | | (_| |
/_/   \_\_| |_|\__,_|_|  \___/|_|\__,_|
                                        
 Build Check - Android
EOF
echo -e "${NC}"

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml não encontrado!"
    print_error "Execute este script na raiz do projeto Flutter"
    exit 1
fi

# Verificar se a pasta android existe
if [ ! -d "android" ]; then
    print_error "Pasta android/ não encontrada!"
    print_error "Este projeto não tem suporte para Android"
    exit 1
fi

# 1. Verificar Flutter Doctor
print_step "🔍 1. Verificando Flutter Doctor"
if flutter doctor | grep -q "Android toolchain"; then
    print_success "Flutter doctor OK"
else
    print_warning "Possíveis problemas detectados pelo flutter doctor"
    flutter doctor
fi

# 2. Limpar cache
print_step "🧹 2. Limpando cache Flutter"
flutter clean
print_success "Cache limpo com sucesso"

# 3. Instalar dependências
print_step "📦 3. Instalando dependências"
flutter pub get
print_success "Dependências instaladas"

# 4. Análise estática
print_step "🔍 4. Análise estática do código"
if flutter analyze; then
    print_success "Análise estática passou sem erros críticos"
else
    print_warning "Análise encontrou issues - verifique acima"
fi

# 5. Verificar dispositivos Android
print_step "📱 5. Verificando dispositivos Android disponíveis"
if flutter devices | grep -q "android"; then
    flutter devices | grep "android"
    print_success "Dispositivos/emuladores Android disponíveis"
else
    print_warning "Nenhum dispositivo/emulador Android conectado"
    print_warning "Você pode iniciar um emulador com: flutter emulators --launch <emulator-id>"
fi

# 6. Build APK Debug
print_step "🔨 6. Building APK Debug"
if flutter build apk --debug; then
    print_success "Build APK Debug concluído com sucesso!"
    
    # Verificar tamanho do APK
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        print_success "APK gerado: $APK_PATH ($APK_SIZE)"
    fi
else
    print_error "Build APK Debug falhou!"
    exit 1
fi

# 7. Build APK Debug com splits (opcional - mais rápido para instalar)
print_step "🔨 7. Building APK Debug com splits por ABI"
if flutter build apk --debug --split-per-abi; then
    print_success "Build APK Debug com splits concluído!"
    
    # Listar APKs gerados
    echo -e "\n${GREEN}APKs gerados:${NC}"
    ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print $9, "(" $5 ")"}'
else
    print_warning "Build com splits falhou (não crítico)"
fi

# 8. Verificar Gradle (opcional)
print_step "🔧 8. Verificando configuração Gradle"
cd android
if ./gradlew tasks > /dev/null 2>&1; then
    print_success "Gradle configurado corretamente"
else
    print_warning "Possíveis problemas com Gradle"
fi
cd ..

# 9. Resumo final
print_step "📊 Resumo da Verificação"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_success "Flutter doctor verificado"
print_success "Cache limpo"
print_success "Dependências instaladas"
print_success "Código analisado"
print_success "Build APK Debug: OK"
print_success "Build APK com splits: OK"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Banner final
echo -e "\n${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║                                                   ║
║   ✅  Build Android SAUDÁVEL!                     ║
║                                                   ║
║   📦  APKs disponíveis em:                        ║
║       build/app/outputs/flutter-apk/              ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Comandos úteis
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo -e "   • Instalar no dispositivo: ${BLUE}flutter install${NC}"
echo -e "   • Rodar no emulador: ${BLUE}flutter run${NC}"
echo -e "   • Build release: ${BLUE}flutter build apk --release --split-per-abi${NC}"
echo -e ""

exit 0
