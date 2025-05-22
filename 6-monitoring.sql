USE DemoSQLPerf;
GO

-- 6.1 Query Store (ativar e consultar)

SELECT TOP 5
    qsq.query_id,
    qsqt.query_sql_text,
    rs.avg_logical_io_reads     AS avg_pages_read,
    rs.last_logical_io_reads    AS last_pages_read,
    rs.count_executions         AS execution_count,
    rs.avg_duration             AS avg_duration_us
FROM 
    sys.query_store_query_text   AS qsqt
    JOIN sys.query_store_query   AS qsq
      ON qsqt.query_text_id = qsq.query_text_id
    JOIN sys.query_store_plan    AS qsp
      ON qsq.query_id = qsp.query_id
    JOIN sys.query_store_runtime_stats AS rs
      ON qsp.plan_id = rs.plan_id
ORDER BY
    rs.avg_logical_io_reads DESC;

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
/********************************************************************
-- Script completo: cria sessão XE, executa consultas, para sessão
-- e exibe os eventos capturados (consultas em Clientes e Vendas)
********************************************************************/

/* 1) Caso já exista, remove a sessão anterior */
IF EXISTS (
    SELECT 1
    FROM sys.server_event_sessions
    WHERE name = 'CapturaClientesVendas'
)
    DROP EVENT SESSION CapturaClientesVendas ON SERVER;
GO

/* 2) Cria a sessão Extended Events */
CREATE EVENT SESSION CapturaClientesVendas
ON SERVER
-- Capture batches e RPCs finalizados
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(
        sqlserver.sql_text,
        sqlserver.username,
        sqlserver.client_hostname,
        sqlserver.session_id
    )
    WHERE duration > 0  -- capture tudo
),
ADD EVENT sqlserver.rpc_completed(
    ACTION(
        sqlserver.sql_text,
        sqlserver.username,
        sqlserver.client_hostname,
        sqlserver.session_id
    )
    WHERE duration > 0
)
-- Alvo em memória para leitura rápida
ADD TARGET package0.ring_buffer
WITH (
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 1 SECONDS,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = OFF
);
GO

/* 3) Inicia a sessão */
ALTER EVENT SESSION CapturaClientesVendas ON SERVER STATE = START;
GO

/* 4) Executa algumas consultas de exemplo */
-- Consulta 1: clientes cujo nome contenha '123'
SELECT ClienteId, Nome, Email
FROM Clientes
WHERE Nome LIKE '%123%';

-- Consulta 2: total de vendas por cliente
SELECT ClienteId, COUNT(*) AS QtdeVendas, SUM(Valor) AS TotalVendido
FROM Vendas
GROUP BY ClienteId
HAVING COUNT(*) > 5;

-- Consulta 3: vendas no último mês para cliente 42
SELECT *
FROM Vendas
WHERE ClienteId = 42
  AND DataVenda >= DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));

GO

/* 5) Para a sessão após as consultas */
GO

/* 6) Consulta os resultados capturados no ring_buffer */
SELECT
    ev.value('@name',       'varchar(50)')    AS event_name,
    ev.value('@timestamp',  'datetime2')       AS utc_timestamp,
    DATEADD(HOUR, -3, ev.value('@timestamp','datetime2')) AS local_timestamp,
    -- dados dentro de <data name="..."><value>...</value></data>
    ev.value('(data[@name="duration"]/value/text())[1]',      'bigint')  AS duration_us,
    ev.value('(data[@name="logical_reads"]/value/text())[1]', 'bigint')  AS logical_reads,
    ev.value('(data[@name="row_count"]/value/text())[1]',     'bigint')  AS row_count,
    -- texto da query capturada (via action sql_text)
    ev.value('(action[@name="sql_text"]/value/text())[1]',    'nvarchar(max)') AS sql_text,
    -- usuário e host, por via das actions
    ev.value('(action[@name="username"]/value/text())[1]',    'nvarchar(128)') AS username,
    ev.value('(action[@name="client_hostname"]/value/text())[1]','nvarchar(128)') AS client_host
FROM 
    sys.dm_xe_sessions AS s
    INNER JOIN sys.dm_xe_session_targets AS t
      ON s.address = t.event_session_address
    -- converte target_data para XML e expande cada <event> sob <RingBufferTarget>
    CROSS APPLY (
      SELECT CAST(t.target_data AS XML) AS xb
    ) AS buf
    CROSS APPLY buf.xb.nodes('RingBufferTarget/event') AS X(ev)
WHERE
    s.name = 'CapturaClientesVendas'
    AND t.target_name = 'ring_buffer'
ORDER BY
    ev.value('@timestamp','datetime2') DESC;

ALTER EVENT SESSION CapturaClientesVendas ON SERVER STATE = STOP;
GO


-- 6.4 sp_Who2 e PerfMon
EXEC sp_who2;
EXEC sp_WhoIsActive @get_task_info = 1;
GO
