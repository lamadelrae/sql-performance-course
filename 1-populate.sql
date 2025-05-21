-- 1.1 Cria base de exemplo e tabelas
CREATE DATABASE DemoSqlPerf;

GO
    USE DemoSqlPerf;

GO
    CREATE TABLE Vendas (
        VendaId INT IDENTITY PRIMARY KEY,
        ClienteId INT,
        Valor DECIMAL(10, 2),
        DataVenda DATE
    );

CREATE TABLE Clientes (
    ClienteId INT IDENTITY PRIMARY KEY,
    Nome VARCHAR(100),
    Email VARCHAR(100)
);

-- 1.2 Popula com dados de teste
WITH ClienteCte AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                o1.object_id
        ) AS Rn,
        'Cliente ' + CAST(
            ROW_NUMBER() OVER (
                ORDER BY
                    (
                        SELECT
                            NULL
                    )
            ) AS VARCHAR
        ) AS Nome,
        'cliente' + CAST(
            ROW_NUMBER() OVER (
                ORDER BY
                    (
                        SELECT
                            NULL
                    )
            ) AS VARCHAR
        ) + '@exemplo.com' AS Email
    FROM
        sys.objects o1
        CROSS JOIN sys.objects o2
)
INSERT INTO
    Clientes (Nome, Email)
SELECT
    Nome,
    Email
FROM
    ClienteCte
WHERE
    Rn <= 100;

-- 100 clientes
WITH VendasCte AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                o1.object_id
        ) AS Rn,
        ABS(CHECKSUM(NEWID())) % 100 + 1 AS ClienteId,
        -- random ClienteId entre 1 e 100
        ROUND(RAND(CHECKSUM(NEWID())) * 1000, 2) AS Valor,
        -- valor até 1000
        DATEADD(DAY, - ABS(CHECKSUM(NEWID())) % 365, GETDATE()) AS DataVenda
    FROM
        sys.objects o1
        CROSS JOIN sys.objects o2
)
INSERT INTO
    Vendas (ClienteId, Valor, DataVenda)
SELECT
    ClienteId,
    Valor,
    DataVenda
FROM
    VendasCte
WHERE
    Rn <= 1000;

-- 10.000 vendas
GO