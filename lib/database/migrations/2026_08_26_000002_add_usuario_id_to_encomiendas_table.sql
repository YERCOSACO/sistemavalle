ALTER TABLE encomiendas
  ADD COLUMN usuario_id BIGINT UNSIGNED NULL DEFAULT NULL AFTER cliente_id,
  ADD CONSTRAINT encomiendas_usuario_id_foreign
    FOREIGN KEY (usuario_id) REFERENCES users (id) ON DELETE SET NULL;
