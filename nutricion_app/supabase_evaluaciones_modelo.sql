-- Tabla para evaluaciones de modelos de planes nutricionales
CREATE TABLE IF NOT EXISTS public.evaluaciones_modelo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES public.planes_nutricionales(id) ON DELETE CASCADE,
    codigo_plan VARCHAR(50) NOT NULL, -- Formato ###-AAAA
    tipo_plan_nutricional VARCHAR(100) NOT NULL, -- Nombre del plan
    tiempo_generacion_segundos DECIMAL(10, 2) NOT NULL, -- Tiempo en segundos
    calificacion_nutricionista VARCHAR(20) NOT NULL CHECK (calificacion_nutricionista IN ('Correcto', 'Incorrecto')),
    nutricionista_id UUID NOT NULL REFERENCES public.nutricionistas(id) ON DELETE CASCADE,
    paciente_id UUID NOT NULL REFERENCES public.pacientes(id) ON DELETE CASCADE,
    fecha_evaluacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar las consultas
CREATE INDEX IF NOT EXISTS idx_evaluaciones_plan_id ON public.evaluaciones_modelo(plan_id);
CREATE INDEX IF NOT EXISTS idx_evaluaciones_nutricionista_id ON public.evaluaciones_modelo(nutricionista_id);
CREATE INDEX IF NOT EXISTS idx_evaluaciones_paciente_id ON public.evaluaciones_modelo(paciente_id);
CREATE INDEX IF NOT EXISTS idx_evaluaciones_fecha ON public.evaluaciones_modelo(fecha_evaluacion);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_evaluaciones_modelo_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER trigger_update_evaluaciones_modelo_updated_at
    BEFORE UPDATE ON public.evaluaciones_modelo
    FOR EACH ROW
    EXECUTE FUNCTION update_evaluaciones_modelo_updated_at();

-- Políticas RLS (Row Level Security)
ALTER TABLE public.evaluaciones_modelo ENABLE ROW LEVEL SECURITY;

-- Política: Los nutricionistas pueden ver todas las evaluaciones
CREATE POLICY "Nutricionistas pueden ver todas las evaluaciones"
    ON public.evaluaciones_modelo
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.nutricionistas
            WHERE nutricionistas.id = evaluaciones_modelo.nutricionista_id
            AND nutricionistas.auth_uid = auth.uid()
        )
    );

-- Política: Los nutricionistas pueden insertar evaluaciones
CREATE POLICY "Nutricionistas pueden insertar evaluaciones"
    ON public.evaluaciones_modelo
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.nutricionistas
            WHERE nutricionistas.auth_uid = auth.uid()
        )
    );

-- Política: Los nutricionistas pueden actualizar sus propias evaluaciones
CREATE POLICY "Nutricionistas pueden actualizar sus evaluaciones"
    ON public.evaluaciones_modelo
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.nutricionistas
            WHERE nutricionistas.id = evaluaciones_modelo.nutricionista_id
            AND nutricionistas.auth_uid = auth.uid()
        )
    );

-- Comentarios en la tabla
COMMENT ON TABLE public.evaluaciones_modelo IS 'Tabla para registrar evaluaciones de modelos de planes nutricionales generados por IA';
COMMENT ON COLUMN public.evaluaciones_modelo.codigo_plan IS 'Código del plan en formato ###-AAAA';
COMMENT ON COLUMN public.evaluaciones_modelo.tipo_plan_nutricional IS 'Nombre/tipo del plan nutricional generado';
COMMENT ON COLUMN public.evaluaciones_modelo.tiempo_generacion_segundos IS 'Tiempo que tardó la generación del modelo en segundos';
COMMENT ON COLUMN public.evaluaciones_modelo.calificacion_nutricionista IS 'Calificación del nutricionista: Correcto o Incorrecto';

