-------------------------------------------------
-- Quantidade de Indices e Colunas por Tabela  --
-------------------------------------------------
Select	Tabela = o.name
,		[Qtd de Indices] = Count(o.name)
,		[Qtd de Colunas] = (Select count(*) From sys.columns Where object_id = o.object_id)
From	sys.indexes i
join	sys.objects o on o.object_id = i.object_id and o.type = 'U'
Group by
		o.name
,		o.object_id
Order by
		Count(o.name) desc

---------------------------------
-- FRAGMENTAÇÃO DOS ÍNDICES --
---------------------------------
--http://msdn.microsoft.com/pt-br/library/ms188917.aspx

--DROP TABLE AnaliseInstancia..Indices

SELECT	TipoIndice = dt.index_type_desc
,		TipoAlocacao = dt.alloc_unit_type_desc 
,		[FillFactor] = si.fill_factor
,		Tabela = OBJECT_NAME(dt.object_id)
,		Indice = si.name
,		Fragmentacao = dt.avg_fragmentation_in_percent
,		Comando = case	when dt.avg_fragmentation_in_percent < 30.0 
							then 'ALTER INDEX ' + si.name + ' ON ' + OBJECT_NAME(dt.object_id) + ' REORGANIZE;'
						when dt.avg_fragmentation_in_percent >= 30.0
							then 'ALTER INDEX ' + si.name + ' ON ' + OBJECT_NAME(dt.object_id) + ' REBUILD;'
				  Else 'Teste' End
--Into	AnaliseInstancia..Indices
FROM	sys.dm_db_index_physical_stats (DB_ID(N'FPW')
, NULL, NULL, NULL, 'DETAILED') dt
JOIN	sys.indexes si ON si.object_id = dt.object_ID AND si.index_id = dt.index_id
WHERE	dt.index_id <> 0
and		dt.avg_fragmentation_in_percent > 10.0
Order	by
		dt.avg_fragmentation_in_percent desc

--------------------------------------------------------------
Select	Comando = 'ALTER INDEX ALL ON ' + Tabela + ' REBUILD;'
,		[%] = Max(Fragmentacao)
From	AnaliseInstancia..Indices
Where	Fragmentacao >= 30
Group by
		Tabela
Order by
		Max(Fragmentacao) desc

-- Detalhes sobre Indices
Declare @Tabela varchar(100)
Set		@Tabela = 'TbRcd'

Select	'DBCC SHOWCONTIG (''' + obj.name + ''',''' + idx.name + ''');'
From	sys.indexes idx
join	sys.objects obj on obj.object_id = idx.object_id
Where	obj.name = @Tabela

Select	'ALTER INDEX ' + idx.name + ' ON ' + obj.name + ' REBUILD;'
From	sys.indexes idx
join	sys.objects obj on obj.object_id = idx.object_id
Where	obj.name = @Tabela

------------------------------------------------
-- Monta as Querys para a criação dos Índices --
------------------------------------------------

DECLARE @MIN_INDEX_ADVANTAGE AS INT
DECLARE @Advantage AS NUMERIC(20,3)
DECLARE @ID AS INT
DECLARE @TableStatement AS VARCHAR(80)
DECLARE @Equality AS VARCHAR(1000)
DECLARE @Inequality AS VARCHAR(1000)
DECLARE @Included AS VARCHAR (8000)
DECLARE @Handler AS INT

SET		@MIN_INDEX_ADVANTAGE = 0

DECLARE MissingIndexes CURSOR FOR
SELECT index_advantage AS Advantage, mid.object_id AS ID, mid.Statement AS TableStatement, mid.Equality_columns AS Equality, mid.inequality_columns AS Inequality, included_columns AS Included, mig.index_handle AS Handler 
FROM(
	SELECT (user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, migs.* 
		FROM sys.dm_db_missing_index_group_stats migs 
	) AS migs_adv, 
   sys.dm_db_missing_index_groups mig, 
   sys.dm_db_missing_index_details mid 
WHERE 
   migs_adv.group_handle = mig.index_group_handle and 
   mig.index_handle = mid.index_handle and
   index_advantage > @MIN_INDEX_ADVANTAGE
   --and	mid.Statement = '[TopManager].[dbo].[TbRcd]'
ORDER BY migs_adv.index_advantage DESC 

OPEN MissingIndexes
FETCH NEXT FROM MissingIndexes 
INTO @Advantage, @ID, @TableStatement, @Equality, @Inequality, @Included, @Handler

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @Columns AS Varchar(2000)
	SET @Columns = ''

	IF @Equality IS NOT NULL SET @Columns = @Columns + @Equality
	IF @Inequality IS NOT NULL AND @Equality IS NOT NULL SET @Columns = @Columns + ', ' + @Inequality
	IF @Inequality IS NOT NULL AND @Equality IS NULL SET @Columns = @Inequality

	IF @Included IS NULL
		print('/* ' + CONVERT(VARCHAR(14), @Advantage) + '% */ CREATE INDEX I_REGINA_' + convert(varchar(8), @Handler)) + ' ON ' + @TableStatement + ' (' + @Columns + ')'
	ELSE
		print('/* ' + CONVERT(VARCHAR(14), @Advantage) + '% */ CREATE INDEX I_REGINA_' + convert(varchar(8), @Handler)) + ' ON ' + @TableStatement + ' (' + @Columns + ') INCLUDE (' + @Included + ')'

	FETCH NEXT FROM MissingIndexes 
	INTO @Advantage, @ID, @TableStatement, @Equality, @Inequality, @Included, @Handler
END

CLOSE MissingIndexes
DEALLOCATE MissingIndexes

-------------------------------------------------
-- Indexes_Mostra os indices que estao criados --
-------------------------------------------------

DECLARE @table_object_id AS int
DECLARE @index_id AS int
DECLARE @index_name AS varchar(60)
DECLARE @table_name AS varchar(30)
DECLARE @clause AS varchar(30)
DECLARE @column_id AS int
DECLARE @is_included_column AS bit
DECLARE @TABLE_TO_SEARCH AS Varchar(30)
SET @TABLE_TO_SEARCH = ''

IF @TABLE_TO_SEARCH = '' SET @TABLE_TO_SEARCH = '%%'
DECLARE indexes CURSOR FOR 
	SELECT		sys.indexes.object_id, sys.indexes.name, index_id 
	FROM		sys.indexes 
	INNER JOIN	sys.objects on sys.objects.object_id = sys.indexes.object_id
	WHERE		sys.indexes.Object_id > 100 and sys.objects.name like @TABLE_TO_SEARCH

OPEN indexes
FETCH NEXT FROM indexes 
INTO @table_object_id, @index_name, @index_id

WHILE @@FETCH_STATUS = 0
BEGIN
      SELECT @table_name = name FROM sys.objects 
            WHERE object_id = @table_object_id
      DECLARE index_columns CURSOR FOR
            SELECT column_id, is_included_column FROM sys.index_columns 
            WHERE sys.index_columns.object_id= @table_object_id
                  AND sys.index_columns.index_id = @index_id
            ORDER BY index_column_id
      print '---------------'
      print 'Nome da tabela: ' + @table_name
      print 'Nome do índice: ' + @index_name
      print 'ID do índice: ' + convert(varchar(3),@index_id)
      print 'Colunas do índice: ' 
      OPEN index_columns

      FETCH NEXT FROM index_columns 

      INTO @column_id, @is_included_column

            WHILE @@FETCH_STATUS = 0
            BEGIN
                  DECLARE @column_name AS varchar(30)
                  SELECT @column_name = name FROM sys.columns 
                        WHERE object_id = @table_object_id
                        AND column_id = @column_id
                  IF @is_included_column = 0 print @column_name
                  ELSE print '(included)' +@column_name 
                  FETCH NEXT FROM index_columns 
                  INTO @column_id, @is_included_column
            END;
      CLOSE index_columns

      DEALLOCATE index_columns
      FETCH NEXT FROM indexes 
      INTO @table_object_id, @index_name, @index_id
END

CLOSE indexes
DEALLOCATE indexes

-----------------------------------
-- Verificar ÍNDICES Especificos --
-----------------------------------

SELECT	DB_NAME(database_id) As Banco
,		OBJECT_NAME(I.object_id) As Tabela
,		I.Name As Indice
,		U.User_Seeks As Pesquisas
,		U.User_Scans As Varreduras
,		U.User_Lookups As LookUps
,		U.User_Updates As Updates
,		U.Last_User_Seek As UltimaPesquisa
,		U.Last_User_Scan As UltimaVarredura
,		U.Last_User_LookUp As UltimoLookUp
,		U.Last_User_Update As UltimaAtualizacao
FROM	sys.indexes As I
LEFT OUTER JOIN sys.dm_db_index_usage_stats As U ON I.object_id = U.object_id 
	AND I.index_id = U.index_id
WHERE	DB_NAME(database_id) = 'banco'
and     I.Name like '%nome%'
Order by U.User_Seeks

----------------------------
-- ÍNDICES NÃO UTILIZADOS --
----------------------------

/* Parte(A) identifica índices sem entrada na DMV 'dm_db_index_usage_stats', isto indica que o índice nunca foi utilizado desde a inicialização do SQL Server */
SELECT DB_NAME(), OBJECT_NAME(i.object_id) AS 'Table', ISNULL(i.name, 'heap') AS 'Index', x.used_page_count AS 'SizeKB'
FROM sys.objects o
INNER JOIN sys.indexes i
ON i.[object_id] = o.[object_id]
LEFT JOIN sys.dm_db_index_usage_stats s
ON i.index_id = s.index_id and s.object_id = i.object_id
LEFT JOIN sys.dm_db_partition_stats x
ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
WHERE OBJECT_NAME(o.object_id) IS NOT NULL AND OBJECT_NAME(s.object_id) IS NULL
AND o.[type] = 'U' AND ISNULL(i.name, 'heap') <> 'heap'

UNION ALL

/* Parte(B) identifica índices que não são mais utilizados desde a inicialização da instância do SQL Server */
SELECT DB_NAME(), OBJECT_NAME(i.object_id) AS 'Table', ISNULL(i.name, 'heap') AS 'Index', x.used_page_count AS 'SizeKB'
FROM sys.objects o
INNER JOIN sys.indexes i
ON i.[object_id] = o.[object_id]
LEFT JOIN sys.dm_db_index_usage_stats s
ON i.index_id = s.index_id and s.object_id = i.object_id
LEFT JOIN sys.dm_db_partition_stats x
ON i.[object_id] = x.[object_id] AND i.index_id = x.index_id
WHERE user_seeks = 0 AND user_scans = 0 AND user_lookups = 0
AND o.[type] = 'U' AND ISNULL(i.name, 'heap') <> 'heap'
ORDER BY 2 ASC

-----------------------------------------------
-- Mostra Tabelas sem indices do BD corrente --
-----------------------------------------------

Select 
			object_name(i.id) 
From		sysindexes i
inner join	sysobjects o ON i.id = o.id
Where		indid = 0 
AND			xtype = 'U'

----------------------------------------
-- Tabelas dependentes (relacionadas) --
----------------------------------------

SELECT distinct
   Comando = 'ALTER INDEX ALL ON ' + OBJECT_NAME(Referenced_Object_ID) + ' REBUILD;'
,  Comando2 = 'UPDATE STATISTICS [dbo].' + OBJECT_NAME(Referenced_Object_ID)
FROM SYS.FOREIGN_KEYS
WHERE Parent_Object_ID = OBJECT_ID('TbFat')