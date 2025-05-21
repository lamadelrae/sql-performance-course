USE DemoSQLPerf;
GO

-- 6.1 Query Store (ativar e consultar)
ALTER DATABASE DemoSQLPerf
  SET QUERY_STORE = ON;
GO

SELECT TOP 5
    qs.query_id,
    qt.query_sql_text,
    rs.total_logical_reads,
    rs.execution_count,
    rs.avg_duration
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_query_text qt
  ON rs.query_text_id = qt.query_text_id
ORDER BY rs.total_logical_reads DESC;
GO

-- 6.2 DMVs: top CPU
SELECT TOP 5
    qs.total_worker_time/qs.execution_count AS avg_cpu,
    SUBSTRING(st.text,
      (qs.statement_start_offset/2)+1,
      ((CASE qs.statement_end_offset
         WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset END
       - qs.statement_start_offset)/2)+1
    ) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_cpu DESC;
GO

-- 6.3 Extended Events: sessão básica
CREATE EVENT SESSION CapturaLento
ON SERVER
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.sql_text, sqlserver.session_id)
    WHERE (duration > 1000000)  -- >1s
)
ADD TARGET package0.ring_buffer;
ALTER EVENT SESSION CapturaLento ON SERVER STATE = START;
GO

-- 6.4 sp_Who2 e PerfMon
EXEC sp_who2;
EXEC sp_WhoIsActive @get_task_info = 1;
GO
