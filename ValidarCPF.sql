-- Para testar depois de executar a função: 
-- SELECT dbo.Fun_ValidarCPF('29998105290')

-- Criando a função que Valida CPF

CREATE FUNCTION Fun_ValidarCPF(@CPF VARCHAR(11))
RETURNS CHAR(1)
AS
BEGIN
DECLARE @INDICE INT,
                    @SOMA INT,
                    @DIG1 INT,
                    @DIG2 INT,
                    @CPF_TEMP VARCHAR(11),
                    @DIGITOS_IGUAIS CHAR(1),
                    @RESULTADO CHAR(1)

SET @RESULTADO = 'N'

/* Verificando se os dígitos são iguais 
A Principio CPF com todos o números iguais são Inválidos apesar de validar o Calculo do digito verificado
EX: O CPF 00000000000 é inválido, mas pelo calculo Validaria */

SET @CPF_TEMP = SUBSTRING(@CPF,1,1)

SET @INDICE = 1
SET @DIGITOS_IGUAIS = 'S'

WHILE (@INDICE <= 11)
BEGIN
   IF SUBSTRING(@CPF,@INDICE,1) <> @CPF_TEMP
      SET @DIGITOS_IGUAIS = 'N'
      SET @INDICE = @INDICE + 1
   END;

--Caso os digitos não sejão todos iguais Começo o calculo do dígitos
IF @DIGITOS_IGUAIS = 'N'
BEGIN
   --Cálculo do 1º dígito
   SET @SOMA = 0  
   SET @INDICE = 1

   WHILE (@INDICE <= 9)
   BEGIN
      SET @Soma = @Soma + CONVERT(INT,SUBSTRING(@CPF,@INDICE,1)) * (11 - @INDICE);
      SET @INDICE = @INDICE + 1
   END

   SET @DIG1 = 11 - (@SOMA % 11)

   IF @DIG1 > 9
      SET @DIG1 = 0;

   -- Cálculo do 2º dígito }
   SET @SOMA = 0
   SET @INDICE = 1

   WHILE (@INDICE <= 10)
   BEGIN
      SET @Soma = @Soma + CONVERT(INT,SUBSTRING(@CPF,@INDICE,1)) * (12 - @INDICE);
      SET @INDICE = @INDICE + 1
   END

   SET @DIG2 = 11 - (@SOMA % 11)

   IF @DIG2 > 9
      SET @DIG2 = 0;

-- Validando
   IF (@DIG1 = SUBSTRING(@CPF,LEN(@CPF)-1,1)) AND (@DIG2 = SUBSTRING(@CPF,LEN(@CPF),1))
      SET @RESULTADO = 'S'
   ELSE
      SET @RESULTADO = 'N'
   END

   RETURN @RESULTADO
END
