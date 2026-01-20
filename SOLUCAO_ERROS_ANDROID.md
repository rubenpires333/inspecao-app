# 🔧 SOLUÇÃO DE ERROS ANDROID - APP FLUTTER

**Data**: Janeiro 2026  
**Projeto**: SIGIV - App Mobile de Inspeção

---

## ✅ PROBLEMA 1: Android SDK Version - RESOLVIDO

### Erro:
```
Your project is configured to compile against Android SDK 35, but the following plugin(s) require to be compiled against a higher Android SDK version:
- flutter_plugin_android_lifecycle compiles against Android SDK 36
- geolocator_android compiles against Android SDK 36
- image_picker_android compiles against Android SDK 36
- path_provider_android compiles against Android SDK 36
- shared_preferences_android compiles against Android SDK 36
- url_launcher_android compiles against Android SDK 36
- video_player_android compiles against Android SDK 36
```

### Solução Aplicada:
✅ **Atualizado `compileSdk` de 35 para 36** no arquivo:
- `android/app/build.gradle.kts`

**Mudança realizada:**
```kotlin
android {
    namespace = "com.example.inspecao"
    compileSdk = 36  // ← Atualizado de 35 para 36
    ...
}
```

---

## ⚠️ PROBLEMA 2: Erro de Rede Maven

### Erro:
```
Could not GET 'https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.10.0/error_prone_annotations-2.10.0.jar'.
Este anfitrião não é conhecido (repo.maven.apache.org)
```

### Possíveis Causas:
1. **Problema de conexão com internet**
2. **DNS não resolve o domínio**
3. **Firewall bloqueando conexão**
4. **Proxy necessário mas não configurado**

### Soluções:

#### Solução 1: Verificar Conexão
```bash
# Testar conexão com Maven
ping repo.maven.apache.org

# Testar acesso HTTP
curl https://repo.maven.apache.org/maven2/
```

#### Solução 2: Configurar Proxy (se necessário)
Se você estiver atrás de um proxy corporativo, adicione ao `android/gradle.properties`:

```properties
# Proxy HTTP
systemProp.http.proxyHost=seu.proxy.com
systemProp.http.proxyPort=8080
systemProp.http.proxyUser=usuario
systemProp.http.proxyPassword=senha

# Proxy HTTPS
systemProp.https.proxyHost=seu.proxy.com
systemProp.https.proxyPort=8080
systemProp.https.proxyUser=usuario
systemProp.https.proxyPassword=senha
```

#### Solução 3: Usar Repositórios Alternativos
Adicione repositórios alternativos no `android/build.gradle.kts`:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        // Repositórios alternativos
        maven { url = uri("https://jcenter.bintray.com/") }
        maven { url = uri("https://plugins.gradle.org/m2/") }
    }
}
```

#### Solução 4: Limpar Cache do Gradle
```bash
# Limpar cache do Gradle
cd android
./gradlew clean --refresh-dependencies

# Ou no Windows
cd android
gradlew.bat clean --refresh-dependencies
```

#### Solução 5: Baixar Dependências Manualmente (Último Recurso)
Se o problema persistir, você pode tentar:
1. Baixar o JAR manualmente do site Maven
2. Colocar na pasta `android/app/libs/`
3. Adicionar como dependência local

---

## 🚀 COMANDOS PARA RESOLVER

### 1. Limpar e Rebuild Completo
```bash
cd c:\xampp\htdocs\SIGIV\inspecao-app\inspecao

# Limpar Flutter
flutter clean

# Limpar Gradle
cd android
gradlew.bat clean
cd ..

# Obter dependências novamente
flutter pub get

# Tentar rodar novamente
flutter run
```

### 2. Verificar Android SDK Instalado
```bash
# Verificar se Android SDK 36 está instalado
flutter doctor -v
```

Se não estiver instalado:
1. Abra Android Studio
2. Tools → SDK Manager
3. Instale Android SDK Platform 36 (Android 15)
4. Aceite a licença

### 3. Verificar Variáveis de Ambiente
```bash
# Verificar ANDROID_HOME
echo $env:ANDROID_HOME

# Se não estiver configurado, adicione:
# ANDROID_HOME=C:\Users\User\AppData\Local\Android\Sdk
```

---

## 📝 VERIFICAÇÕES FINAIS

### Checklist:
- [x] ✅ `compileSdk = 36` atualizado no `build.gradle.kts`
- [ ] ⚠️ Android SDK 36 instalado no sistema
- [ ] ⚠️ Conexão com internet funcionando
- [ ] ⚠️ DNS resolvendo `repo.maven.apache.org`
- [ ] ⚠️ Firewall não bloqueando Maven
- [ ] ⚠️ Proxy configurado (se necessário)

---

## 🔍 DIAGNÓSTICO ADICIONAL

### Verificar Versão do Android SDK Instalada
```bash
# Listar SDKs instalados
flutter doctor -v

# Ou verificar diretamente
dir "%ANDROID_HOME%\platforms"
```

### Verificar Logs Detalhados do Gradle
```bash
cd android
gradlew.bat assembleDebug --stacktrace --info
```

### Testar Download Manual
Abra no navegador:
- https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.10.0/

Se não abrir, há problema de rede/DNS.

---

## 💡 SOLUÇÃO RÁPIDA (Tentativa)

Se o problema for apenas temporário de rede, tente:

```bash
cd c:\xampp\htdocs\SIGIV\inspecao-app\inspecao
flutter clean
flutter pub get
flutter run
```

O Gradle tentará novamente baixar as dependências.

---

## 📚 REFERÊNCIAS

- [Flutter Android Build Configuration](https://docs.flutter.dev/deployment/android)
- [Gradle Configuration](https://docs.gradle.org/current/userguide/build_environment.html)
- [Android SDK Versions](https://developer.android.com/studio/releases/platforms)

---

**Status**: 
- ✅ Android SDK atualizado para 36
- ⚠️ Problema de rede Maven - verificar conexão

**Próximos Passos**:
1. Verificar se Android SDK 36 está instalado
2. Testar conexão com Maven
3. Configurar proxy se necessário
4. Tentar rodar novamente
