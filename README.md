# Oracle & PostgreSQL DBA Tools

**Author:** Binyam T  
**Experience:** 12+ years Oracle Database Administration  
**Specializations:** Performance Tuning, High Availability, Cloud Migrations

---

## 📚 About This Repository

This repository contains production-ready scripts and tools I've developed over 12+ years as a Senior Oracle Database Consultant. These tools are used in client engagements for:

- Performance tuning and diagnostics
- Backup and recovery verification
- High availability (Data Guard, RAC)
- Cloud migrations (Oracle→PostgreSQL, Oracle→Azure)

---

## 🗂️ Repository Structure

```
oracle-dba-tools/
├── oracle/
│   ├── performance-tuning.sql
│   ├── rman-backup-check.sql
│   ├── dataguard-health-check.sql
│   └── rac-status.sql
├── postgresql/
│   ├── performance-analysis.sql
│   ├── backup-verification.sql
│   └── replication-monitoring.sql
├── migrations/
│   ├── oracle-to-postgresql/
│   └── oracle-to-azure/
├── automation/
│   ├── backup-automation.sh
│   └── monitoring-alerts.py
└── docs/
    ├── usage-guide.md
    └── best-practices.md
```

---

## 🛠️ Oracle Scripts

### 1. Performance Tuning (`oracle/performance-tuning.sql`)

**Purpose:** Identify top SQL statements causing performance bottlenecks using AWR data.

**Usage:**
```sql
-- Connect as DBA user
sqlplus / as sysdba

-- Run the script
@performance-tuning.sql

-- Review output:
-- - Top 20 SQL by elapsed time
-- - High average elapsed time queries
-- - CPU + I/O intensive SQL
-- - Index usage analysis
```

**Typical Results:** 40-70% query improvement after implementing recommendations.

---

### 2. RMAN Backup Check (`oracle/rman-backup-check.sql`)

**Purpose:** Comprehensive backup health check for Oracle databases.

**Usage:**
```sql
-- Run weekly as part of DBA maintenance
@rman-backup-check.sql

-- Checks:
-- ✓ RMAN backup status (last 7 days)
-- ✓ Backup pieces verification
-- ✓ Archive log backup status
-- ✓ FRA usage monitoring
-- ✓ Failed backup detection
```

**Best Practice:** Run weekly, archive results for compliance audits.

---

### 3. Data Guard Health Check (`oracle/dataguard-health-check.sql`)

**Purpose:** Verify Data Guard configuration and synchronization status.

**Usage:**
```sql
-- Run on both primary and standby databases
@dataguard-health-check.sql

-- Monitors:
-- ✓ Apply lag (should be < 5 minutes)
-- ✓ Archive gaps (should be zero)
-- ✓ MRP process status
-- ✓ Switchover readiness
```

**Alert Threshold:** Apply lag > 10 minutes requires immediate investigation.

---

## 🐘 PostgreSQL Scripts

### 1. Performance Analysis (`postgresql/performance-analysis.sql`)

**Purpose:** Identify slow queries using pg_stat_statements.

**Prerequisites:**
```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

**Usage:**
```sql
-- Run during business hours for realistic workload
\i performance-analysis.sql

-- Analyzes:
-- - Top queries by total execution time
-- - Most frequently executed queries
-- - High I/O queries
-- - Unused indexes
-- - Lock contention
```

---

### 2. Backup Verification (`postgresql/backup-verification.sql`)

**Purpose:** Verify backup configuration and recovery readiness.

**Usage:**
```sql
\i backup-verification.sql

-- Checks:
-- ✓ WAL archiving status
-- ✓ Streaming replication status
-- ✓ PITR readiness
-- ✓ Backup tool configuration (pgBackRest, WAL-G)
```

---

## 🚀 Migration Tools

### Oracle → PostgreSQL

**Tools Used:**
- `ora2pg` - Schema conversion
- `pgLoader` - Data migration
- Custom validation scripts

**Documentation:** See `migrations/oracle-to-postgresql/README.md`

---

### Oracle → Azure SQL

**Tools Used:**
- Azure Database Migration Service
- Custom T-SQL conversion scripts

**Documentation:** See `migrations/oracle-to-azure/README.md`

---

## 📖 Blog Articles

I write detailed case studies and technical guides on my blog:

🔗 **Blog:** [database-insights-binyam.blogspot.com](https://database-insights-binyam.blogspot.com)

**Recent Articles:**
1. [Oracle Performance Tuning: 45min to 90sec Case Study](#)
2. [RMAN Backup Best Practices: 100+ Implementations](#)
3. [Data Guard Implementation for Financial Services](#)
4. [Oracle to Azure Migration Guide](#)
5. [Oracle to PostgreSQL Migration: Complete Guide](#)

---

## 💼 Consulting Services

I offer database consulting services for:

### Performance Tuning
- AWR/ASH analysis
- SQL optimization
- Index strategy
- Configuration tuning

---

### Backup & Disaster Recovery
- Backup strategy design
- RMAN/pgBackRest configuration
- DR testing and documentation
- Compliance audits (SOX, HIPAA, PCI)


---

### High Availability
- Oracle: RAC, Data Guard, GoldenGate
- PostgreSQL: Patroni, streaming replication
- Azure: Always On, geo-replication

**Engagement:** $5,000-20,000

---

### Cloud Migrations
- Oracle → PostgreSQL
- Oracle → Azure SQL
- On-premise → Cloud (AWS, Azure, OCI)


---

## 📞 Contact

**Upwork:** [Profile](https://www.upwork.com/freelancers/~013f55a2420aa5df34)  
**Blog:** [database-insights-binyam.blogspot.com](https://database-insights-binyam.blogspot.com)  
**Email:** [Via Upwork or blog contact form]

---

## 📄 License

These scripts are provided as-is for educational and professional use. Feel free to use and modify for your own projects.

**Attribution appreciated but not required.**

---

## ⭐ Support

If these scripts helped you, consider:
1. Starring this repository ⭐
2. Reading my blog articles
3. Hiring me for consulting engagements

---

*Last Updated: March 2026*  
*Author: Binyam T*
