-- ==============================================================================
-- PROYECTO: WarmyRider (Riobamba Moto)
-- TABLA: public.perfiles
-- DESCRIPCIÓN: Almacena los perfiles de Pasajeros y Conductores en PostgreSQL.
-- ==============================================================================

-- 1. Crear tabla perfiles vinculada a auth.users de Supabase
CREATE TABLE IF NOT EXISTS public.perfiles (
    -- ID vinculado directamente al UUID del usuario autenticado en auth.users
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Rol dentro del sistema: 'pasajero' o 'conductor'
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('pasajero', 'conductor')),

    -- Nombres y apellidos completos
    nombre_completo VARCHAR(150) NOT NULL,

    -- Número celular único para contacto directo y llamadas del viaje
    celular VARCHAR(20) NOT NULL UNIQUE,

    -- Cédula de identidad ecuatoriana (10 dígitos)
    -- Es NULA para pasajeros (cero fricción en registro) y OBLIGATORIA para conductores
    cedula VARCHAR(10) UNIQUE,

    -- Calificación promedio (inicialmente 5.0)
    calificacion DECIMAL(3, 2) NOT NULL DEFAULT 5.00 CHECK (calificacion >= 1.0 AND calificacion <= 5.0),

    -- Fecha y hora de registro (Timestamp UTC)
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 2. ÍNDICES DE CONSULTA RÁPIDA
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_perfiles_rol ON public.perfiles(rol);
CREATE INDEX IF NOT EXISTS idx_perfiles_celular ON public.perfiles(celular);
CREATE INDEX IF NOT EXISTS idx_perfiles_cedula ON public.perfiles(cedula);

-- ==============================================================================
-- 3. SEGURIDAD DE ACCESO A NIVEL DE FILA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================
-- Habilitar RLS en la tabla
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

-- Política 1: Lectura permitida a usuarios autenticados
-- Permite que pasajeros y conductores autenticados puedan ver los datos básicos del otro participante en un viaje
CREATE POLICY "Permitir lectura a usuarios autenticados"
ON public.perfiles
FOR SELECT
TO authenticated
USING (true);

-- Política 2: Inserción de perfil
-- Cada usuario únicamente puede insertar su propio perfil con su auth.uid()
CREATE POLICY "Permitir a cada usuario insertar su propio perfil"
ON public.perfiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Política 3: Actualización de perfil
-- Cada usuario únicamente puede modificar sus propios datos
CREATE POLICY "Permitir a cada usuario actualizar su propio perfil"
ON public.perfiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ==============================================================================
-- 4. COMENTARIOS EXPLICATIVOS EN EL MOTOR POSTGRESQL
-- ==============================================================================
COMMENT ON TABLE public.perfiles IS 'Perfiles de usuarios (Pasajeros y Conductores) para la plataforma Riobamba Moto';
COMMENT ON COLUMN public.perfiles.id IS 'Identificador único correspondiente a auth.users.id de Supabase';
COMMENT ON COLUMN public.perfiles.rol IS 'Rol del usuario: pasajero o conductor';
COMMENT ON COLUMN public.perfiles.cedula IS 'Cédula ecuatoriana requerida únicamente para conductores';
COMMENT ON COLUMN public.perfiles.calificacion IS 'Puntuación promedio del usuario (1.0 a 5.0)';
