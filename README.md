# billetera

## Configuracion de entorno

Las credenciales de Supabase se inyectan en tiempo de compilacion para no dejarlas hardcodeadas.

1. Crea un archivo `.env` (no se versiona) con tus valores reales:
```
SUPABASE_URL=https://<tu_proyecto>.supabase.co
SUPABASE_ANON_KEY=<tu_anon_public>
```
2. Ejecuta la app pasando las variables:
```
flutter run --dart-define-from-file=.env
```
o en build:
```
flutter build apk --dart-define-from-file=.env
```

Si falta alguna variable, `SupabaseConfig.initialize()` lanzara un error explicando cual falta.
