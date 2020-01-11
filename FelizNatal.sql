USE tempdb
GO

-- Preparando o cenário
CREATE TABLE #ChristmasScene
(
item VARCHAR(32)
,shape GEOMETRY
) ;

-- Coloca a árvore e estrela
INSERT INTO #ChristmasScene
VALUES ( 'Tree',
'POLYGON((4 0, 0 0, 3 2, 1 2, 3 4, 1 4, 3 6, 2 6, 4 8, 6 6, 5 6, 7 4, 5 4, 7 2, 5 2, 8 0, 4 0))' ),
( 'Base', 'POLYGON((2.5 0, 3 -1, 5 -1, 5.5 0, 2.5 0))' ),
( 'Star',
'POLYGON((4 7.5, 3.5 7.25, 3.6 7.9, 3.1 8.2, 3.8 8.2, 4 8.9, 4.2 8.2, 4.9 8.2, 4.4 7.9, 4.5 7.25, 4 7.5))' )

-- Decorando a árvore
DECLARE @i INT = 0
,@x INT
,@y INT ;
WHILE ( @i < 20 )
BEGIN
INSERT INTO #ChristmasScene
VALUES ( 'Bauble' + CAST(@i AS VARCHAR(8)),
GEOMETRY::Point(RAND() * 5 + 1.5, RAND() * 6, 0).STBuffer(0.3) )
SET @i = @i + 1 ;
END

-- Saudação de Natal
insert into #ChristmasScene
VALUES
('F',
'POLYGON((1 10, 1 11, 2 11, 2 10.8, 1.25 10.8, 1.25 10.6, 1.75 10.6, 1.75 10.4, 1.25 10.4, 1.25 10, 1 10))'),
('E',
'POLYGON((2 10, 2 11, 3 11, 3 10.8, 2.25 10.8, 2.25 10.6, 2.75 10.6, 2.75 10.4, 2.25 10.4, 2.25 10.2, 3 10.2, 3 10, 2 10))'),
('L',
'POLYGON((3.15 11, 3.15 10, 3.85 10, 3.85 10.2, 3.35 10.2, 3.35 11, 3.15 11))'),
('I',
'POLYGON((4.2 11, 4.8 11, 4.8 10.8, 4.6 10.8, 4.6 10.2, 4.8 10.2, 4.8 10, 4.2 10, 4.2 10.2, 4.4 10.2, 4.4 10.8, 4.2 10.8, 4.2 11))'),
('Z',
'POLYGON((5 11, 6 11, 5.4 10.2, 6 10.2, 6 10, 5 10, 5.6 10.8, 5 10.8, 5 11))'),

('N',
'POLYGON((2 10, 2 9, 2.2 9, 2.2 9.8, 2.8 9, 3 9, 3 10, 2.8 10, 2.8 9.3, 2.3 10, 2 10))'),
('A',
'POLYGON((3 9, 3 10, 4 10, 4 9, 3.75 9, 3.75 9.3, 3.25 9.3, 3.25 9, 3 9),(3.25 9.5, 3.25 9.8, 3.75 9.8, 3.75 9.5, 3.25 9.5))' ),
( 'T',
'POLYGON((4 9.8, 4 10, 5 10, 5 9.8, 4.6 9.8, 4.6 9, 4.4 9, 4.4 9.8, 4 9.8))' ),
('A',
'POLYGON((5 9, 5 10, 6 10, 6 9, 5.75 9, 5.75 9.3, 5.25 9.3, 5.25 9, 5 9),(5.25 9.5, 5.25 9.8, 5.75 9.8, 5.75 9.5, 5.25 9.5))' ),
('L',
'POLYGON((6.15 10, 6.15 9, 6.85 9, 6.85 9.2, 6.35 9.2, 6.35 10, 6.15 10))')
;

-- Admire a cena
SELECT *
FROM #ChristmasScene -- Arrume as agulhas de pinheiro e guarde as decorações

-- Apague o cenário criado
DROP TABLE #ChristmasScene
