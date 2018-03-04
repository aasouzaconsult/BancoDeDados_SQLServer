-- SEGURANÇA
SELECT [>] = 'SEGURANÇA'
--  Get logins that are connected and how many sessions they have (Query 29) (Connection Counts)
SELECT login_name, [program_name], COUNT(session_id) AS [session_count] 
FROM sys.dm_exec_sessions WITH (NOLOCK)
GROUP BY login_name, [program_name]
ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);

--Listar quais permissões cada usuário tem
--dentro do database
SELECT dp.NAME AS principal_name,
	   dp.type_desc AS principal_type_desc,
	   o.NAME AS [object_name],
	   p.permission_name,
	   p.state_desc AS permission_state_desc
 FROM      sys.database_permissions p
 LEFT JOIN sys.all_objects          o ON p.major_id             = o.[OBJECT_ID]
INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id

--Qual a database role?
SELECT USR.name AS [User_Name], 
	   USR1.name AS Database_Role
  FROM       SYS.database_role_members DR
  INNER JOIN sys.sysusers USR  ON DR.member_principal_id = USR.uid
  INNER JOIN sys.sysusers USR1 ON USR1.uid               = DR.role_principal_id