-- Criando um banco de dados (configurações padrão)
CREATE DATABASE [BD_Aula]

-- Criando e Alimentando a Tabela de Teste
Create table TabelaDeTeste (
   id     int identity(1,1),
   campoA varchar(20), 
   campoB int,
   campoC datetime,
   campoD decimal(18,8)
) -- DROP TABLE TabelaDeTeste

-- Alimentando a Tabela de Teste
declare @i int
set @i = 1
while (@i <= 2000000) -- Inserindo 2 milhões de registros 
   begin
		insert into TabelaDeTeste values ('teste: '+ convert(varchar, @i*3), @i*5,getdate(), RAND())
		set @i = @i +1
   end

-- verificando a tabela de teste
select * from TabelaDeTeste

-----------------------------------------------------
-- Criando e Alimentando a Tabela de Relação
Create table TabelaDeRelacao (
   id     int identity(1,3),
   campoA varchar(20),
) -- DROP TABLE TabelaDeRelacao

-- Alimentando a Tabela de Relacao
declare @j int
set @j = 1
while (@j <= 300000) -- Inserindo 300 mil registros 
   begin
		insert into TabelaDeRelacao values ('Relacao: '+ convert(varchar, @j*2))
		set @j = @j +1
   end

-- verificando a tabela de relação
select * from TabelaDeRelacao

-- relacionando as 2 tabelas criadas
select A.campoA
     , R.campoA
	 , A.campoD
  from TabelaDeTeste   A
  join TabelaDeRelacao R ON R.id = A.id