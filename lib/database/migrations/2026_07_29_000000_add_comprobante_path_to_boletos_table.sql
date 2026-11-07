ALTER TABLE boletos
  ADD COLUMN comprobante_path VARCHAR(255) NULL DEFAULT NULL AFTER expira_en;
