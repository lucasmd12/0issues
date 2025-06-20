# Configuração do Firebase

Para configurar o Firebase no projeto, você precisará:

## 1. Configuração do Firebase Console

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Crie um novo projeto ou use um existente
3. Adicione um app Android e/ou iOS
4. Baixe os arquivos de configuração:
   - `google-services.json` para Android (colocar em `android/app/`)
   - `GoogleService-Info.plist` para iOS (colocar em `ios/Runner/`)

## 2. Configuração do Realtime Database

1. No Firebase Console, vá para "Realtime Database"
2. Crie um banco de dados
3. Configure as regras de segurança (exemplo):

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'",
        ".write": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'"
      }
    },
    "voiceRooms": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "rooms": {
      "$roomId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "messages": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

## 3. Configuração do Firebase Messaging

1. No Firebase Console, vá para "Cloud Messaging"
2. Configure as notificações push
3. Adicione a chave do servidor ao seu backend se necessário

## 4. Configuração do Android

Adicione ao `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-messaging'
}
```

Adicione ao `android/build.gradle`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

Adicione ao final do `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## 5. Configuração do iOS

1. Abra o projeto iOS no Xcode
2. Adicione o `GoogleService-Info.plist` ao projeto
3. Configure as capacidades de notificação push

## 6. Inicialização no App

O Firebase já está configurado no `main.dart`:

```dart
await Firebase.initializeApp();
```

E o `FirebaseService` será inicializado automaticamente quando o usuário fizer login.

