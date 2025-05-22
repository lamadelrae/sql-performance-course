PRINT '--- Sem índice ---';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
    SELECT Valor
    FROM Vendas
    WHERE DataVenda > '2025-01-01';
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

	-- Create an index optimized for this query
CREATE NONCLUSTERED INDEX IX_Vendas_DataVenda_Valor
ON Vendas(DataVenda)
INCLUDE (Valor);

GO
	-- Update stats to ensure optimizer has accurate data
UPDATE STATISTICS Vendas;
GO
	-- Run query with index
PRINT '--- Com índice ---';
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
    SELECT Valor
    FROM Vendas
    WHERE DataVenda > '2025-01-01';
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO