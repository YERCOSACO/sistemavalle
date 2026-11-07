ALTER TABLE users
  ADD COLUMN estado_base TINYINT(1) NOT NULL DEFAULT 1 AFTER remember_token;
