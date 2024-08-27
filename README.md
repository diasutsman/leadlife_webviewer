# Leadlife.id webviewer

## Run the project

1. Make sure to make .env file with this content (filled with advisor or user):

```
MODE=advisor
```
or 
```
MODE=user
```

advisor: Show "https://leadlife.id/login/advisor" as the webview

user: Show "https://leadlife.id" as the webview


2. Run these commands
```console
flutter pub get

dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs

flutter run
```