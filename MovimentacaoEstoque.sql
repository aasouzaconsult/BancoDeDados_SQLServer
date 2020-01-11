-- A dica de hoje tem o objetivo de demonstrar e exemplificar como criar um processo de atualização automática de saldo em 
--estoque de um determinado produto, através da utilização de Triggers no SQL Server.

-- Criando a tabela de Produtos
Create Table NovosProdutos (
  Codigo Int Identity(1,1)
, Descricao VarChar(20)
, Saldo Int)

-- Populando…
Insert Into NovosProdutos Values('Produto – '+ Convert(VarChar(3),@@Identity), 0)
Go 100

-- Ver a tabela Novos Produtos
Select * From NovosProdutos

-- Criando tabela de Movimentações
Create Table Movimentacao(
Codigo Int Identity(1,1)
, CodProduto Int
, TipoMovimentacao Char(1)
, Valor Int)

-- Criando a Trigger de Movimentação (E- Entrada / S – Saída)
Create Trigger T_MovimentacaoSaldo On Movimentacao After Insert, Update As
Declare @TipoMovimentacao Char(1)
Select @TipoMovimentacao=TipoMovimentacao from Inserted

If @TipoMovimentacao = 'E'
Begin
  Update NovosProdutos
  Set Saldo = Saldo + I.Valor
  from NovosProdutos NP Inner Join Inserted I On NP.Codigo = I.CodProduto
End

If @TipoMovimentacao = 'S'
Begin
  Update NovosProdutos
  Set Saldo = Saldo - I.Valor
  from NovosProdutos NP Inner Join Inserted I On NP.Codigo = I.CodProduto
End

-- Fazendo lançamentos de entrada
Insert Into Movimentacao Values(2,'E',10)
Insert Into Movimentacao Values(2,'E',15)
Insert Into Movimentacao Values(2,'E',5)
Insert Into Movimentacao Values(2,'E',22)
Insert Into Movimentacao Values(2,'E',10)
Insert Into Movimentacao Values(1,'E',15)
Insert Into Movimentacao Values(8,'E',10)
Insert Into Movimentacao Values(9,'E',15)
Insert Into Movimentacao Values(1,'E',5)
Insert Into Movimentacao Values(3,'E',22)
Insert Into Movimentacao Values(22,'E',10)

-- Fazendo lançamentos de saída
Insert Into Movimentacao Values(2,'S',8)
Insert Into Movimentacao Values(2,'S',5)
Insert Into Movimentacao Values(2,'S',3)
Insert Into Movimentacao Values(2,'S',2)
Insert Into Movimentacao Values(2,'S',1)
Insert Into Movimentacao Values(8,'S',8)
Insert Into Movimentacao Values(8,'S',3)
Insert Into Movimentacao Values(9,'S',5)
Insert Into Movimentacao Values(1,'S',3)
Insert Into Movimentacao Values(3,'S',2)
Insert Into Movimentacao Values(22,'S',1)

-- Verificando o valor atual do saldo movimentado
select * from NovosProdutos -- Veja o Saldo aqui (Saldo)
select * from Movimentacao

-- Fonte
-- https://social.msdn.microsoft.com/Forums/sqlserver/pt-BR/a1844c8f-ace5-4bd4-80cb-8a73922c7d9c/triggers-atualizar-saldos-conta-correntes?forum=expresscompactpt
