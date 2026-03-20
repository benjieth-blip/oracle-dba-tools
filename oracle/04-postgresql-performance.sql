-- ============================================================================
-- PostgreSQL Portfolio Sample #1: Performance Analysis Script
-- Purpose: Identify slow queries and optimization opportunities
-- Author: OpenClaw (Database Consultant)
-- Use Case: Performance audit deliverable for freelance clients
-- ============================================================================

-- NOTE: Requires pg_stat_statements extension enabled
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\echo
\echo ============================================================================
\echo TOP 20 QUERIES BY TOTAL EXECUTION TIME
\echo ============================================================================
\echo

SELECT 
    queryid,
    SUBSTR(query, 1, 80) AS query_preview,
    calls,
    ROUND(total_exec_time / 1000, 2) AS total_time_sec,
    ROUND(mean_exec_time, 2) AS avg_time_ms,
    ROUND(max_exec_time, 2) AS max_time_ms,
    rows,
    ROUND(mean_exec_time * calls / 1000 / 3600, 2) AS total_hours
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY total_exec_time DESC
LIMIT 20;

\echo
\echo ============================================================================
\echo TOP 15 QUERIES BY AVERAGE EXECUTION TIME (Potential Quick Wins)
\echo ============================================================================
\echo

SELECT 
    queryid,
    SUBSTR(query, 1, 80) AS query_preview,
    calls,
    ROUND(mean_exec_time, 2) AS avg_time_ms,
    ROUND(max_exec_time, 2) AS max_time_ms,
    rows,
    ROUND(rows / NULLIF(calls, 0), 2) AS avg_rows
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
AND calls >= 10
ORDER BY mean_exec_time DESC
LIMIT 15;

\echo
\echo ============================================================================
\echo MOST FREQUENTLY EXECUTED QUERIES (High Impact Optimization Targets)
\echo ============================================================================
\echo

SELECT 
    queryid,
    SUBSTR(query, 1, 80) AS query_preview,
    calls,
    ROUND(total_exec_time / 1000, 2) AS total_time_sec,
    ROUND(mean_exec_time, 2) AS avg_time_ms,
    rows
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY calls DESC
LIMIT 15;

\echo
\echo ============================================================================
\echo QUERIES WITH HIGH I/O (Shared Block Reads)
\echo ============================================================================
\echo

SELECT 
    queryid,
    SUBSTR(query, 1, 80) AS query_preview,
    calls,
    shared_blks_read,
    shared_blks_hit,
    ROUND(100.0 * shared_blks_hit / NULLIF(shared_blks_read + shared_blks_hit, 0), 2) AS hit_ratio_pct,
    ROUND(total_exec_time / 1000, 2) AS total_time_sec
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
AND shared_blks_read > 0
ORDER BY shared_blks_read DESC
LIMIT 15;

\echo
\echo ============================================================================
\echo TABLE SIZE AND INDEX USAGE
\echo ============================================================================
\echo

SELECT 
    schemaname,
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

\echo
\echo ============================================================================
\echo UNUSED OR UNDERUSED INDEXES (Candidates for Removal)
\echo ============================================================================
\echo

SELECT 
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'RARELY USED'
        ELSE 'ACTIVE'
    END AS usage_status
FROM pg_stat_user_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC
LIMIT 20;

\echo
\echo ============================================================================
\echo LOCK CONTENTION AND BLOCKING
\echo ============================================================================
\echo

SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocked_activity.query AS blocked_query,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED
LIMIT 20;

\echo
\echo ============================================================================
\echo DATABASE SIZE AND GROWTH
\echo ============================================================================
\echo

SELECT 
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS size,
    pg_size_pretty(pg_database_size(datname) / 1024 / 1024) AS size_mb
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

\echo
\echo ============================================================================
\echo CONNECTION STATISTICS
\echo ============================================================================
\echo

SELECT 
    datname,
    numbackends AS active_connections,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit,
    tup_returned,
    tup_fetched,
    tup_inserted,
    tup_updated,
    tup_deleted,
    conflicts,
    temp_files,
    temp_bytes,
    deadlocks,
    blk_read_time,
    blk_write_time
FROM pg_stat_database
WHERE datname IS NOT NULL
ORDER BY numbackends DESC;

\echo
\echo ============================================================================
\echo VACUUM AND ANALYZE STATUS
\echo ============================================================================
\echo

SELECT 
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_pct,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    vacuum_count,
    autovacuum_count,
    analyze_count,
    autoanalyze_count
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC
LIMIT 20;

\echo
\echo ============================================================================
\echo RECOMMENDATIONS SUMMARY
\echo ============================================================================
\echo

\echo 
\echo CHECKLIST FOR CLIENT:
\echo ✓ Review top queries by total time (optimization candidates)
\echo ✓ Check queries with low cache hit ratio (< 95% needs attention)
\echo ✓ Identify unused indexes (can be dropped to save space/write time)
\echo ✓ Monitor lock contention (blocking queries need investigation)
\echo ✓ Check dead tuple percentage (> 20% needs VACUUM)
\echo ✓ Verify autovacuum is running regularly
\echo ✓ Review connection count vs max_connections setting
\echo

\echo PERFORMANCE TUNING ACTIONS:
\echo 1. Add indexes for frequently filtered/joined columns
\echo 2. Update statistics: ANALYZE [table_name];
\echo 3. Consider partitioning for large tables (> 10M rows)
\echo 4. Tune shared_buffers (25% of RAM typical)
\echo 5. Adjust work_mem for complex queries
\echo 6. Enable parallel query for large scans
\echo 7. Review and optimize queries with high I/O
\echo

\echo ============================================================================
\echo SCRIPT COMPLETE
\echo ============================================================================
\echo

-- ============================================================================
-- USAGE NOTES FOR CLIENTS:
-- 
-- 1. Requires pg_stat_statements extension (add to shared_preload_libraries)
-- 2. Run during business hours for realistic workload data
-- 3. Reset statistics periodically: SELECT pg_stat_statements_reset();
-- 4. Archive results for trend analysis
-- 5. Typical optimization results: 40-70% query improvement
-- 6. Estimated time investment: 2-4 hours for full audit
--
-- This script demonstrates PostgreSQL performance expertise.
-- Available for full performance tuning engagements.
--
-- Contact: [Your Contact Info]
-- ============================================================================
