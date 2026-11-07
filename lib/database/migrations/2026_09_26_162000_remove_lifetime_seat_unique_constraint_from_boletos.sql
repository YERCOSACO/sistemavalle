ALTER TABLE boletos
  ADD INDEX boletos_viaje_id_index (viaje_id),
  DROP INDEX boletos_viaje_id_numero_asiento_unique;
