USE DemoSQLPerf;
GO

-- 4.1 Evitar SELECT *
-- Antes: SELECT * FROM Clientes;
-- Depois:
SELECT ClienteID, Nome, Email
FROM Clientes;

-- 4.2 Subquery correlacionada vs JOIN
-- Subquery (lentidão em grandes volumes)
SELECT c.Nome
FROM Clientes c
WHERE c.ClienteID IN (
    SELECT v.ClienteID
    FROM Vendas v
    WHERE v.Valor > 500
);

-- Refatorada com JOIN
SELECT DISTINCT c.Nome
FROM Clientes c
JOIN Vendas v
  ON v.ClienteID = c.ClienteID
WHERE v.Valor > 500;

-- 4.3 Paginação com OFFSET/FETCH
SELECT ClienteID, Nome
FROM Clientes
ORDER BY ClienteID
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;
GO
