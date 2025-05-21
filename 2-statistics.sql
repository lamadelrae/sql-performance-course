USE DemoSQLPerf;
GO

-- 2.1 Ativa estatísticas de IO e tempo
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- 2.2 Consulta simples para analisar
SELECT *
FROM Vendas
WHERE DataVenda > '2025-01-01';

-- 2.3 Desliga estatísticas
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
