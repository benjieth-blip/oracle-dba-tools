-- ============================================================================
-- Oracle DBA Portfolio Sample #3: Data Guard Health Check
-- Purpose: Verify Data Guard configuration and synchronization status
-- Author: OpenClaw (Oracle DBA Agent)
-- Use Case: HA/DR audit deliverable for freelance clients
-- ============================================================================

SET ECHO OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 100
SET LINESIZE 150
COLUMN database_role FORMAT A20
COLUMN protection_mode FORMAT A25
COLUMN protection_level FORMAT A25
COLUMN status FORMAT A15
COLUMN destination FORMAT A30

PROMPT
PROMPT ============================================================================
-- DATABASE ROLE AND PROTECTION MODE
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    database_role,
    protection_mode,
    protection_level,
    open_mode,
    force_logging
FROM v$database;

PROMPT
PROMPT ============================================================================
-- DATA GUARD CONFIGURATION
PROMPT ============================================================================
PROMPT

SELECT 
    dest_id,
    destination,
    status,
    target,
    schedule,
    transport_mode,
    affirm,
    async_blocks,
    net_timeout,
    delay_mins,
    reopen_secs,
    register,
    binding,
    valid_for
FROM v$archive_dest
WHERE target = 'STANDBY'
ORDER BY dest_id;

PROMPT
PROMPT ============================================================================
-- STANDBY DATABASE STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    dest_id,
    status,
    error
FROM v$archive_dest_status
WHERE status != 'VALID'
OR error IS NOT NULL;

PROMPT
PROMPT ============================================================================
-- MANAGED RECOVERY PROCESS (MRP) STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    process,
    status,
    thread#,
    sequence#,
    block#,
    blocks
FROM v$managed_standby
WHERE process LIKE '%MRP%'
OR process LIKE '%RFS%';

PROMPT
PROMPT ============================================================================
-- ARCHIVE GAP DETECTION
PROMPT ============================================================================
PROMPT

SELECT 
    thread#,
    low_sequence#,
    high_sequence#
FROM v$archive_gap;

PROMPT
PROMPT ============================================================================
-- STANDBY REDO LOG STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    group#,
    thread#,
    sequence#,
    bytes,
    used,
    archived,
    status
FROM v$standby_log
ORDER BY group#;

PROMPT
PROMPT ============================================================================
-- LOG TRANSPORT STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    thread#,
    sequence#,
    first_time,
    next_time,
    applied,
    status
FROM v$archived_log
WHERE standby_thread# IS NOT NULL
AND first_time >= SYSDATE - 1
ORDER BY first_time DESC;

PROMPT
PROMPT ============================================================================
-- APPLY LAG (Physical Standby)
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value,
    unit
FROM v$dataguard_stats
WHERE name LIKE '%lag%'
OR name LIKE '%delay%';

PROMPT
PROMPT ============================================================================
-- FLASHBACK DATABASE STATUS (Both Primary and Standby)
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value
FROM v$flashback_database_log;

PROMPT
PROMPT ============================================================================
-- FAILOVER AND SWITCHOVER READINESS
PROMPT ============================================================================
PROMPT

SELECT 
    name,
    value
FROM v$database
WHERE name IN ('DATABASE_ROLE', 'PROTECTION_MODE', 'PROTECTION_LEVEL');

SELECT 
    switchover_status,
    fsfo_status
FROM v$database;

PROMPT
PROMPT ============================================================================
-- RECENT ARCHIVE LOG APPLY STATUS
PROMPT ============================================================================
PROMPT

SELECT 
    thread#,
    sequence#,
    TO_CHAR(first_time, 'YYYY-MM-DD HH24:MI:SS') AS first_time,
    TO_CHAR(next_time, 'YYYY-MM-DD HH24:MI:SS') AS next_time,
    applied,
    registrar,
    status
FROM v$archived_log
WHERE first_time >= SYSDATE - 7
ORDER BY first_time DESC;

PROMPT
PROMPT ============================================================================
-- DATA GUARD ERROR LOG (Last 24 Hours)
PROMPT ============================================================================
PROMPT

SELECT 
    TO_CHAR(timestamp, 'YYYY-MM-DD HH24:MI:SS') AS timestamp,
    message
FROM v$dataguard_status
WHERE severity IN ('Error', 'Warning')
AND timestamp >= SYSDATE - 1
ORDER BY timestamp DESC;

PROMPT
PROMPT ============================================================================
-- DATA GUARD HEALTH CHECK SUMMARY
PROMPT ============================================================================
PROMPT

PROMPT
PROMPT CHECKLIST FOR CLIENT:
PROMPT ✓ Primary database role confirmed (should be PRIMARY)
PROMPT ✓ Standby database accessible and in MOUNT or OPEN mode
PROMPT ✓ No archive gaps detected
PROMPT ✓ MRP process running on standby
PROMPT ✓ Apply lag within acceptable threshold (< 5 minutes recommended)
PROMPT ✓ Standby redo logs configured and active
PROMPT ✓ No errors in Data Guard status log
PROMPT ✓ Switchover/failover tested within last 6 months
PROMPT ✓ Flashback database enabled (optional but recommended)
PROMPT ✓ FRA sized appropriately for both primary and standby
PROMPT

PROMPT RECOMMENDED ACTIONS:
PROMPT 1. Document current configuration in runbook
PROMPT 2. Schedule quarterly failover test
PROMPT 3. Set up monitoring alerts for apply lag > 10 minutes
PROMPT 4. Review archive destination status weekly
PROMPT 5. Test restore from standby annually
PROMPT

PROMPT ============================================================================
-- SCRIPT COMPLETE
PROMPT ============================================================================
PROMPT

-- ============================================================================
-- USAGE NOTES FOR CLIENTS:
-- 
-- 1. Run daily on both primary and standby databases
-- 2. Archive results for compliance/audit purposes
-- 3. Set up alerts for:
--    - Apply lag > 10 minutes
--    - Archive gaps detected
--    - MRP process not running
--    - Any ERROR severity in Data Guard status
-- 4. Test failover/switchover quarterly (document results)
-- 5. Review and update runbook after any configuration changes
--
-- This script demonstrates Data Guard expertise for HA/DR implementations.
-- Available for full Data Guard setup, troubleshooting, and DR planning.
--
-- Contact: [Your Contact Info]
-- ============================================================================
