USE DemoSQLPerf;
GO

-- 3.1 Criação de índices
CREATE INDEX IX_Vendas_DataVenda
ON Vendas(DataVenda);

CREATE INDEX IX_Vendas_ClienteID
ON Vendas(ClienteID);

-- 3.2 Forçar atualização de estatísticas
UPDATE STATISTICS Vendas;
ANALYZE TABLE Vendas;  -- em versões mais recentes
GO

-- 3.3 Teste de performance pós-índice
SET STATISTICS IO ON;
SELECT *
FROM Vendas
WHERE DataVenda > '2025-01-01';
SET STATISTICS IO OFF;
GO
