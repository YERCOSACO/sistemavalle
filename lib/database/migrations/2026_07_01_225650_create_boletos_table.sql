CREATE TABLE boletos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reserva_id BIGINT UNSIGNED NOT NULL,
  viaje_id BIGINT UNSIGNED NOT NULL,
  numero_asiento VARCHAR(255) NOT NULL,
  nombre_pasajero VARCHAR(255) NOT NULL,
  ci_pasajero VARCHAR(255) NULL DEFAULT NULL,
  telefono_pasajero VARCHAR(255) NULL DEFAULT NULL,
  precio DECIMAL(8, 2) NOT NULL,
  metodo_pago VARCHAR(255) NOT NULL DEFAULT 'QR',
  estado VARCHAR(255) NOT NULL DEFAULT 'pendiente',
  expira_en TIMESTAMP NULL DEFAULT NULL,
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY boletos_viaje_id_numero_asiento_unique (viaje_id, numero_asiento),
  CONSTRAINT boletos_reserva_id_foreign
    FOREIGN KEY (reserva_id) REFERENCES reservas (id),
  CONSTRAINT boletos_viaje_id_foreign
    FOREIGN KEY (viaje_id) REFERENCES viajes (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
