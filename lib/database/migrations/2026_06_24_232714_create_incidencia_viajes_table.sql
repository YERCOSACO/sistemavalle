CREATE TABLE incidencia_viajes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  viaje_id BIGINT UNSIGNED NOT NULL,
  tipo_incidencia_id BIGINT UNSIGNED NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NULL DEFAULT NULL,
  descripcion_detalle TEXT NULL,
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT incidencia_viajes_viaje_id_foreign
    FOREIGN KEY (viaje_id) REFERENCES viajes (id),
  CONSTRAINT incidencia_viajes_tipo_incidencia_id_foreign
    FOREIGN KEY (tipo_incidencia_id) REFERENCES tipo_incidencias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
