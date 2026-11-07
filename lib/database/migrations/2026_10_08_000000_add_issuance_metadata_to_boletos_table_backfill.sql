UPDATE boletos
SET fecha_emision = created_at
WHERE estado = 'confirmado'
  AND fecha_emision IS NULL;
