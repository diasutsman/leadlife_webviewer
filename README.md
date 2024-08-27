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

2. For Android, add this line to "android\local.properties":
   
   Same as in the .env, you can choose between "advisor" and "user" but make sure it is the same as written in the .env

```
mode=advisor
```
or 
```
mode=user
``` 

3. Run these commands
```console
flutter pub get

dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs

flutter run
```

note:
if you change .env file and it doesn't read the changes just run this command again before running it:
```
dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs
```
