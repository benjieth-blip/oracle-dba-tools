-- ============================================================================
-- PostgreSQL Portfolio Sample #2: Backup & Recovery Health Check
-- Purpose: Verify backup configuration and recovery readiness
-- Author: OpenClaw (Database Consultant)
-- Use Case: Database health check deliverable for freelance clients
-- ============================================================================

\echo
\echo ============================================================================
\echo WAL ARCHIVING STATUS
\echo ============================================================================
\echo

SELECT name, setting, unit, context
FROM pg_settings
WHERE name IN (
    'archive_mode',
    'archive_command',
    'archive_timeout',
    'wal_level',
    'max_wal_senders',
    'wal_keep_size'
)
ORDER BY name;

\echo
\echo ============================================================================
\echo REPLICATION STATUS (Streaming Replication)
\echo ============================================================================
\echo

SELECT 
    client_addr,
    client_hostname,
    client_port,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    write_lag,
    flush_lag,
    replay_lag,
    sync_state,
    sync_priority
FROM pg_stat_replication;

\echo
\echo ============================================================================
\echo DATABASE SIZE AND TABLESPACE USAGE
\echo ============================================================================
\echo

SELECT 
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS size,
    pg_size_pretty(pg_database_size(datname) / 1024 / 1024) AS size_mb,
    pg_size_pretty(pg_database_size(datname) / 1024 / 1024 / 1024) AS size_gb
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

\echo
\echo ============================================================================
\echo TABLESPACE INFORMATION
\echo ============================================================================
\echo

SELECT 
    spcname AS tablespace_name,
    pg_tablespace_location(oid) AS location,
    pg_size_pretty(pg_tablespace_size(spcname)) AS size
FROM pg_tablespace;

\echo
\echo ============================================================================
\echo RECENT CHECKPOINTS
\echo ============================================================================
\echo

SELECT 
    checkpoints_timed,
    checkpoints_req,
    checkpoint_write_time,
    checkpoint_sync_time,
    buffers_checkpoint,
    buffers_clean,
    buffers_backend,
    buffers_backend_fsync,
    buffers_alloc
FROM pg_stat_bgwriter;

\echo
\echo ============================================================================
\echo PGBACKREST CONFIGURATION CHECK (If Using pgBackRest)
\echo ============================================================================
\echo

-- Note: pgBackRest stores info in pgbackrest.conf, not database
-- This checks for pgbackrest extension if installed

SELECT 
    extname,
    extversion
FROM pg_extension
WHERE extname LIKE '%backrest%'
OR extname LIKE '%backup%';

\echo
\echo ============================================================================
\echo BASE BACKUP HISTORY (If Using pg_basebackup)
\echo ============================================================================
\echo

-- Check pg_wal directory for backup labels
-- This requires file system access, showing query for reference

\echo Query to check backup history:
\echo SELECT * FROM pg_ls_waldir() WHERE name LIKE '%backup%' OR name LIKE '%history%';

\echo
\echo ============================================================================
\echo POINT-IN-TIME RECOVERY (PITR) READINESS
\echo ============================================================================
\echo

SELECT 
    pg_is_in_recovery() AS is_standby,
    pg_last_wal_receive_lsn() AS last_received_lsn,
    pg_last_wal_replay_lsn() AS last_replayed_lsn,
    pg_last_xact_replay_timestamp() AS last_replay_timestamp,
    pg_current_wal_lsn() AS current_wal_lsn
FROM pg_stat_database
LIMIT 1;

\echo
\echo ============================================================================
\echo STANDBY SERVER STATUS (If This Is a Replica)
\echo ============================================================================
\echo

SELECT 
    pg_is_in_recovery() AS is_recovery,
    pg_last_wal_receive_lsn() AS receive_lsn,
    pg_last_wal_replay_lsn() AS replay_lsn,
    pg_last_xact_replay_timestamp() AS replay_timestamp,
    EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS replay_lag_seconds;

\echo
\echo ============================================================================
\echo WAL GENERATION RATE (Estimate Backup Requirements)
\echo ============================================================================
\echo

-- Approximate WAL generation (requires monitoring over time)
SELECT 
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS total_wal_generated;

\echo
\echo ============================================================================
\echo CONNECTION AND SESSION LIMITS
\echo ============================================================================
\echo

SELECT 
    name,
    setting,
    unit,
    context
FROM pg_settings
WHERE name IN (
    'max_connections',
    'superuser_reserved_connections',
    'statement_timeout',
    'lock_timeout',
    'idle_in_transaction_session_timeout'
);

SELECT 
    count(*) AS current_connections,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - count(*) AS available_connections
FROM pg_stat_activity;

\echo
\echo ============================================================================
\echo LONG-RUNNING QUERIES (Potential Backup Window Issues)
\echo ============================================================================
\echo

SELECT 
    pid,
    usename,
    datname,
    client_addr,
    application_name,
    state,
    wait_event_type,
    wait_event,
    query_start,
    NOW() - query_start AS duration,
    SUBSTR(query, 1, 100) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
AND NOW() - query_start > interval '5 minutes'
ORDER BY duration DESC
LIMIT 20;

\echo
\echo ============================================================================
\echo UNCOMMITTED TRANSACTIONS (Backup Consistency Check)
\echo ============================================================================
\echo

SELECT 
    pid,
    usename,
    datname,
    client_addr,
    xact_start,
    state,
    NOW() - xact_start AS transaction_duration,
    SUBSTR(query, 1, 100) AS query_preview
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
AND NOW() - xact_start > interval '10 minutes'
ORDER BY transaction_duration DESC;

\echo
\echo ============================================================================
\echo BACKUP RECOMMENDATIONS CHECKLIST
\echo ============================================================================
\echo

\echo 
\echo BACKUP CONFIGURATION CHECKLIST:
\echo ✓ archive_mode = on (required for PITR)
\echo ✓ archive_command configured and tested
\echo ✓ wal_level = replica (minimum for replication)
\echo ✓ max_wal_senders >= 3 (for replication + backups)
\echo ✓ Regular base backups scheduled (pg_basebackup or pgBackRest)
\echo ✓ WAL archiving monitored for failures
\echo ✓ Backup retention policy documented
\echo ✓ Restore testing scheduled quarterly
\echo ✓ Offsite backup replication configured
\echo ✓ Backup alerts configured (email/SMS)
\echo

\echo RECOVERY READINESS:
\echo ✓ Documented recovery procedures (runbook)
\echo ✓ RTO (Recovery Time Objective) defined and tested
\echo ✓ RPO (Recovery Point Objective) defined and met
\echo ✓ Backup verification script running regularly
\echo ✓ Standby server configured and synchronized (if applicable)
\echo

\echo RECOMMENDED TOOLS:
\echo - pgBackRest: Enterprise-grade backup with compression, deduplication
\echo - WAL-G: Cloud-native WAL archiving (S3, GCS, Azure)
\echo - Barman: Backup and recovery manager for PostgreSQL
\echo - pg_basebackup: Built-in base backup tool
\echo - repmgr: Replication manager with backup features
\echo

\echo ============================================================================
\echo SCRIPT COMPLETE
\echo ============================================================================
\echo

-- ============================================================================
-- USAGE NOTES FOR CLIENTS:
-- 
-- 1. Run weekly as part of routine DBA maintenance
-- 2. Archive results for compliance/audit purposes
-- 3. Set up alerts for archive failures
-- 4. Test restore procedures quarterly (documented in runbook)
-- 5. Ensure WAL archiving stays current (no growing lag)
-- 6. Recommended: Implement automated backup monitoring
--
-- This script demonstrates PostgreSQL backup/recovery expertise.
-- Available for full backup strategy implementation and DR planning.
--
-- Contact: [Your Contact Info]
-- ============================================================================
