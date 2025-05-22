USE DemoSQLPerf;
GO

-- 5.1 Enable partitioning with a function
CREATE PARTITION FUNCTION PF_Vendas_Data (DATE)
AS RANGE RIGHT FOR VALUES
    ('2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01');
GO

-- 5.2 Create a partition scheme using the function
CREATE PARTITION SCHEME PS_Vendas_Data
AS PARTITION PF_Vendas_Data
ALL TO ([PRIMARY]);
GO

-- 5.3 Create partitioned table with composite primary key
CREATE TABLE Vendas_Part (
    VendaID      INT IDENTITY,
    ClienteID    INT,
    Valor        DECIMAL(10,2),
    DataVenda    DATE,
    CONSTRAINT PK_Vendas_Part PRIMARY KEY (VendaID, DataVenda)
) ON PS_Vendas_Data(DataVenda);
GO

-- 5.4 Move data into the partitioned table
INSERT INTO Vendas_Part (ClienteID, Valor, DataVenda)
SELECT ClienteID, Valor, DataVenda
FROM Vendas;
GO

-- 5.5 Querying the partitioned table (optional performance optimization)
SELECT *
FROM Vendas_Part
WHERE DataVenda BETWEEN '2024-07-01' AND '2024-12-31';
GO
