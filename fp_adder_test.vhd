library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_adder_test is
end fp_adder_test;

architecture sim of fp_adder_test is
    -- Entrada
    signal sign1, sign2 : std_logic := '0';
    signal exp1, exp2   : std_logic_vector (3 downto 0) := (others => '0');
    signal frac1, frac2 : std_logic_vector (7 downto 0) := (others => '0');

    -- Saída
    signal sign_out     : std_logic;
    signal exp_out      : std_logic_vector (3 downto 0);
    signal frac_out     : std_logic_vector (7 downto 0);
begin

    - Associação das variáveis do código original com as entradas do testbench. 
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

    -- Testes de cálculos
    stimulus_process: process
    begin
        -- Caso 1
        sign1 <= '0';
        exp1  <= "0011";
        frac1 <= "00110110";
        
        sign2 <= '1';
        exp2  <= "0100"; 
        frac2 <= "01010111";
        wait for 100 ns;

        -- Caso 2
        sign1 <= '0';
        exp1  <= "1010";
        frac1 <= "11110000";
        
        sign2 <= '1'; 
        exp2  <= "1001";
        frac2 <= "10110000";
        wait for 100 ns;

        -- Caso 3
        sign1 <= '1';
        exp1  <= "0111";
        frac1 <= "11000000";
        
        sign2 <= '1';
        exp2  <= "0111";
        frac2 <= "10000000";
        wait for 100 ns;
        wait;
    end process;

end sim;
