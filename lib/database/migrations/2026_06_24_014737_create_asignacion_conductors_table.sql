CREATE TABLE asignacion_conductores (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  viaje_id BIGINT UNSIGNED NOT NULL,
  conductor_id BIGINT UNSIGNED NOT NULL,
  tipo_asignacion VARCHAR(255) NOT NULL,
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY asignacion_conductores_viaje_id_tipo_asignacion_unique (viaje_id, tipo_asignacion),
  CONSTRAINT asignacion_conductores_viaje_id_foreign
    FOREIGN KEY (viaje_id) REFERENCES viajes (id),
  CONSTRAINT asignacion_conductores_conductor_id_foreign
    FOREIGN KEY (conductor_id) REFERENCES conductores (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
