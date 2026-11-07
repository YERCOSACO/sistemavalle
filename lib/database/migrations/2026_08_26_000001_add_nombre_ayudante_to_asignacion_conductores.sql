ALTER TABLE asignacion_conductores
  MODIFY COLUMN conductor_id BIGINT UNSIGNED NULL,
  ADD COLUMN nombre_ayudante VARCHAR(255) NULL DEFAULT NULL AFTER tipo_asignacion;
