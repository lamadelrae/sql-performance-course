USE DemoSQLPerf;
GO

-- 5.1 Habilita particionamento
CREATE PARTITION FUNCTION PF_Vendas_Data (DATE)
AS RANGE RIGHT FOR VALUES
    ('2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01');

CREATE PARTITION SCHEME PS_Vendas_Data
AS PARTITION PF_Vendas_Data
ALL TO ([PRIMARY]);

-- 5.2 Cria tabela particionada
CREATE TABLE Vendas_Part (
    VendaID      INT IDENTITY PRIMARY KEY,
    ClienteID    INT,
    Valor        DECIMAL(10,2),
    DataVenda    DATE
) ON PS_Vendas_Data(DataVenda);

-- 5.3 Move dados para tabela particionada
INSERT INTO Vendas_Part (ClienteID, Valor, DataVenda)
SELECT ClienteID, Valor, DataVenda
FROM Vendas;

-- 5.4 Query em partições
SELECT *
FROM Vendas_Part
WHERE DataVenda BETWEEN '2024-07-01' AND '2024-12-31';
GO
