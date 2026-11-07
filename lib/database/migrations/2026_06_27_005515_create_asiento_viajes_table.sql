CREATE TABLE asiento_viajes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  viaje_id BIGINT UNSIGNED NOT NULL,
  numero_asiento VARCHAR(255) NOT NULL,
  estado VARCHAR(255) NOT NULL DEFAULT 'disponible',
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY asiento_viajes_viaje_id_numero_asiento_unique (viaje_id, numero_asiento),
  CONSTRAINT asiento_viajes_viaje_id_foreign
    FOREIGN KEY (viaje_id) REFERENCES viajes (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
