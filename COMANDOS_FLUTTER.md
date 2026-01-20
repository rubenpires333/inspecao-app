# 🚀 COMANDOS FLUTTER - APP DE INSPEÇÃO

**Projeto**: SIGIV - Sistema Integrado de Gestão de Inspeções e Vistorias  
**Plataforma**: Flutter (Android/iOS/Web)  
**Data**: Janeiro 2026

---

## 📋 ÍNDICE

1. [Comandos Básicos](#comandos-básicos)
2. [Hot Reload e Hot Restart](#hot-reload-e-hot-restart)
3. [Comandos por Dispositivo](#comandos-por-dispositivo)
4. [Comandos de Build](#comandos-de-build)
5. [Comandos de Debug](#comandos-de-debug)
6. [Comandos Úteis](#comandos-úteis)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 COMANDOS BÁSICOS

### Rodar o App com Hot Reload

```bash
# Navegar para o diretório do projeto
cd c:\xampp\htdocs\SIGIV\inspecao-app\inspecao

# Rodar o app (modo debug com hot reload)
flutter run
```

### Verificar Dispositivos Disponíveis

```bash
# Listar todos os dispositivos conectados (emuladores, físicos, web)
flutter devices
```

### Rodar em Dispositivo Específico

```bash
# Rodar em dispositivo específico pelo ID
flutter run -d <device-id>

# Exemplos:
flutter run -d emulator-5554          # Android Emulator
flutter run -d chrome                  # Chrome (Web)
flutter run -d windows                 # Windows Desktop
flutter run -d macos                   # macOS Desktop
flutter run -d linux                   # Linux Desktop
```

---

## ⚡ HOT RELOAD E HOT RESTART

### Durante a Execução do App

Quando o app estiver rodando, você pode usar os seguintes comandos no terminal:

| Tecla | Ação | Descrição |
|-------|------|-----------|
| `r` | **Hot Reload** | Recarrega mudanças mantendo o estado atual (mais rápido) |
| `R` | **Hot Restart** | Reinicia o app aplicando todas as mudanças |
| `q` | **Quit** | Sair do app |
| `h` | **Help** | Ver todos os comandos disponíveis |
| `d` | **Detach** | Desconectar do terminal (app continua rodando) |
| `c` | **Clear** | Limpar o console |

### Hot Reload Automático

O Flutter detecta automaticamente quando você salva um arquivo (`.dart`) e pode fazer hot reload automaticamente se configurado no seu editor.

**VS Code**: Salve o arquivo (`Ctrl+S`) → Hot Reload automático  
**Android Studio**: Salve o arquivo (`Ctrl+S`) → Clique no botão ⚡ (Hot Reload)

---

## 📱 COMANDOS POR DISPOSITIVO

### Android

```bash
# Rodar em Android (emulador ou dispositivo físico)
flutter run

# Rodar em Android específico
flutter run -d android

# Listar apenas dispositivos Android
flutter devices | grep android
```

### iOS (apenas no macOS)

```bash
# Rodar em iOS Simulator
flutter run -d ios

# Rodar em dispositivo iOS físico
flutter run -d <ios-device-id>
```

### Web

```bash
# Rodar no Chrome
flutter run -d chrome

# Rodar no Edge
flutter run -d edge

# Rodar no Firefox (se configurado)
flutter run -d firefox
```

### Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

---

## 🏗️ COMANDOS DE BUILD

### Build de Debug (com Hot Reload)

```bash
# Build APK de debug (Android)
flutter build apk --debug

# Build App Bundle de debug (Android)
flutter build appbundle --debug

# Build iOS de debug (macOS apenas)
flutter build ios --debug
```

### Build de Release (otimizado, sem Hot Reload)

```bash
# Build APK de release (Android)
flutter build apk --release

# Build App Bundle de release (Android - para Play Store)
flutter build appbundle --release

# Build iOS de release (macOS apenas)
flutter build ios --release

# Build Web de release
flutter build web --release
```

### Build para Plataformas Específicas

```bash
# Android
flutter build apk --release --target-platform android-arm64

# iOS
flutter build ios --release --no-codesign

# Web
flutter build web --release --web-renderer html
```

---

## 🐛 COMANDOS DE DEBUG

### Rodar com Debug Detalhado

```bash
# Rodar com logs detalhados
flutter run --verbose

# Rodar com observatory (ferramenta de debug)
flutter run --observatory-port=8888
```

### Ver Logs do App

```bash
# Ver logs em tempo real
flutter logs

# Ver logs de dispositivo específico
flutter logs -d <device-id>
```

### Limpar e Rebuild

```bash
# Limpar build anterior
flutter clean

# Obter dependências novamente
flutter pub get

# Rodar novamente
flutter run
```

---

## 🛠️ COMANDOS ÚTEIS

### Verificar Ambiente

```bash
# Verificar se tudo está configurado corretamente
flutter doctor

# Verificar com mais detalhes
flutter doctor -v
```

### Gerenciar Dependências

```bash
# Obter dependências
flutter pub get

# Atualizar dependências
flutter pub upgrade

# Ver dependências desatualizadas
flutter pub outdated
```

### Análise de Código

```bash
# Analisar código
flutter analyze

# Formatar código
flutter format .

# Formatar arquivo específico
flutter format lib/main.dart
```

### Testes

```bash
# Rodar todos os testes
flutter test

# Rodar testes com cobertura
flutter test --coverage

# Rodar teste específico
flutter test test/widget_test.dart
```

### Limpar Projeto

```bash
# Limpar build
flutter clean

# Limpar e obter dependências
flutter clean && flutter pub get
```

---

## 🔧 TROUBLESHOOTING

### Problema: Hot Reload não funciona

**Solução 1**: Use Hot Restart (`R` no terminal)

**Solução 2**: Reinicie o app
```bash
# Parar o app (pressione 'q')
# Depois rode novamente
flutter run
```

**Solução 3**: Limpe e rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Problema: Dispositivo não encontrado

**Solução 1**: Verifique dispositivos
```bash
flutter devices
```

**Solução 2**: Inicie um emulador
```bash
# Android
# Abra Android Studio → AVD Manager → Inicie um emulador

# iOS (macOS)
open -a Simulator
```

**Solução 3**: Conecte dispositivo físico
```bash
# Android: Ative "Depuração USB" nas opções de desenvolvedor
# iOS: Confie no computador quando solicitado
```

### Problema: Erro de dependências

**Solução**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Problema: Erro de compilação

**Solução 1**: Limpar build
```bash
flutter clean
flutter pub get
flutter run
```

**Solução 2**: Verificar versão do Flutter
```bash
flutter --version
flutter upgrade
```

### Problema: App não inicia

**Solução**:
```bash
# Verificar logs
flutter logs

# Rodar com verbose para ver erros
flutter run --verbose
```

---

## 📝 COMANDOS RÁPIDOS - RESUMO

### Para Desenvolvimento Diário

```bash
# 1. Navegar para o projeto
cd c:\xampp\htdocs\SIGIV\inspecao-app\inspecao

# 2. Verificar dispositivos
flutter devices

# 3. Rodar o app
flutter run

# 4. Durante execução:
#    - Pressione 'r' para Hot Reload
#    - Pressione 'R' para Hot Restart
#    - Pressione 'q' para sair
```

### Para Limpar e Recomeçar

```bash
cd c:\xampp\htdocs\SIGIV\inspecao-app\inspecao
flutter clean
flutter pub get
flutter run
```

### Para Build de Release

```bash
cd c:\xampp\htdocs\SIGIV\inspecao-app\inspecao
flutter build apk --release
# APK estará em: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎯 QUANDO USAR CADA COMANDO

| Situação | Comando |
|----------|---------|
| Desenvolvimento normal | `flutter run` |
| Mudança em código Dart | Pressione `r` (Hot Reload) |
| Mudança em `main()` ou `initState()` | Pressione `R` (Hot Restart) |
| App travou | Pressione `q` e rode `flutter run` novamente |
| Erro de dependências | `flutter clean && flutter pub get` |
| Build para produção | `flutter build apk --release` |
| Verificar ambiente | `flutter doctor` |
| Ver logs | `flutter logs` |

---

## 💡 DICAS IMPORTANTES

### ⚠️ Hot Reload NÃO funciona para:

- Mudanças em `main()`
- Mudanças em `initState()`
- Mudanças em construtores
- Mudanças em enums
- Mudanças em classes abstratas
- Mudanças em imports de pacotes nativos

**Solução**: Use Hot Restart (`R`) ou reinicie o app

### ✅ Hot Reload funciona para:

- Mudanças em widgets
- Mudanças em métodos de build
- Mudanças em variáveis de estado
- Mudanças em estilos e temas
- Mudanças em lógica de negócio

### 🚀 Performance

- **Hot Reload**: ~1 segundo (mantém estado)
- **Hot Restart**: ~3-5 segundos (reinicia app)
- **Rebuild completo**: ~30-60 segundos (compila tudo)

---

## 📚 RECURSOS ADICIONAIS

### Documentação Oficial

- [Flutter Hot Reload](https://docs.flutter.dev/development/tools/hot-reload)
- [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)
- [Flutter Debugging](https://docs.flutter.dev/testing/debugging)

### Comandos de Ajuda

```bash
# Ver ajuda geral
flutter --help

# Ver ajuda de comando específico
flutter run --help
flutter build --help
```

---

**Documento criado em**: Janeiro 2026  
**Versão**: 1.0  
**Projeto**: SIGIV - App Mobile de Inspeção
