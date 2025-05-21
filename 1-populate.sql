-- 1.1 Cria base de exemplo e tabelas
CREATE DATABASE DemoSQLPerf;
GO
USE DemoSQLPerf;
GO

CREATE TABLE Vendas (
    VendaID      INT IDENTITY PRIMARY KEY,
    ClienteID    INT,
    Valor        DECIMAL(10,2),
    DataVenda    DATE
);

CREATE TABLE Clientes (
    ClienteID INT IDENTITY PRIMARY KEY,
    Nome      VARCHAR(100),
    Email     VARCHAR(100)
);

-- 1.2 Popula com dados de teste
INSERT INTO Clientes (Nome, Email)
SELECT
    'Cliente ' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR),
    'cliente' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR) + '@exemplo.com'
FROM sys.objects o1
CROSS JOIN sys.objects o2
WHERE o1.object_id <= 100;  -- 100 clientes

INSERT INTO Vendas (ClienteID, Valor, DataVenda)
SELECT
    ABS(CHECKSUM(NEWID())) % 100 + 1,  -- random ClienteID entre 1 e 100
    ROUND(RAND(CHECKSUM(NEWID())) * 1000, 2),  -- valor até 1000
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE())
FROM sys.objects o1
CROSS JOIN sys.objects o2
WHERE o1.object_id <= 1000;  -- ~10.000 vendas
GO
