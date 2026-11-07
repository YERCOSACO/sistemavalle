ALTER TABLE boletos
  ADD COLUMN fecha_emision TIMESTAMP NULL DEFAULT NULL AFTER reserva_id,
  ADD COLUMN usuario_id BIGINT UNSIGNED NULL DEFAULT NULL AFTER fecha_emision,
  ADD COLUMN cliente_emisor_id BIGINT UNSIGNED NULL DEFAULT NULL AFTER usuario_id,
  ADD CONSTRAINT boletos_usuario_id_foreign
    FOREIGN KEY (usuario_id) REFERENCES users (id) ON DELETE SET NULL,
  ADD CONSTRAINT boletos_cliente_emisor_id_foreign
    FOREIGN KEY (cliente_emisor_id) REFERENCES clientes (id) ON DELETE SET NULL;
