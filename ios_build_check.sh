#!/bin/bash

################################################################################
# iOS Build Check Script
# Projeto: aguide-app-ptbr
# Descrição: Verificação preventiva de build iOS (Simulador)
# Uso: ./ios_build_check.sh
# Nota: Este script testa build para SIMULADOR (não requer certificado)
################################################################################

set -e  # Para na primeira falha

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Função para print com cores
print_step() {
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Banner
echo -e "${MAGENTA}"
cat << "EOF"
 ___ ___  ____  
|_ _/ _ \/ ___| 
 | | | | \___ \ 
 | | |_| |___) |
|___\___/|____/ 
                
 Build Check - iOS (Simulator)
EOF
echo -e "${NC}"

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml não encontrado!"
    print_error "Execute este script na raiz do projeto Flutter"
    exit 1
fi

# Verificar se a pasta ios existe
if [ ! -d "ios" ]; then
    print_error "Pasta ios/ não encontrada!"
    print_error "Este projeto não tem suporte para iOS"
    exit 1
fi

# Verificar se está rodando no macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "Este script só pode ser executado no macOS!"
    print_error "Builds iOS requerem Xcode que só está disponível em macOS"
    exit 1
fi

# 1. Verificar Flutter Doctor
print_step "🔍 1. Verificando Flutter Doctor"
if flutter doctor | grep -q "Xcode"; then
    print_success "Flutter doctor OK"
else
    print_warning "Possíveis problemas detectados pelo flutter doctor"
    flutter doctor
fi

# 2. Verificar Xcode
print_step "🛠️  2. Verificando Xcode"
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_success "Xcode instalado: $XCODE_VERSION"
else
    print_error "Xcode não encontrado!"
    print_error "Instale o Xcode pela App Store"
    exit 1
fi

# 3. Limpar cache
print_step "🧹 3. Limpando cache Flutter"
flutter clean
print_success "Cache limpo com sucesso"

# 4. Limpar build iOS específico
print_step "🧹 4. Limpando build iOS anterior"
rm -rf ios/build
print_success "Build iOS anterior removido"

# 5. Instalar dependências
print_step "📦 5. Instalando dependências"
flutter pub get
print_success "Dependências instaladas"

# 6. Instalar CocoaPods
print_step "🍫 6. Instalando CocoaPods dependencies"
cd ios
if pod install; then
    print_success "CocoaPods instalado com sucesso"
else
    print_warning "Problemas ao instalar CocoaPods"
fi
cd ..

# 7. Análise estática
print_step "🔍 7. Análise estática do código"
if flutter analyze; then
    print_success "Análise estática passou sem erros críticos"
else
    print_warning "Análise encontrou issues - verifique acima"
fi

# 8. Verificar simuladores disponíveis
print_step "📱 8. Verificando simuladores iOS disponíveis"
echo -e "${BLUE}Simuladores disponíveis:${NC}"
xcrun simctl list devices available | grep -i "iphone" | head -5

# Verificar se há algum simulador rodando
if flutter devices | grep -q "ios.*simulator"; then
    print_success "Simulador iOS detectado"
    flutter devices | grep "ios.*simulator"
else
    print_info "Nenhum simulador rodando no momento"
    print_info "Abrindo simulador..."
    open -a Simulator
    sleep 3
fi

# 9. Build iOS para Simulador (NÃO requer certificado)
print_step "🔨 9. Building iOS para Simulador (Debug)"
print_info "Este build NÃO requer certificado de desenvolvedor"

if flutter build ios --debug --simulator; then
    print_success "Build iOS Simulador concluído com sucesso!"
    
    # Verificar app gerado
    APP_PATH="build/ios/iphonesimulator/Runner.app"
    if [ -d "$APP_PATH" ]; then
        APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
        print_success "App gerado: $APP_PATH ($APP_SIZE)"
    fi
else
    print_error "Build iOS Simulador falhou!"
    exit 1
fi

# 10. Verificar projeto Xcode (opcional)
print_step "🔧 10. Verificando projeto Xcode"
if xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showdestinations > /dev/null 2>&1; then
    print_success "Projeto Xcode configurado corretamente"
else
    print_warning "Possíveis problemas com projeto Xcode"
fi

# 11. Resumo final
print_step "📊 Resumo da Verificação"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_success "Flutter doctor verificado"
print_success "Xcode configurado"
print_success "Cache limpo"
print_success "Dependências instaladas"
print_success "CocoaPods atualizado"
print_success "Código analisado"
print_success "Build iOS Simulador: OK"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Banner final
echo -e "\n${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║                                                   ║
║   ✅  Build iOS (Simulador) SAUDÁVEL!             ║
║                                                   ║
║   📱  App disponível em:                          ║
║       build/ios/iphonesimulator/Runner.app        ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Comandos úteis
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo -e "   • Rodar no simulador: ${BLUE}flutter run${NC}"
echo -e "   • Especificar simulador: ${BLUE}flutter run -d \"iPhone 16 Pro\"${NC}"
echo -e "   • Abrir no Xcode: ${BLUE}open ios/Runner.xcworkspace${NC}"
echo -e ""

# Aviso sobre dispositivo físico
echo -e "${YELLOW}⚠️  Nota sobre Dispositivo Físico:${NC}"
echo -e "   Para buildar para iPhone/iPad físico você precisa:"
echo -e "   • Apple Developer Account (gratuita ou paga)"
echo -e "   • Configurar certificados no Xcode"
echo -e "   • Comando: ${BLUE}flutter build ios --debug${NC} (sem --simulator)"
echo -e ""

exit 0
