CREATE TABLE notificaciones (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cliente_id BIGINT UNSIGNED NOT NULL,
  titulo VARCHAR(255) NOT NULL,
  mensaje TEXT NOT NULL,
  tipo VARCHAR(255) NOT NULL DEFAULT 'info',
  canal VARCHAR(255) NOT NULL DEFAULT 'sistema',
  prioridad VARCHAR(255) NOT NULL DEFAULT 'normal',
  fecha_envio TIMESTAMP NULL DEFAULT NULL,
  fecha_lectura TIMESTAMP NULL DEFAULT NULL,
  referenciable_type VARCHAR(255) NULL DEFAULT NULL,
  referenciable_id BIGINT UNSIGNED NULL DEFAULT NULL,
  estado VARCHAR(255) NOT NULL DEFAULT 'pendiente',
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY notificaciones_referenciable_type_referenciable_id_index (referenciable_type, referenciable_id),
  CONSTRAINT notificaciones_cliente_id_foreign
    FOREIGN KEY (cliente_id) REFERENCES clientes (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
