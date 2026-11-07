CREATE TABLE encomiendas (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cliente_id BIGINT UNSIGNED NULL DEFAULT NULL,
  remitente_nombre VARCHAR(255) NULL DEFAULT NULL,
  remitente_ci VARCHAR(255) NULL DEFAULT NULL,
  remitente_telefono VARCHAR(255) NULL DEFAULT NULL,
  destinatario_nombre VARCHAR(255) NOT NULL,
  destinatario_ci VARCHAR(255) NULL DEFAULT NULL,
  destinatario_telefono VARCHAR(255) NULL DEFAULT NULL,
  viaje_id BIGINT UNSIGNED NOT NULL,
  tipo_encomienda_id BIGINT UNSIGNED NOT NULL,
  cantidad INT NOT NULL DEFAULT 1,
  total_pagar DECIMAL(8, 2) NOT NULL DEFAULT 0,
  estado VARCHAR(255) NOT NULL DEFAULT 'recibido',
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT encomiendas_cliente_id_foreign
    FOREIGN KEY (cliente_id) REFERENCES clientes (id),
  CONSTRAINT encomiendas_viaje_id_foreign
    FOREIGN KEY (viaje_id) REFERENCES viajes (id),
  CONSTRAINT encomiendas_tipo_encomienda_id_foreign
    FOREIGN KEY (tipo_encomienda_id) REFERENCES tipo_encomiendas (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
