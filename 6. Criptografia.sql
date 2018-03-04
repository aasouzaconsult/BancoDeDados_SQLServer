-- TDE (Transparent Data Encryption)

-- Para compreender, na prática, como funciona a criptografia no SQL Server, vamos utilizar uma 
-- tabela que armazenará informações de login e senha de usuários. Para criar essa tabela, execute o script:
USE BD_Aula

CREATE TABLE Usuario
(
    ID INT IDENTITY,
    [LOGIN] VARCHAR(MAX),
    SENHA VARBINARY (MAX)
)
GO

-- Feito isso, vamos agora gerar nossa chave mestra, certificado e chave simétrica:

-- Criamos a chave mestra, dando a ela uma senha;
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'PASSWORD@123'
GO

-- Geramos o nosso certificado;
CREATE CERTIFICATE Certificado
ENCRYPTION BY PASSWORD = 'SENHA@123'
WITH SUBJECT = 'Certificado Senha Usuario'
GO

-- Adicionamos nossa chave simétrica utilizando o algoritmo AES_256 e protegendo-a por meio do certificado 
-- criado anteriormente.
CREATE SYMMETRIC KEY ChaveSenha
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE Certificado
GO

-- Após criarmos nossos objetos de criptografia, podemos consultá-los através das tabelas 
SELECT * FROM SYS.symmetric_keys
GO
SELECT * FROM SYS.certificates
GO

-- Antes de usar a chave simétrica para criptografar o campo senha da tabela Usuario, devemos abrir 
--essa chave, o que pode ser feito com o comando OPEN SYMMETRIC KEY, no qual também informamos o 
--certificado que foi utilizado ao criar a chave.

--Agora, para inserir no campo senha o valor criptografado, devemos utilizar a função ENCRYPTBYKEY, 
--para a qual devemos informar como primeiro parâmetro a GUID da chave que abrimos no comando anterior 
--(ela pode ser obtida com a função KEY_GUID), e o valor do campo.

--Abrimos a chave simétrica, disponibilizando-a para uso nas instruções seguintes;
OPEN SYMMETRIC KEY ChaveSenha
DECRYPTION BY CERTIFICATE Certificado WITH PASSWORD = 'SENHA@123'

-- Obtemos a GUID (identificador gerado automaticamente pelo SQL Server) da chave;
DECLARE @GUID UNIQUEIDENTIFIER = (SELECT KEY_GUID('ChaveSenha'))
-- Inserimos o valor criptografado na tabela;
INSERT INTO Usuario VALUES ('ALEX', ENCRYPTBYKEY(@GUID, 'alex@123'))
GO

-- Selecionamos os dados da tabela para ver o resultado da operação anterior;
SELECT * FROM Usuario

-- Fechamos a chave utilizada.
CLOSE SYMMETRIC KEY ChaveSenha

-- testando...
SELECT * FROM Usuario

-- Para descriptografar esses dados e ver o real valor que foi inserido no campo senha, 
-- devemos abrir novamente nossa chave simétrica, ler esse campo com a função DECRYPTBYKEY, 
-- converter seu valor para varchar e fechar a chave em seguida.

OPEN SYMMETRIC KEY ChaveSenha
DECRYPTION BY CERTIFICATE Certificado WITH PASSWORD = 'SENHA@123'
GO

SELECT    *
,   senhadescriptografada = CAST (DECRYPTBYKEY(SENHA) AS varchar(50))
FROM      Usuario
GO

CLOSE SYMMETRIC KEY ChaveSenha -- Se eu fechar, não é para aparecer mais

-- testando...
SELECT    *
,   senhadescriptografada = CAST (DECRYPTBYKEY(SENHA) AS varchar(50))
FROM      Usuario

---- DESMONTANDO O CENÁRIO
-- DROP MASTER KEY
-- DROP SYMMETRIC KEY ChaveSenha
-- DROP CERTIFICATE Certificado
-- DROP TABLE Usuario