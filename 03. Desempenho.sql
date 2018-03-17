------------------------------------
-- Informações do SQL Server e SO --
------------------------------------

SELECT top 1 
       SERVERPROPERTY ('MachineName') AS [Server Name]
     , @@VERSION AS [SQL Server and OS Version Info]
     , SERVERPROPERTY('Edition') AS [Edition]
     , SERVERPROPERTY('ProductLevel') AS [ProductLevel]
     , SERVERPROPERTY('ProductVersion') AS [ProductVersion]
     , SERVERPROPERTY('ProcessID') AS [ProcessID]
     , create_date AS [SQL Server Install Date]
FROM sys.server_principals WITH (NOLOCK)
order by create_date desc 

-- Máquina
EXEC xp_readerrorlog 0, 1, N'Manufacturer'

-- Processador
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\CentralProcessor\0', N'ProcessorNameString';

-- Parte Física (Servidor)
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count],
sqlserver_start_time, affinity_type_desc
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);  

----------------------------
-- Processos em execução  --
----------------------------
Select 	proces.spid
,		proces.ecid
,		proces.blocked
,		proces.status
,		bases.name as 'Banco'
,		proces.hostname as 'Host'
,		proces.loginame as 'Login'
,		proces.program_name as 'Aplicação'
,		proces.hostprocess
,		proces.cmd as 'Comando'
,		st.[text] as 'Query rodando' -- (*)
,		proces.lastwaittype
,		proces.nt_domain as 'Dominio'
,		proces.nt_username as 'Usuário'
,		proces.request_id
,		proces.cpu as 'Tempo CPU'
,		proces.waittime as 'Tempo Espera'
,		proces.physical_io 'Disco Entrada/Saida'
,		proces.login_time as 'Hora do Login'
,		proces.last_batch
,		proces.net_address
,		proces.net_library as 'Protocolo'
,		proces.open_tran as 'Transações em Aberto'
From		sys.sysprocesses proces
left join	sys.databases bases	on bases.database_id = proces. dbid
cross apply sys.dm_exec_sql_text(proces.sql_handle) as st -- Ver o que esta rodando (*)

-- ##################################################################
-- # Retorna a Média das 10 Query's que mais consumiram tempo de CPU #
-- ##################################################################

Select Top 10
		total_worker_time / execution_count as [Avg CPU Time]
,		Substring (st.text, (qs.statement_start_offset / 2) + 1,
		((Case statement_end_offset
			when -1 then datalength(st.text)
			else qs.statement_end_offset 
			end	-qs.statement_start_offset)/2) + 1) as Query		
From	sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
Order by
		total_worker_time / execution_count desc

-- ###################################################
-- # Retorna as 5 Querys com maior tempo de execução #
-- ###################################################

Select  Top 5
		creation_time
,		last_execution_time
,		total_clr_time
,		total_clr_time / execution_count as [Avg CLR Time]
,		last_clr_time
,		execution_count
,		Substring (st.text, (qs.statement_start_offset / 2) + 1,
		((Case statement_end_offset
			when -1 then datalength(st.text)
			else qs.statement_end_offset 
			end -qs.statement_start_offset)/2) + 1) as Query
From	sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
Order by
		total_clr_time / execution_count desc

-- Dados 
SELECT [>] = 'DADOS';
SELECT DISTINCT vs.volume_mount_point, vs.file_system_type, 
vs.logical_volume_name, CONVERT(DECIMAL(18,2),vs.total_bytes/1073741824.0) AS [Total Size (GB)],
CONVERT(DECIMAL(18,2),vs.available_bytes/1073741824.0) AS [Available Size (GB)],  
CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %] 
FROM sys.master_files AS f WITH (NOLOCK)
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs OPTION (RECOMPILE);

-- CPU
SELECT [>] = 'CPU';

-- Get CPU utilization by database (Query 24) (CPU Usage by Database)
WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [Database Name], SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Rank],
       [Database Name], [CPU_Time_Ms] AS [CPU Time (ms)], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
FROM DB_CPU_Stats
WHERE DatabaseID <> 32767 -- ResourceDB
ORDER BY [CPU Rank] OPTION (RECOMPILE);

-- Get CPU Utilization History for last 256 minutes (in one minute intervals)  (Query 32) (CPU Utilization History)
-- This version works with SQL Server 2008 R2
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 

SELECT TOP(100) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
	  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
			'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM ( 
			SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);

-- IO
SELECT [>] = 'IO';
-- Get I/O utilization by database (Query 25) (IO Usage By Database)
WITH Aggregate_IO_Statistics
AS
(SELECT DB_NAME(database_id) AS [Database Name],
CAST(SUM(num_of_bytes_read + num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS io_in_mb
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
GROUP BY database_id)
SELECT ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS [I/O Rank], [Database Name], io_in_mb AS [Total I/O (MB)],
       CAST(io_in_mb/ SUM(io_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O Percent]
FROM Aggregate_IO_Statistics
ORDER BY [I/O Rank] OPTION (RECOMPILE);

-- Memória
SELECT [>] = 'MEMÓRIA';
-- Good basic information about OS memory amounts and state  (Query 34) (System Memory)
SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       available_physical_memory_kb/1024 AS [Available Memory (MB)], 
       total_page_file_kb/1024 AS [Total Page File (MB)], 
	   available_page_file_kb/1024 AS [Available Page File (MB)], 
	   system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

-- Get a count of SQL connections by IP address (Query 30) (Connection Counts by IP Address)
SELECT ec.client_net_address, es.[program_name], es.[host_name], es.login_name, 
COUNT(ec.session_id) AS [connection count] 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 
GROUP BY ec.client_net_address, es.[program_name], es.[host_name], es.login_name  
ORDER BY ec.client_net_address, es.[program_name] OPTION (RECOMPILE);

-- ESPAÇO
SELECT [>] = 'ESPAÇO por tabela';
use BD_Aula
exec sp_spaceused 'TabelaDeTeste', @updateusage = N'TRUE';