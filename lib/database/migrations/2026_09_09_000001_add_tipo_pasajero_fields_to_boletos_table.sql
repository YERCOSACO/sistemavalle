ALTER TABLE boletos
  ADD COLUMN espacio_extra TINYINT(1) NOT NULL DEFAULT 0 AFTER telefono_pasajero,
  ADD COLUMN mascota TINYINT(1) NOT NULL DEFAULT 0 AFTER espacio_extra;
