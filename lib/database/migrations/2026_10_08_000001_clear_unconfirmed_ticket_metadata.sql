UPDATE boletos
SET fecha_emision = NULL,
    usuario_id = NULL
WHERE estado != 'confirmado';
