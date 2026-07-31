library ieee;
use ieee.std_logic_1164.all;

entity hex_to_sseg is
    port (
        hex  : in  std_logic_vector(3 downto 0); -- A entrada binária de 4 bits (de 0 a F)
        dp   : in  std_logic;                    -- Controle do Ponto Decimal (1 = acende, 0 = apaga)
        sseg : out std_logic_vector(7 downto 0)  -- Saída para os pinos do display (DP, G, F, E, D, C, B, A)
    );
end hex_to_sseg;

architecture comportamento of hex_to_sseg is
    -- Sinal interno para os 7 segmentos (sem o ponto decimal)
    signal segmentos : std_logic_vector(6 downto 0);
begin
    process(hex)
    begin
        -- Mapeia cada valor hexadecimal para o desenho visual no display
        -- Ordem dos bits: G, F, E, D, C, B, A (0 = LED Aceso, 1 = LED Apagado)
        case hex is
            when "0000" => segmentos <= "1000000"; -- Exibe '0'
            when "0001" => segmentos <= "1111001"; -- Exibe '1'
            when "0010" => segmentos <= "0100100"; -- Exibe '2'
            when "0011" => segmentos <= "0110000"; -- Exibe '3'
            when "0100" => segmentos <= "0011001"; -- Exibe '4'
            when "0101" => segmentos <= "0010010"; -- Exibe '5'
            when "0110" => segmentos <= "0000010"; -- Exibe '6'
            when "0111" => segmentos <= "1111000"; -- Exibe '7'
            when "1000" => segmentos <= "0000000"; -- Exibe '8'
            when "1001" => segmentos <= "0010000"; -- Exibe '9'
            when "1010" => segmentos <= "0001000"; -- Exibe 'A'
            when "1011" => segmentos <= "0000011"; -- Exibe 'b'
            when "1100" => segmentos <= "1000110"; -- Exibe 'C'
            when "1101" => segmentos <= "0100001"; -- Exibe 'd'
            when "1110" => segmentos <= "0000110"; -- Exibe 'E'
            when "1111" => segmentos <= "0001110"; -- Exibe 'F'
            when others => segmentos <= "1111111"; -- Todos apagados por segurança
        end case;
    end process;

    -- Concatena o Ponto Decimal (bit 7) com os segmentos (bits 6 a 0)
    -- Se dp='1' (queremos o ponto), invertemos para '0' pois a placa é Anodo Comum.
    sseg <= not(dp) & segmentos;

end comportamento;