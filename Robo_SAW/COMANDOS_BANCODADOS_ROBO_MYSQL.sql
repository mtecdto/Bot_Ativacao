/* Colocar banco de dados em uso, sempre que for entrar roda o comando */
USE dto_keys;


/* Visualizar tudo que tem no banco de dados */
SELECT * FROM general_keys;


/* Visualizar tudo que tem no banco de dados com o status (0,1,2,3) basta substituir */
SELECT * FROM general_keys WHERE keystate=3;


/* ATUALIZAR CHAVE (no exemplo vai mudar o status das chaves para disponível 0, todas as chaves que estiverem com o status bloqueada 2, PARA OUTRAS OPERAÇÕES BASTA MUDAR PARA O STATUS DESEJADO)*/
UPDATE general_keys SET keystate=0 WHERE keystate=2;


/* DELETAR TODAS AS CHAVES DO BANCO */
DELETE FROM general_keys WHERE idkey>0;

