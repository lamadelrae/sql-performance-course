-- 1.1 Cria base de exemplo e tabelas
CREATE DATABASE DemoSqlPerf;
GO

USE DemoSqlPerf;
GO

ALTER DATABASE DemoSQLPerf
SET QUERY_STORE = ON;
GO

CREATE TABLE Clientes (
    ClienteId INT IDENTITY PRIMARY KEY,
    Nome     VARCHAR(100),
    Email    VARCHAR(100)
);
GO

CREATE TABLE Vendas (
    VendaId   INT IDENTITY PRIMARY KEY,
    ClienteId INT,
    Valor     DECIMAL(10, 2),
    DataVenda DATE
);
GO

-- 1.2 Gera e materializa a sequência “tally” super-rápida
;WITH 
  E1 AS (SELECT 1 AS dummy UNION ALL SELECT 1),
  E2 AS (SELECT a.dummy FROM E1 a CROSS JOIN E1 b),
  E4 AS (SELECT a.dummy FROM E2 a CROSS JOIN E2 b),
  E8 AS (SELECT a.dummy FROM E4 a CROSS JOIN E4 b),
  E16 AS (SELECT a.dummy FROM E8 a CROSS JOIN E8 b),
  Numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM E16 a
    CROSS JOIN E16 b
  )
SELECT num
INTO #Numbers
FROM Numbers
WHERE num <= 5000000;  -- gera até o maior volume que você precisa
GO

-- 1.3 Popula Clientes com os primeiros 1.000.000 de registros
INSERT INTO Clientes (Nome, Email)
SELECT
    'Cliente ' + CAST(num AS VARCHAR(12))                           AS Nome,
    'cliente' + CAST(num AS VARCHAR(12)) + '@exemplo.com'          AS Email
FROM #Numbers
WHERE num <= 1000000;    -- ajuste o limite conforme necessário
GO

-- 1.4 Popula Vendas com 5.000.000 de registros
INSERT INTO Vendas (ClienteId, Valor, DataVenda)
SELECT
    ABS(CHECKSUM(NEWID())) % 1000000 + 1                           AS ClienteId,
    ROUND(RAND(CHECKSUM(NEWID())) * 1000, 2)                       AS Valor,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE())         AS DataVenda
FROM #Numbers
WHERE num <= 5000000;    -- ajuste conforme sua necessidade de volume
GO

-- 1.5 Limpa a temp table
DROP TABLE #Numbers;
GO
