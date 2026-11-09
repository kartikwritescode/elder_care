-- Migration: 20261110000000_optimize_alarm_cron_and_security.sql
-- Description: Composite partial indexes for alarm-cron / trigger-alarms, FK indexes, RLS on care_connections, and table analytics.

-- 1. Partial index for due alarms (status = 'scheduled')
-- Eliminates sequential scan on cron trigger query:
-- SELECT ... FROM alarm_instances WHERE status = 'scheduled' AND scheduled_time <= now()
CREATE INDEX IF NOT EXISTS idx_alarm_instances_due
ON public.alarm_instances (scheduled_time ASC)
WHERE status = 'scheduled';

-- 2. Partial index for missed / escalation alarms (status = 'triggered' AND acknowledged_at IS NULL)
-- Eliminates sequential scan on escalation query:
-- SELECT ... FROM alarm_instances WHERE status = 'triggered' AND acknowledged_at IS NULL AND triggered_at <= threshold
CREATE INDEX IF NOT EXISTS idx_alarm_instances_escalation
ON public.alarm_instances (triggered_at ASC)
WHERE status = 'triggered' AND acknowledged_at IS NULL;

-- 3. Foreign key indexes on receiver_id and caregiver_id to accelerate joins with users table
CREATE INDEX IF NOT EXISTS idx_alarm_instances_receiver_id
ON public.alarm_instances (receiver_id);

CREATE INDEX IF NOT EXISTS idx_alarm_instances_caregiver_id
ON public.alarm_instances (caregiver_id);

-- 4. Enable RLS on public.care_connections with authenticated user policy to resolve Supabase Security Advisor warning
ALTER TABLE IF EXISTS public.care_connections ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'care_connections' 
      AND policyname = 'care_connections_authenticated_policy'
  ) THEN
    CREATE POLICY care_connections_authenticated_policy
    ON public.care_connections
    FOR ALL
    TO authenticated
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);
  END IF;
END $$;

-- 5. Refresh optimizer statistics on affected tables so PostgreSQL planner immediately uses the partial indexes
ANALYZE public.alarm_instances;
ANALYZE public.care_connections;
ANALYZE public.users;
