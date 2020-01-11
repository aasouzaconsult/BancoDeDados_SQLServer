-- Autor: Alex Souza

-- Criando a função para Tirar Letras de Textos
CREATE FUNCTION Func_TirarLetras ( @Texto varchar(max) )
RETURNS varchar(max)
AS
BEGIN
   DECLARE @Resultado varchar(max)
   SELECT @Resultado = Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(@Texto, 'z', ' '), 'x', ' '), 'w', ' '), 'y', ' '), 'v', ' '), 'u', ' '), 't', ' '), 's', ' '), 'r', ' '), 'q', ' '), 'p', ' '), 'o', ' '), 'n', ' '), 'm', ' '), 'l', ' '), 'k', ' '), 'j', ' '), 'i', ' '), 'h', ' '), 'g', ' '), 'f', ' '), 'e', ' '), 'd', ' '), 'c', ' '), 'b', ' '), 'a', ' ')
   RETURN @Resultado
END

--Exemplo de Uso
Declare @Texto varchar(100)
Set @Texto = '1Tirando2as3Letras4X5P6T7O8Z9do10Texto'

-- Chamando a função
Select dbo.Func_TirarLetras (@Texto)
