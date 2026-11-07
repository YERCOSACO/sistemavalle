CREATE TABLE clientes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(255) NOT NULL,
  apellido VARCHAR(255) NOT NULL,
  cedula VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  contrasena VARCHAR(255) NOT NULL,
  telefono VARCHAR(255) NULL DEFAULT NULL,
  direccion VARCHAR(255) NULL DEFAULT NULL,
  fecha_nacimiento DATE NULL DEFAULT NULL,
  remember_token VARCHAR(100) NULL DEFAULT NULL,
  estado_base TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT NULL,
  updated_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY clientes_cedula_unique (cedula),
  UNIQUE KEY clientes_email_unique (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
