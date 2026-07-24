library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_adder_tb is
end fp_adder_tb;

architecture sim of fp_adder_tb is
    -- Sinais de entrada
    signal sign1, sign2 : std_logic := '0';
    signal exp1, exp2   : std_logic_vector (3 downto 0) := (others => '0');
    signal frac1, frac2 : std_logic_vector (7 downto 0) := (others => '0');

    -- Sinais de saída
    signal sign_out     : std_logic;
    signal exp_out      : std_logic_vector (3 downto 0);
    signal frac_out     : std_logic_vector (7 downto 0);
begin

    -- Instanciação do componente principal que você quer testar
    uut: entity work.fp_adder
        port map (
            sign1     => sign1,
            sign2     => sign2,
            exp1      => exp1,
            exp2      => exp2,
            frac1     => frac1,
            frac2     => frac2,
            sign_out  => sign_out,
            exp_out   => exp_out,
            frac_out  => frac_out
        );

    -- Processo de estímulos (aqui você define os casos de teste)
    stimulus_process: process
    begin
        -- Caso 1: Teste inicial (Exemplo com frações e expoentes específicos)
        sign1 <= '0';
        exp1  <= "1000"; -- Expoente 8
        frac1 <= "11010101";
        
        sign2 <= '0';
        exp2  <= "1000"; -- Expoente 8
        frac2 <= "10101010";
        wait for 100 ns;

        -- Caso 2: Mudando os valores para testar subtração ou outros expoentes
        sign1 <= '0';
        exp1  <= "1010";
        frac1 <= "11110000";
        
        sign2 <= '1'; -- Número negativo
        exp2  <= "1001";
        frac2 <= "10110000";
        wait for 100 ns;

        -- Caso 3: Adicione mais casos de teste conforme desejar
        sign1 <= '1';
        exp1  <= "0111";
        frac1 <= "11000000";
        
        sign2 <= '1';
        exp2  <= "0111";
        frac2 <= "10000000";
        wait for 100 ns;

        -- Fim da simulação
        wait;
    end process;

end sim;
