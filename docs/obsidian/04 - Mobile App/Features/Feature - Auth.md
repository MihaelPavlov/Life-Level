---
tags: [lifelevel, mobile]
aliases: [Auth Feature, Login, Register]
---
# Feature — Auth

> Login, registration, and first-time character setup wizard.

## Files

```
lib/features/auth/
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── welcome_setup_screen.dart
│   ├── class_selection_screen.dart
│   ├── avatar_selection_screen.dart
│   └── character_created_screen.dart
└── services/
    └── auth_service.dart
```

## LoginScreen

- Email + password form
- Calls `AuthService().login(email, password)`
- On success: `ApiClient.saveToken(result.token)` + `Navigator.pushReplacement`
- Branches:
  - `result.isSetupComplete == false` → `WelcomeSetupScreen`
  - Else → `MainShell`

## RegisterScreen

- Username + email + password form
- Calls `AuthService().register(...)`
- Same post-login flow as Login

## Character setup wizard (first-time only)

1. **WelcomeSetupScreen** — intro
2. **ClassSelectionScreen** — pick class (fetched via `GET /api/classes`)
3. **AvatarSelectionScreen** — pick emoji
4. **CharacterCreatedScreen** — calls `CharacterService.setupCharacter(classId, avatarEmoji)` → backend grants **+500 XP starter bonus**

## AuthService

```dart
class AuthService {
  Future<AuthResult> register(String username, String email, String password);
  Future<AuthResult> login(String email, String password);
  Future<void> saveRingConfig(List<String> itemIds);   // PUT /api/user/ring
}

class AuthResult {
  String token;                  // JWT
  String username;
  String characterId;
  List<String> ringItems;
  bool isSetupComplete;
}
```

## Related
- [[Auth and JWT]] (backend)
- [[Identity]] (backend module)
- [[Feature - Character]]
- [[App Architecture]] (_AuthGate)
