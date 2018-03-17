-- Para verificar quais databases da sua instância estão com o Change Data Capture (CDC) ativo
SELECT [name], is_cdc_enabled FROM sys.databases

-- Para verificar quais tabelas de um determinado database estão com o recurso de CDC ativo
SELECT [name], is_tracked_by_cdc FROM sys.tables

-- O controle do Change Data Capture (CDC) é feito a nível de database. Para ativar o CDC, você irá utilizar a Stored Procedure de sistema sys.sp_cdc_enable_db.
USE BD_Aula
GO
EXEC sys.sp_cdc_enable_db 
GO

-- IMPORTANTE --
-- Ele cria um Esquema chamado CDC (Segurança\Esquemas)
-- Cria também algumas tabelas de sistemas (Tabelas\Tabelas do Sistema)
-- Cria 2 JOBS por Banco de Dados habilitado (ao fazer por Tabela)

CREATE TABLE TbTeste (
    cd smallint
  , nm varchar(10)
);

ALTER TABLE TbTeste     
  add xx varchar(10)

ALTER TABLE TbTeste     
  drop column xx

-- As tabelas criadas pelo CDC são:
-- cdc.captured_columns: Essa tabela de sistema vai listar todas as colunas das tabelas que estão com o CDC ativado. 
--Essas informações também podem ser consultadas utilizando a SP de sistema sys.sp_cdc_get_source_columns.

SELECT * FROM cdc.captured_columns

-- cdc.change_tables: Essa tabela de sistema vai listar todas as tabelas que estão com o CDC ativado. 
--Essas informações também podem ser consultadas utilizando a SP de sistema sys.sp_cdc_help_change_data_capture.
SELECT * FROM [cdc].[change_tables]

-- cdc.ddl_history: Essa tabela de sistema vai armazenar todas as alterações de DDL realizadas nas tabelas que estão 
--com o CDC ativado. Essas informações também podem ser consultadas utilizando a SP de sistema sys.sp_cdc_get_ddl_history.
SELECT * FROM [cdc].[ddl_history]

----------------
-- POR TABELA --
----------------

-- Para iniciar o monitoramento de tabelas e começar a armazenar o histórico de alterações de dados (DML) e estrutura (DDL), 
--você precisará utilizar a SP de sistema sys.sp_cdc_enable_table.

USE BD_Aula
GO 

EXEC sys.sp_cdc_enable_table 
@source_schema = N'dbo', 
@source_name   = N'TbTeste', 
@role_name     = NULL 
GO

-- Verificar (1 - delete / 2 - Insert / 3 - valor anterior / 4 - valor atualizado)
SELECT * FROM [cdc].[dbo_TbTeste_CT]

-- Testar
INSERT INTO TbTeste VALUES (1, 'teste 1')
INSERT INTO TbTeste VALUES (2, 'teste 2')
INSERT INTO TbTeste VALUES (3, 'teste 3')

UPDATE TbTeste
SET nm = 'Teste 01'
WHERE cd = 1

INSERT INTO TbTeste VALUES (4, 'teste 4')

DELETE TbTeste WHERE cd = 4 

---- Desabilitar CDC
--USE BD_Aula
--EXEC sys.sp_cdc_disable_db
--GO

---- Desabilitar por Tabela
---- Identificando o nome da instância de captura do CDC:
--EXEC sys.sp_cdc_help_change_data_capture
--GO
--SELECT OBJECT_NAME([object_id]), OBJECT_NAME(source_object_id), capture_instance FROM cdc.change_tables

---- Uma vez que identificamos o nome da instância (dbo_Clientes), agora podemos executar a sys.sp_cdc_disable_table 
----para efetivamente desativar o CDC nesta tabela:

--EXEC sys.sp_cdc_disable_table
--    @source_schema = 'dbo', -- sysname
--    @source_name = 'TbTeste', -- sysname
--    @capture_instance = 'dbo_TbTeste' -- sysname