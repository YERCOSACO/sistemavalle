CREATE TABLE viajes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ruta_id BIGINT UNSIGNED NOT NULL,
  bus_id BIGINT UNSIGNED NOT NULL,
  fecha_viaje DATE NOT NULL,
  hora_salida TIME NOT NULL,
  estado VARCHAR(255) NOT NULL DEFAULT 'programado',
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT viajes_ruta_id_foreign
    FOREIGN KEY (ruta_id) REFERENCES rutas (id),
  CONSTRAINT viajes_bus_id_foreign
    FOREIGN KEY (bus_id) REFERENCES buses (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
