library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench para fp_adder_de10_v1
-- Requer VHDL-2008 (usa "external names" para acessar os sinais
-- internos expn e fracn do DUT, já que eles não são portas).

entity fp_adder_test is
end fp_adder_test;

architecture sim of fp_adder_test is
    -- Sinais de interface com o DUT (equivalentes às entradas físicas da DE10)
    signal ADC_CLK_10 : std_logic := '0';
    signal SW         : std_logic_vector (9 downto 0) := (others => '0');
    signal KEY        : std_logic_vector (1 downto 0) := (others => '1'); -- '1' = solto

    -- Saídas do DUT
    signal sign_out   : std_logic;
    signal exp_out    : std_logic_vector (3 downto 0);
    signal frac_out   : std_logic_vector (7 downto 0);

    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector (6 downto 0);
    signal LEDR       : std_logic_vector (3 downto 0);

    constant CLK_PERIOD : time := 20 ns;

    -- OBS: expn e fracn são sinais internos da arquitetura "arch" do DUT
    -- (não são portas). Não precisamos de external names para vê-los:
    -- basta dar dump da hierarquia inteira na simulação e abrir no
    -- GTKWave, onde eles aparecem em uut/expn e uut/fracn.

begin

    -- Associação das variáveis do código original com as entradas do testbench.
    uut: entity work.fp_adder_de10_v1
        port map (
            ADC_CLK_10 => ADC_CLK_10,
            SW         => SW,
            KEY        => KEY,
            sign_out   => sign_out,
            exp_out    => exp_out,
            frac_out   => frac_out,
            HEX0       => HEX0,
            HEX1       => HEX1,
            HEX2       => HEX2,
            HEX3       => HEX3,
            HEX4       => HEX4,
            HEX5       => HEX5,
            LEDR       => LEDR
        );

    -- Geração do clock
    clk_process: process
    begin
        ADC_CLK_10 <= '0';
        wait for CLK_PERIOD / 2;
        ADC_CLK_10 <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Testes de cálculos
    stimulus_process: process

        -- Simula um clique no botão KEY(0), respeitando o sincronismo de
        -- 2 flip-flops usado no DUT para detectar a borda de descida.
        procedure press_key0 is
        begin
            wait until rising_edge(ADC_CLK_10);
            KEY(0) <= '0';
            wait for 3 * CLK_PERIOD;
            KEY(0) <= '1';
            wait for 3 * CLK_PERIOD;
        end procedure;

        -- Carrega um operando completo (sinal + fração, depois expoente),
        -- reproduzindo os 2 passos que o usuário faria com as chaves SW.
        procedure load_operand(sign_bit : std_logic;
                                frac_bits : std_logic_vector (7 downto 0);
                                exp_bits  : std_logic_vector (3 downto 0)) is
        begin
            SW(9)          <= sign_bit;
            SW(8 downto 1) <= frac_bits;
            press_key0;

            SW(9 downto 6) <= exp_bits;
            press_key0;
        end procedure;

        -- Carrega os dois operandos de um caso de teste e imprime os
        -- resultados, incluindo os sinais intermediários expn e fracn.
        procedure run_case(caseName : string;
                            sign1v : std_logic; exp1v : std_logic_vector (3 downto 0); frac1v : std_logic_vector (7 downto 0);
                            sign2v : std_logic; exp2v : std_logic_vector (3 downto 0); frac2v : std_logic_vector (7 downto 0)) is
        begin
            report "==== " & caseName & " ====";

            load_operand(sign1v, frac1v, exp1v);
            load_operand(sign2v, frac2v, exp2v);

            wait for 2 * CLK_PERIOD; -- aguarda a lógica combinacional estabilizar
            -- expn e fracn (sinais internos do DUT) podem ser conferidos
            -- aqui neste instante de tempo diretamente no GTKWave,
            -- em uut/expn e uut/fracn.

            report "sign_out = " & std_logic'image(sign_out);
            report "exp_out  = " & integer'image(to_integer(unsigned(exp_out)));
            report "frac_out = " & integer'image(to_integer(unsigned(frac_out)));
        end procedure;

    begin
        -- Reset inicial (KEY(1) = '0' limpa os registradores internos)
        KEY(1) <= '0';
        wait for 4 * CLK_PERIOD;
        KEY(1) <= '1';
        wait for 2 * CLK_PERIOD;

        -- Caso 1
        run_case("Caso 1",
                  '0', "0011", "00110110",
                  '1', "0100", "01010111");

        -- Caso 2
        run_case("Caso 2",
                  '0', "1010", "11110000",
                  '1', "1001", "10110000");

        -- Caso 3
        run_case("Caso 3",
                  '1', "0111", "11000000",
                  '1', "0111", "10000000");

        wait;
    end process;

end sim;
