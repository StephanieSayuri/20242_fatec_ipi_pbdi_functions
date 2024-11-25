-- Active: 1726576516959@@localhost@1234@postgres@public

---------------------------------------------------------------------
-- Bloco de Código 2.8.1
---------------------------------------------------------------------

CREATE TABLE tb_cliente(
    cod_cliente SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL
);

INSERT INTO tb_cliente (nome) VALUES ('joão santos'), ('maria andrade');
SELECT * FROM tb_cliente;

CREATE TABLE tb_tipo_conta (
    cod_tipo_conta SERIAL PRIMARY KEY,
    descricao VARCHAR(200) NOT NULL
);

INSERT INTO tb_tipo_conta (descricao) VALUES ('conta corrente'), ('conta poupança');
SELECT * FROM tb_tipo_conta;

CREATE TABLE tb_conta (
    cod_conta SERIAL PRIMARY KEY,
    status VARCHAR(200) NOT NULL DEFAULT 'aberta',
    data_criacao TIMESTAMP DEFAULT current_timestamp,
    data_ultima_transacao TIMESTAMP DEFAULT current_timestamp,
    saldo NUMERIC(10, 2) NOT NULL DEFAULT 1000 CHECK (saldo >= 1000),
    cod_cliente INT NOT NULL,
    cod_tipo_conta INT NOT NULL,
    constraint fk_cliente FOREIGN KEY (cod_cliente) REFERENCES tb_cliente(cod_cliente),
    constraint fk_tipo_conta FOREIGN KEY (cod_tipo_conta) REFERENCES tb_tipo_conta(cod_tipo_conta)
);
SELECT * FROM tb_conta;

---------------------------------------------------------------------
-- Bloco de Código 2.9.1
---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_abrir_conta;
CREATE OR REPLACE FUNCTION fn_abrir_conta (
    IN p_cod_cli INT,
    IN p_saldo NUMERIC(10, 2), 
    IN p_cod_tipo_conta INT) 
    RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO tb_conta (cod_cliente, saldo, cod_tipo_conta) VALUES ($1, $2, $3);
    RETURN TRUE;

    EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;

DO $$
DECLARE
    v_cod_cliente INT := 2;
    v_saldo NUMERIC (10, 2) := 500;
    v_cod_tipo_conta INT := 1;
    v_resultado BOOLEAN;
BEGIN
    SELECT fn_abrir_conta (v_cod_cliente, v_saldo, v_cod_tipo_conta) INTO v_resultado;
    RAISE NOTICE '%', FORMAT('Conta com saldo R$%s%s foi aberta', v_saldo, 
        CASE WHEN v_resultado THEN '' ELSE ' não' END);

    v_saldo := 1000;
    SELECT fn_abrir_conta (v_cod_cliente, v_saldo, v_cod_tipo_conta) INTO v_resultado;
    RAISE NOTICE '%', FORMAT('Conta com saldo R$%s%s foi aberta', v_saldo, 
        CASE WHEN v_resultado THEN '' ELSE ' não' END);
END;
$$;
SELECT * FROM tb_conta;

---------------------------------------------------------------------
-- Bloco de Código 2.10.1
---------------------------------------------------------------------
-- ROUTINE se aplica a funções e procedimentos
DROP ROUTINE IF EXISTS fn_depositar;
CREATE OR REPLACE FUNCTION fn_depositar (IN p_cod_cliente INT, IN p_cod_conta INT,
    IN p_valor NUMERIC(10, 2)) RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql AS $$
DECLARE
    v_saldo_resultante NUMERIC(10, 2);
BEGIN
    UPDATE tb_conta SET saldo = saldo + p_valor WHERE cod_cliente = p_cod_cliente AND cod_conta = p_cod_conta;

    SELECT saldo FROM tb_conta c 
    WHERE c.cod_cliente = p_cod_cliente 
    AND c.cod_conta = p_cod_conta 
    INTO v_saldo_resultante;

    RETURN v_saldo_resultante;
END;
$$;

DO $$
DECLARE
    v_cod_cliente INT := 1;
    v_cod_conta INT := 2;
    v_valor NUMERIC(10, 2) := 200;
    v_saldo_resultante NUMERIC (10, 2);
BEGIN
    SELECT fn_depositar (v_cod_cliente, v_cod_conta, v_valor) INTO v_saldo_resultante;
    RAISE NOTICE '%', FORMAT('Após depositar R$%s, o saldo resultante é de R$%s', v_valor, v_saldo_resultante);
END;
$$;

SELECT * FROM tb_conta;




-- 1 Exercícios

-- 1.1 Escreva a seguinte função:
-- nome: fn_consultar_saldo
-- recebe: código de cliente, código de conta
-- devolve: o saldo da conta especificada
CREATE OR REPLACE FUNCTION fn_consultar_saldo (
    IN p_cod_cliente INT, 
    IN p_cod_conta INT)
    RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql AS $$
DECLARE
    v_saldo_resultante NUMERIC(10, 2);
BEGIN
    SELECT saldo FROM tb_conta c 
    WHERE c.cod_cliente = p_cod_cliente 
    AND c.cod_conta = p_cod_conta 
    INTO v_saldo_resultante;

    RETURN v_saldo_resultante;
END;
$$;


-- 1.2 Escreva a seguinte função:
-- nome: fn_transferir
-- recebe: código de cliente remetente, código de conta remetente, código de cliente destinatário, código de conta destinatário, valor da transferência
-- devolve: um booleano que indica se a transferência ocorreu ou não. Uma transferência somente pode acontecer se nenhuma conta envolvida ficar no negativo.
CREATE OR REPLACE FUNCTION fn_transferir (
    IN p_cliente_remente INT, 
    IN p_conta_remente INT, 
    IN p_cliente_destinatario INT, 
    IN p_conta_destinatario INT, 
    IN v_valor NUMERIC(10, 2))
    RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado BOOLEAN;
    saldo_remente NUMERIC(10, 2);
BEGIN
    SELECT saldo FROM tb_conta c 
    WHERE c.cod_cliente = p_cliente_remente 
    AND c.cod_conta = p_conta_remente 
    INTO saldo_remente;

    IF saldo_remente >= v_valor THEN
        UPDATE tb_conta SET saldo = saldo - v_valor WHERE cod_cliente = p_cliente_remente AND cod_conta = p_conta_remente;
        UPDATE tb_conta SET saldo = saldo + v_valor WHERE cod_cliente = p_cliente_destinatario AND cod_conta = p_conta_destinatario;
        v_resultado := TRUE;
    ELSE
        v_resultado := FALSE;
    END IF;

    RETURN v_resultado;
END;
$$;


-- 1.3 Escreva blocos anônimos para testar cada função.
DO $$
DECLARE
    resultado NUMERIC(10, 2);
BEGIN
    SELECT fn_consultar_saldo(1, 2) INTO resultado;
    RAISE NOTICE '%', resultado;
END;
$$;

DO $$
DECLARE
    resultado BOOLEAN;
BEGIN
    resultado := fn_transferir(1, 2, 2, 5, 100.00);
    RAISE NOTICE '%', resultado;
END;
$$;

SELECT * FROM tb_conta;