CREATE TABLE model_has_roles (
  role_id BIGINT UNSIGNED NOT NULL,
  model_type VARCHAR(255) NOT NULL,
  model_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, model_id, model_type),
  KEY model_has_roles_model_id_model_type_index (model_id, model_type),
  CONSTRAINT model_has_roles_role_id_foreign
    FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
