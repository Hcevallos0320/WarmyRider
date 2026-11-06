-- ==============================================================================
-- PROYECTO: WarmyRider (Riobamba Moto)
-- TABLA MAESTRA: public.perfiles
-- ==============================================================================
-- Esta tabla almacena los perfiles tanto de Pasajeros como de Conductores,
-- vinculada directamente con el sistema de autenticación de Supabase (auth.users).

CREATE TABLE IF NOT EXISTS public.perfiles (
    -- ID vinculado al UUID generado por Supabase Authentication
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Rol dentro del sistema: 'pasajero' o 'conductor'
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('pasajero', 'conductor')),

    -- Nombres y apellidos completos (No nulo)
    nombre_completo VARCHAR(150) NOT NULL,

    -- Número de celular único y obligatorio para contacto
    celular VARCHAR(20) NOT NULL UNIQUE,

    -- Cédula de identidad ecuatoriana (10 dígitos).
    -- Es NULA para pasajeros (cero fricción en registro) y OBLIGATORIA para conductores.
    cedula VARCHAR(10) UNIQUE,

    -- Calificación promedio (por defecto 5.0 para manejar valores como 4.95)
    calificacion NUMERIC(3, 2) NOT NULL DEFAULT 5.00 CHECK (calificacion >= 1.0 AND calificacion <= 5.0),

    -- Fecha y hora de registro en la plataforma
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- ÍNDICES DE RENDIMIENTO PARA BÚSQUEDAS FRECUENTES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_perfiles_rol ON public.perfiles(rol);
CREATE INDEX IF NOT EXISTS idx_perfiles_celular ON public.perfiles(celular);
CREATE INDEX IF NOT EXISTS idx_perfiles_cedula ON public.perfiles(cedula);

-- ==============================================================================
-- SEGURIDAD A NIVEL DE FILA (ROW LEVEL SECURITY - RLS)
-- ==============================================================================
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

-- 1. Lectura: Permitida a usuarios autenticados para coordinar los viajes
CREATE POLICY "Permitir lectura de perfiles a usuarios autenticados"
ON public.perfiles
FOR SELECT
TO authenticated
USING (true);

-- 2. Inserción: Cada usuario autenticado sólo puede crear su propio perfil
CREATE POLICY "Permitir a cada usuario insertar su propio perfil"
ON public.perfiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 3. Actualización: Cada usuario únicamente puede modificar sus propios datos
CREATE POLICY "Permitir a cada usuario actualizar su propio perfil"
ON public.perfiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- ==============================================================================
-- COMENTARIOS EN EL MOTOR POSTGRESQL
-- ==============================================================================
COMMENT ON TABLE public.perfiles IS 'Tabla maestra de perfiles de pasajeros y conductores de Riobamba Moto';
COMMENT ON COLUMN public.perfiles.id IS 'UUID idéntico al identificador en auth.users';
COMMENT ON COLUMN public.perfiles.rol IS 'Rol asignado: pasajero o conductor';
COMMENT ON COLUMN public.perfiles.cedula IS 'Cédula ecuatoriana obligatoria para conductores y nula para pasajeros';
COMMENT ON COLUMN public.perfiles.calificacion IS 'Calificación media de reputación del usuario (1.00 a 5.00)';
