-- ============================================================================
-- Oracle DBA Portfolio Sample #2: Backup Verification Script
-- Purpose: Comprehensive RMAN backup health check
-- Author: OpenClaw (Oracle DBA Agent)
-- Use Case: Database health check deliverable for freelance clients
-- ============================================================================

SET ECHO OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 100
SET LINESIZE 150
COLUMN backup_type FORMAT A20
COLUMN status FORMAT A15
COLUMN start_time FORMAT A25
COLUMN end_time FORMAT A25
COLUMN output_device_type FORMAT A15

PROMPT
PROMPT ============================================================================
-- RMAN BACKUP SUMMARY (Last 7 Days)
PROMPT ============================================================================
PROMPT

SELECT 
    session_key,
    input_type AS backup_type,
    status,
    TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI:SS') AS start_time,
    TO_CHAR(end_time, 'YYYY-MM-DD HH24:MI:SS') AS end_time,
    ROUND(elapsed_seconds / 60, 2) AS elapsed_minutes,
    output_device_type,
    output_bytes_display
FROM v$rman_backup_job_details
WHERE start_time >= SYSDATE - 7
ORDER BY start_time DESC;

PROMPT
PROMPT ============================================================================
-- BACKUP PIECES STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    piece_name,
    backup_type,
    status,
    TO_CHAR(completion_time, 'YYYY-MM-DD HH24:MI:SS') AS completion_time,
    pieces,
    ROUND(bytes / 1024 / 1024, 2) AS size_mb
FROM v$backup_piece
WHERE completion_time >= SYSDATE - 7
ORDER BY completion_time DESC;

PROMPT
PROMPT ============================================================================
-- ARCHIVELOG BACKUP STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    sequence#,
    first_time,
    next_time,
    blocks * block_size AS size_bytes,
    archived,
    deleted
FROM v$archived_log
WHERE first_time >= SYSDATE - 7
ORDER BY sequence# DESC;

PROMPT
PROMPT ============================================================================
-- RECOVERY WINDOW CHECK
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value,
    unit
FROM v$rman_configuration
WHERE name LIKE '%RETENTION%';

PROMPT
PROMPT ============================================================================
-- FLASHBACK DATABASE STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value
FROM v$flashback_database_log;

SELECT 
    oldest_flashback_time,
    retention_target,
    flashback_size,
    estimated_flashback_size
FROM v$flashback_database_log;

PROMPT
PROMPT ============================================================================
-- DATAFILE BACKUP STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    file#,
    name,
    TO_CHAR(checkpoint_time, 'YYYY-MM-DD HH24:MI:SS') AS last_checkpoint,
    TO_CHAR(first_time, 'YYYY-MM-DD HH24:MI:SS') AS first_backup,
    TO_CHAR(last_time, 'YYYY-MM-DD HH24:MI:SS') AS last_backup
FROM v$datafile df
JOIN v$backup b ON df.file# = b.file#
WHERE b.status = 'ACTIVE' OR b.status = 'NOT ACTIVE'
GROUP BY file#, name, checkpoint_time, first_time, last_time;

PROMPT
PROMPT ============================================================================
-- CONTROLFILE BACKUP STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    type,
    status,
    TO_CHAR(completion_time, 'YYYY-MM-DD HH24:MI:SS') AS completion_time,
    pieces
FROM v$controlfile_backup
ORDER BY completion_time DESC;

PROMPT
PROMPT ============================================================================
-- SPFILE BACKUP STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    bs_key,
    backup_type,
    status,
    TO_CHAR(completion_time, 'YYYY-MM-DD HH24:MI:SS') AS completion_time,
    pieces
FROM v$backup_spfile
ORDER BY completion_time DESC;

PROMPT
PROMPT ============================================================================
-- BACKUP STORAGE LOCATION CHECK
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value
FROM v$diag_info
WHERE name LIKE '%Archive%';

PROMPT
PROMPT ============================================================================
-- FRA (Fast Recovery Area) USAGE
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value,
    unit
FROM v$recovery_file_dest;

SELECT 
    file_type,
    percent_space_used,
    percent_space_reclaimable,
    number_of_files
FROM v$flash_recovery_area_usage;

PROMPT
PROMPT ============================================================================
-- BACKUP ERRORS (Last 30 Days)
PROMPT ============================================================================
PROMPT

SELECT 
    session_key,
    input_type,
    status,
    TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI:SS') AS start_time,
    TO_CHAR(end_time, 'YYYY-MM-DD HH24:MI:SS') AS end_time,
    error
FROM v$rman_backup_job_details
WHERE status = 'FAILED'
AND start_time >= SYSDATE - 30
ORDER BY start_time DESC;

PROMPT
PROMPT ============================================================================
-- BACKUP RECOMMENDATIONS REPORT
PROMPT ============================================================================
PROMPT

PROMPT 
PROMPT CHECKLIST FOR CLIENT:
PROMPT ✓ Verify backups completed successfully (status = COMPLETED)
PROMPT ✓ Check backup duration is within acceptable window
PROMPT ✓ Confirm archive logs are being backed up regularly
PROMPT ✓ Validate FRA has sufficient free space (> 20%)
PROMPT ✓ Test restore procedures quarterly
PROMPT ✓ Document backup retention policy
PROMPT ✓ Verify offsite backup replication (if applicable)
PROMPT ✓ Check for any failed backup jobs in last 30 days
PROMPT

PROMPT ============================================================================
-- SCRIPT COMPLETE
PROMPT ============================================================================
PROMPT

-- ============================================================================
-- USAGE NOTES FOR CLIENTS:
-- 
-- 1. Run weekly as part of routine DBA maintenance
-- 2. Archive results for compliance/audit purposes
-- 3. Set up alerts for FAILED backup status
-- 4. Test restore procedures quarterly (documented in runbook)
-- 5. Ensure FRA usage stays below 80%
-- 6. Recommended: Implement automated backup monitoring
--
-- This script demonstrates comprehensive backup verification expertise.
-- Available for full backup strategy implementation and DR planning.
--
-- Contact: [Your Contact Info]
-- ============================================================================
