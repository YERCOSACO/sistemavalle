SELECT required.table_name,
       CASE
         WHEN actual.table_name IS NULL THEN 'MISSING'
         ELSE 'OK'
       END AS status
FROM (
  SELECT 'dart_migrations' AS table_name
  UNION ALL SELECT 'users'
  UNION ALL SELECT 'password_reset_tokens'
  UNION ALL SELECT 'sessions'
  UNION ALL SELECT 'permissions'
  UNION ALL SELECT 'roles'
  UNION ALL SELECT 'model_has_permissions'
  UNION ALL SELECT 'model_has_roles'
  UNION ALL SELECT 'role_has_permissions'
  UNION ALL SELECT 'clientes'
  UNION ALL SELECT 'buses'
  UNION ALL SELECT 'conductores'
  UNION ALL SELECT 'rutas'
  UNION ALL SELECT 'tipo_encomiendas'
  UNION ALL SELECT 'tipo_incidencias'
  UNION ALL SELECT 'personal_access_tokens'
  UNION ALL SELECT 'viajes'
  UNION ALL SELECT 'asignacion_conductores'
  UNION ALL SELECT 'incidencia_viajes'
  UNION ALL SELECT 'encomiendas'
  UNION ALL SELECT 'notificaciones'
  UNION ALL SELECT 'asiento_viajes'
  UNION ALL SELECT 'reservas'
  UNION ALL SELECT 'boletos'
) AS required
LEFT JOIN information_schema.tables AS actual
  ON actual.table_schema = DATABASE()
 AND actual.table_name = required.table_name
ORDER BY required.table_name;
