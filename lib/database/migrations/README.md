# Migraciones para una base independiente de Dart

Estos archivos recrean las tablas funcionales de las migraciones Laravel
existentes en una base **independiente** para la API Dart. La configuración
actual usa la misma base de Laravel; por tanto, no ejecutes estas migraciones
con la configuración actual. No contienen las tablas de cache ni de colas de
Laravel.

Antes de ejecutar el migrador:

1. Crea una base MySQL vacía para Dart.
2. Configura `DB_DATABASE`/`DB_NAME` para que la API y sus seeders usen esa
   base.
3. Configura las variables `MIGRATION_DB_*` y
   `LARAVEL_DB_DATABASE` de `.env.example`.
4. Confirma que `MIGRATION_DB_DATABASE` sea diferente de la base Laravel.
5. Ejecuta el comando con `--confirm-migrations`.

El migrador no crea la base de datos y no se ejecuta al iniciar el servidor.
No apuntes esta configuración de migraciones a la base compartida de Laravel.
`check_schema.sql` permite verificar la presencia de las tablas de aplicación
sin cambiar el esquema.
