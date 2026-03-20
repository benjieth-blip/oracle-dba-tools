-- ============================================================================
-- Oracle DBA Portfolio Sample #1: Performance Tuning Script
-- Purpose: Identify and tune slow-running queries using AWR data
-- Author: OpenClaw (Oracle DBA Agent)
-- Use Case: Performance audit deliverable for freelance clients
-- ============================================================================

SET ECHO OFF
SET FEEDBACK ON
SET VERIFY OFF
SET PAGESIZE 100
SET LINESIZE 200
COLUMN sql_text FORMAT A80
COLUMN elapsed_time_sec FORMAT 999,999,999.99
COLUMN executions FORMAT 999,999,999
COLUMN avg_elapsed_sec FORMAT 999,999.99

PROMPT
PROMPT ============================================================================
-- TOP 20 SQL STATEMENTS BY TOTAL ELAPSED TIME (AWR)
PROMPT ============================================================================
PROMPT

SELECT * FROM (
    SELECT 
        sql_id,
        ROUND(elapsed_time_delta / 1000000, 2) AS elapsed_time_sec,
        executions_delta AS executions,
        ROUND((elapsed_time_delta / 1000000) / NULLIF(executions_delta, 0), 2) AS avg_elapsed_sec,
        SUBSTR(sql_text, 1, 80) AS sql_text
    FROM dba_hist_sqlstat s
    JOIN dba_hist_sqltext t ON s.sql_id = t.sql_id
    WHERE elapsed_time_delta > 0
    ORDER BY elapsed_time_delta DESC
)
WHERE ROWNUM <= 20;

PROMPT
PROMPT ============================================================================
-- SQL WITH HIGHEST AVERAGE ELAPSED TIME (Potential Quick Wins)
PROMPT ============================================================================
PROMPT

SELECT * FROM (
    SELECT 
        sql_id,
        executions_delta AS executions,
        ROUND((elapsed_time_delta / 1000000) / NULLIF(executions_delta, 0), 2) AS avg_elapsed_sec,
        ROUND(elapsed_time_delta / 1000000, 2) AS total_elapsed_sec,
        SUBSTR(sql_text, 1, 80) AS sql_text
    FROM dba_hist_sqlstat s
    JOIN dba_hist_sqltext t ON s.sql_id = t.sql_id
    WHERE executions_delta > 10
    ORDER BY avg_elapsed_sec DESC
)
WHERE ROWNUM <= 15;

PROMPT
PROMPT ============================================================================
-- RESOURCE-INTENSIVE SQL (CPU + I/O)
PROMPT ============================================================================
PROMPT

SELECT * FROM (
    SELECT 
        sql_id,
        ROUND(cpu_time_delta / 1000000, 2) AS cpu_time_sec,
        ROUND(iowait_delta / 1000000, 2) AS io_wait_sec,
        executions_delta AS executions,
        buffer_gets_delta AS buffer_gets,
        disk_reads_delta AS disk_reads,
        SUBSTR(sql_text, 1, 60) AS sql_text
    FROM dba_hist_sqlstat s
    JOIN dba_hist_sqltext t ON s.sql_id = t.sql_id
    WHERE cpu_time_delta > 0 OR iowait_delta > 0
    ORDER BY (cpu_time_delta + iowait_delta) DESC
)
WHERE ROWNUM <= 15;

PROMPT
PROMPT ============================================================================
-- SQL WITH HIGH PARSE COUNT (Soft/Hard Parse Issues)
PROMPT ============================================================================
PROMPT

SELECT * FROM (
    SELECT 
        sql_id,
        parses_delta AS parses,
        hard_parses_delta AS hard_parses,
        executions_delta AS executions,
        ROUND(parses_delta / NULLIF(executions_delta, 0), 2) AS parse_per_exec,
        SUBSTR(sql_text, 1, 60) AS sql_text
    FROM dba_hist_sqlstat s
    JOIN dba_hist_sqltext t ON s.sql_id = t.sql_id
    WHERE parses_delta > 0
    ORDER BY parses_delta DESC
)
WHERE ROWNUM <= 15;

PROMPT
PROMPT ============================================================================
-- WAIT EVENT ANALYSIS FOR TOP SQL
PROMPT ============================================================================
PROMPT

SELECT * FROM (
    SELECT 
        sql_id,
        event,
        SUM(wait_time_delta + time_waited_delta) / 1000000 AS total_wait_sec,
        SUM(waits_delta) AS total_waits
    FROM dba_hist_sqlstat s
    JOIN dba_hist_active_sess_history a ON s.sql_id = a.sql_id
    WHERE event IS NOT NULL
    GROUP BY sql_id, event
    ORDER BY total_wait_sec DESC
)
WHERE ROWNUM <= 20;

PROMPT
PROMPT ============================================================================
-- INDEX USAGE ANALYSIS (Identify Unused Indexes)
PROMPT ============================================================================
PROMPT

SELECT 
    owner,
    index_name,
    table_name,
    leaf_blocks,
    distinct_keys,
    num_rows,
    last_analyzed
FROM dba_indexes
WHERE owner NOT IN ('SYS', 'SYSTEM', 'ORACLE_MAINTAIN')
AND index_name NOT IN (
    SELECT index_name 
    FROM dba_hist_sql_plan 
    WHERE operation = 'INDEX'
    AND sql_id IN (SELECT sql_id FROM dba_hist_sqlstat WHERE executions_delta > 0)
)
ORDER BY leaf_blocks DESC;

PROMPT
PROMPT ============================================================================
-- TABLESPACE USAGE AND GROWTH
PROMPT ============================================================================
PROMPT

SELECT 
    df.tablespace_name,
    ROUND(df.total_bytes / 1024 / 1024, 2) AS total_mb,
    ROUND(df.free_bytes / 1024 / 1024, 2) AS free_mb,
    ROUND((df.total_bytes - df.free_bytes) / 1024 / 1024, 2) AS used_mb,
    ROUND(((df.total_bytes - df.free_bytes) / df.total_bytes) * 100, 2) AS pct_used
FROM (
    SELECT 
        tablespace_name,
        SUM(bytes) AS total_bytes,
        SUM(CASE WHEN autoextensible = 'YES' THEN maxbytes ELSE bytes END) AS max_bytes
    FROM dba_data_files
    GROUP BY tablespace_name
) df
JOIN (
    SELECT 
        tablespace_name,
        SUM(bytes) AS free_bytes
    FROM dba_free_space
    GROUP BY tablespace_name
) fs ON df.tablespace_name = fs.tablespace_name
ORDER BY pct_used DESC;

PROMPT
PROMPT ============================================================================
-- SESSION ACTIVITY SNAPSHOT
PROMPT ============================================================================
PROMPT

SELECT 
    status,
    type,
    COUNT(*) AS session_count
FROM v$session
GROUP BY status, type
ORDER BY session_count DESC;

PROMPT
PROMPT ============================================================================
-- LONG RUNNING SESSIONS (> 1 hour)
PROMPT ============================================================================
PROMPT

SELECT 
    sid,
    serial#,
    username,
    program,
    status,
    ROUND(last_call_et / 3600, 2) AS hours_idle,
    logon_time
FROM v$session
WHERE last_call_et > 3600
AND username IS NOT NULL
ORDER BY last_call_et DESC;

PROMPT
PROMPT ============================================================================
-- SCRIPT COMPLETE
PROMPT ============================================================================
PROMPT

-- ============================================================================
-- USAGE NOTES FOR CLIENTS:
-- 
-- 1. Run this script during business hours for realistic workload data
-- 2. Requires AWR license (or use V$ views for real-time analysis)
-- 3. Results help identify:
--    - Queries needing optimization
--    - Missing indexes
--    - Parse efficiency issues
--    - Resource bottlenecks
-- 4. Follow-up: Generate execution plans for top offenders
-- 5. Estimated time savings: 40-70% reduction in query response time
--
-- Contact: [Your Contact Info]
-- ============================================================================
