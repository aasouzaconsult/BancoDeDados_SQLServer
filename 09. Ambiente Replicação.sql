-- Criando tabela de Funcionarios
CREATE TABLE Funcionario (
  cd smallint
, nm varchar(60)
, dtAdmissao smalldatetime
, cddep smallint 
);

-- Criando tabela de Dependentes
CREATE TABLE Dependente (
  cddep smallint
, nmdep varchar(60)
);

-- Populando as tabelas
INSERT INTO Funcionario VALUES (1, 'Funcionario 1', getdate()-700, null),
                               (2, 'Funcionario 2', getdate()-600, null),
							   (3, 'Funcionario 3', getdate()-500, 1),
							   (4, 'Funcionario 4', getdate()-400, null),
							   (5, 'Funcionario 5', getdate()-100, 2)

INSERT INTO Dependente VALUES (1, 'Dependente 1'),
                              (2, 'Dependente 2')

-- Visualizando os dados replicados
SELECT * FROM Funcionario
SELECT * FROM Dependente

-- Relacionando
SELECT Fun.*
     , Dep.* 
  FROM      Funcionario Fun
  LEFT JOIN Dependente  Dep on Dep.cddep = Fun.cddep


--------------------
-- Na Instância 2 --
--------------------
CREATE DATABASE BD_AulaReplicado

-- Visualizando os dados replicados
SELECT * FROM Funcionario
SELECT * FROM Dependente

-- Relacionando
SELECT Fun.*
     , Dep.* 
  FROM      Funcionario Fun
  LEFT JOIN Dependente  Dep on Dep.cddep = Fun.cddep

--------------------
-- Na Instância 1 --
--------------------
INSERT INTO Funcionario VALUES (6, 'Funcionario 6', getdate()-300, null, NEWID()),
                               (7, 'Funcionario 7', getdate()-200, 4, NEWID())

INSERT INTO Dependente VALUES (4, 'Dependente 4', NEWID())
INSERT INTO Dependente VALUES (5, 'Dependente 5', NEWID())

--------------------
-- Na Instância 2 --
--------------------
-- Visualizando os dados replicados
SELECT * FROM Funcionario
SELECT * FROM Dependente

----------------------------------------------------------------------------------
-----------------
-- NOVOS DADOS --
-----------------
-- Instancia 1  (2016 - Developer)
SELECT * FROM Funcionario
SELECT * FROM Dependente

INSERT INTO Funcionario VALUES (8, 'Funcionario 6', getdate()-300, null, NEWID()),
                               (9, 'Funcionario 7', getdate()-200, 5, NEWID())

-- Instancia 2 (2014 - Express)
SELECT * FROM Funcionario
SELECT * FROM Dependente

INSERT INTO Dependente VALUES (6, 'Dependente 6', NEWID())