-------------------------------------------------
-- CRIA BANCO PARA TESTES DE BACKUP E RECOVERY --
-------------------------------------------------
USE master
IF EXISTS (SELECT NULL FROM SYS.DATABASES WHERE NAME = 'SQLSERVER_RS_RECOVERY')
           DROP DATABASE SQLSERVER_RS_RECOVERY
CREATE DATABASE SQLSERVER_RS_RECOVERY

-- Visualizar Modelo de Recuperação
SELECT NAME, RECOVERY_MODEL_DESC
  FROM SYS.DATABASES
 WHERE NAME LIKE '%SQLSERVER_RS_RECOVERY%'

--ALTERAR MODELO DE RECUPERAÇÃO DE UMA BASE
--ALTER DATABASE SQLSERVER_RS_RECOVERY SET RECOVERY SIMPLE
--ALTER DATABASE SQLSERVER_RS_RECOVERY SET RECOVERY FULL
--ALTER DATABASE SQLSERVER_RS_RECOVERY SET RECOVERY BULK_LOGGED

-- Criando uma tabela para testes
USE SQLSERVER_RS_RECOVERY;

CREATE TABLE Info (
   id    smallint identity(1,1),
   nm    varchar(100),
   dt    smalldatetime not null
); -- DROP TABLE Info

-- Populando a tabela para testes
INSERT INTO Info VALUES ('Teste A', getdate())
INSERT INTO Info VALUES ('Teste B', getdate())
INSERT INTO Info VALUES ('Teste C', getdate())
INSERT INTO Info VALUES ('Teste D', getdate())
INSERT INTO Info VALUES ('Teste F', getdate())
INSERT INTO Info VALUES ('Teste E', getdate())
INSERT INTO Info VALUES ('Teste G', getdate())
INSERT INTO Info VALUES ('Teste H', getdate())
INSERT INTO Info VALUES ('Teste I', getdate())
INSERT INTO Info VALUES ('Teste J', getdate())
INSERT INTO Info VALUES ('Teste L', getdate())

-- Depois do backup full
INSERT INTO Info VALUES ('Teste M', getdate())
INSERT INTO Info VALUES ('Teste N', getdate())
INSERT INTO Info VALUES ('Teste O', getdate())
INSERT INTO Info VALUES ('Teste P', getdate())
INSERT INTO Info VALUES ('Teste Q', getdate())

-- Depois do backup diferencial
INSERT INTO Info VALUES ('Teste X', getdate())
INSERT INTO Info VALUES ('Teste S', getdate())
INSERT INTO Info VALUES ('Teste T', getdate())
INSERT INTO Info VALUES ('Teste U', getdate())
INSERT INTO Info VALUES ('Teste V', getdate())
INSERT INTO Info VALUES ('Teste Z', getdate())

-- Visualizar
SELECT * FROM SQLSERVER_RS_RECOVERY..Info

-------------
-- BACKUPS --
-------------
-- FULL
BACKUP DATABASE SQLSERVER_RS_RECOVERY TO DISK = 'C:\TEMP\SQL\backupFULL.dat'

-- Comprimido e com Cópia (Mirror)
BACKUP DATABASE SQLSERVER_RS_RECOVERY TO DISK = 'C:\TEMP\SQL\backupFULL_Compress.dat' 
MIRROR TO DISK = 'C:\TEMP\SQL\Copia\backupFULL_Copia.dat' WITH FORMAT, COMPRESSION , STATS = 10

-- DIFFERENTIAL
BACKUP DATABASE SQLSERVER_RS_RECOVERY TO DISK = 'C:\TEMP\SQL\backupDIFF.dat' WITH DIFFERENTIAL, COMPRESSION

-- T-LOG
BACKUP LOG SQLSERVER_RS_RECOVERY TO DISK = 'C:\TEMP\SQL\backupLOG.dat' WITH COMPRESSION, STATS = 10 -- Porcentagem concluída

--------------------------------------------------
-- VERIFICAR INTEGRIDADE DO BACKUP (IMPORTANTE) --
--------------------------------------------------
RESTORE VERIFYONLY FROM DISK = 'C:\TEMP\SQL\backupFULL_Compress.dat'

-------------------------------
-- Informações sobre backups --
------------------------------- 
SELECT backup_set_id
	   ,database_name
	   ,user_name
	   ,backup_start_date
	   ,backup_finish_date
	   ,CASE type
			WHEN 'D' THEN 'Full'
			WHEN 'L' THEN 'Log'
			WHEN 'I' THEN 'Differential'
		END AS 'Backup type'
	   ,compatibility_Level
	   ,CAST(backup_size / 1024 as INT) AS 'Backup Size(KB)'
	   ,CAST(compressed_backup_size / 1024 as INT) AS  'Compressed(KB)'
	   ,server_name
	   ,recovery_model
  FROM MSDB..backupset
  ORDER BY backup_finish_date DESC

-------------
-- RESTORE --
-------------
USE master
-- FULL
RESTORE DATABASE SQLSERVER_RS_RECOVERY FROM DISK = 'C:\TEMP\SQL\backupFULL_Compress.dat'
WITH REPLACE
,	 NORECOVERY -- Deixa aberto para recuperar um proximo backup
,	 STATS=10

-- DIFERENCIAL
RESTORE DATABASE SQLSERVER_RS_RECOVERY FROM  DISK = 'C:\TEMP\SQL\backupDIFF.dat' WITH NORECOVERY,	 STATS = 10 

-- LOG
RESTORE LOG SQLSERVER_RS_RECOVERY FROM  DISK = 'C:\TEMP\SQL\backupLOG.dat' WITH RECOVERY

-- Visualizando
SELECT * FROM SQLSERVER_RS_RECOVERY..Info

---------------------------------------------
-- RESTORE LOG (Recuperação Point-in-Time) --
---------------------------------------------
RESTORE DATABASE SQLSERVER_RS_RECOVERY FROM DISK = 'C:\TEMP\SQL\backupFULL_Compress.dat'
WITH REPLACE, NORECOVERY -- Deixa aberto para recuperar um proximo backup
,	 STATS=10

-- DIFERENCIAL
RESTORE DATABASE SQLSERVER_RS_RECOVERY FROM  DISK = 'C:\TEMP\SQL\backupDIFF.dat' WITH NORECOVERY, STATS = 10 

-- LOG (Recuperação Point-in-Time)
RESTORE LOG SQLSERVER_RS_RECOVERY FROM  DISK = 'C:\TEMP\SQL\backupLOG.dat' WITH NORECOVERY,  STOPAT = '20180308 16:46:50' 

RESTORE DATABASE SQLSERVER_RS_RECOVERY WITH RECOVERY; 

-- Visualizando
SELECT * FROM SQLSERVER_RS_RECOVERY..Info

-------------------------------
-- Informações sobre RESTORE --
-------------------------------
SELECT * FROM MSDB..restorefile
SELECT * FROM MSDB..restorehistory

--------------------------------------------
-- RESTAURANDO BACKUP COM ERROS - RESTORE --
--------------------------------------------
USE master;
-- Checando o backup...
BACKUP DATABASE SQLSERVER_RS_RECOVERY TO DISK = 'C:\Temp\SQL\Corrompido.bak'
WITH CHECKSUM;

-- Checando o backup, mas deixando continuar...
BACKUP DATABASE SQLSERVER_RS_RECOVERY TO DISK = 'C:\Temp\SQL\CorrompidoErros.bak'
WITH CHECKSUM, CONTINUE_AFTER_ERROR;

--Restaurando um backup, ignorando os erros 
RESTORE DATABASE SQLSERVER_RS_RECOVERY FROM DISK = 'C:\Temp\SQL\CorrompidoErros.bak'
WITH	CONTINUE_AFTER_ERROR,		REPLACE;

-------------------------------------
-- OBSERVAÇÕES IMPORTANTES e DICAS --
-------------------------------------
-----------------------------------
-- Verificar páginas corrompidas --
-----------------------------------
-- SELECT * FROM MSDB..suspect_pages

----------------------------
-- Modelos de recuperação --
----------------------------
 /*	BULK_LOGGED: 
		* Aumenta consideravelmente o tamanho dos backups de log, pois carrega todos os extents continentes das páginas
		* Não permite restore point in time.

	FULL:
		* Exige a realização de backups de logs periódicos, para controle de tamanho do Log de Transações (.ldf)

	SIMPLE:
		* Mais facilidade de Administração, porém sem muitas possibilidades de Restore, pois permite restauração somente até  
		   final do backup full */

-------------------------------------------------
-- RESTAURANDO a Base de Dados MASTER e a MSDB --
-------------------------------------------------
-- ****** 
-- MASTER
-- ******
-- 1. Passo - Entrar no Prompt de Comando

-- 2. Passo - Parar o Serviço do SQL Server (1. Prompt de Comando)
-- C:\> NET STOP MSSQLSERVER

-- 3. Restartar o SQL Server com Single Mode (2. Prompt de Comando)
-- C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Binn> SQLSERVR.EXE -m

-- 4. Entra no SQLCMD (3. Prompt de Comando)
-- C:\> SQLCMD -SLOCALHOST -E

-- 5. Restaurar o backup do Banco de Dados Master
-- 1> RESTORE DATABASE MASTER FROM DISK = 'C:\BACKUP_MASTER.BAK' WITH REPLACE
-- 2> GO

-- 6. Restartar o SQL Server (Normal - 1. Prompt de Comando)
-- C:\> NET START MSSQLSERVER
 
-- ****
-- MSDB
-- ****
-- 1. No SQL Server Management Studio, com o serviço do SQL Server Agent Parado
-- RESTORE DATABASE MSDB FROM DISK = 'C:\BACKUP_MSDB.BAK' 


/*******************************
 * Desenvolvido por Alex Souza *
 *******************************/