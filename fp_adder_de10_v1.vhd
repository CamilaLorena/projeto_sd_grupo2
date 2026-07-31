library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_adder_de10_v1 is
    port (
        ADC_CLK_10 : in std_logic;
        SW         : in std_logic_vector (9 downto 0);
        KEY        : in std_logic_vector (1 downto 0);
        sign_out   : out std_logic;
        exp_out    : out std_logic_vector (3 downto 0);
        frac_out   : out std_logic_vector (7 downto 0);
        
        -- 6 Displays Declarados
        HEX0       : out std_logic_vector (6 downto 0);
        HEX1       : out std_logic_vector (6 downto 0);
        HEX2       : out std_logic_vector (6 downto 0);
        HEX3       : out std_logic_vector (6 downto 0);
        HEX4       : out std_logic_vector (6 downto 0);
        HEX5       : out std_logic_vector (6 downto 0);
        
        LEDR       : out std_logic_vector (3 downto 0)
    );
end fp_adder_de10_v1;

architecture arch of fp_adder_de10_v1 is
    signal contador : integer range 0 to 3 := 0; 
    signal signb, signs, sign1, sign2 : std_logic;
    signal expb, exps, expn, exp1, exp2 : unsigned (3 downto 0);
    signal fracb, fracs, fraca, fracn, frac1, frac2  : unsigned (7 downto 0);
    signal sum_norm : unsigned (7 downto 0);
    signal exp_diff : unsigned (3 downto 0);
    signal sum : unsigned (8 downto 0); 
    signal leado : unsigned (2 downto 0);

    signal key0_r1, key0_r2 : std_logic := '1';
    signal key0_pulse : std_logic;

    -- Sinais para armazenar os dígitos decimais (BCD)
    signal exp_dez, exp_uni : unsigned(3 downto 0);
    signal frac_cen, frac_dez, frac_uni : unsigned(3 downto 0);

    -- =================================================================
    -- FUNÇÃO DECODIFICADORA: Binário (0 a 9) para Display de 7 Segmentos
    -- =================================================================
    function decode_7seg(hex_val : unsigned(3 downto 0)) return std_logic_vector is
    begin
        case hex_val is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when others => return "1111111"; -- Desligado (Proteção)
        end case;
    end function;

begin

    -- 1. Detector de borda para o Botão
    process(ADC_CLK_10)
    begin
        if rising_edge(ADC_CLK_10) then
            key0_r1 <= KEY(0);
            key0_r2 <= key0_r1;
        end if;
    end process;
    key0_pulse <= '1' when key0_r2 = '1' and key0_r1 = '0' else '0';


    -- 2. Máquina de Estados (Entrada de Dados)
    process (ADC_CLK_10)
    begin
        if rising_edge(ADC_CLK_10) then
            if (KEY(1)='0') then -- RESET
                sign1 <= '0'; sign2 <= '0';
                frac1 <= (others => '0'); frac2 <= (others => '0');
                exp1 <= (others => '0'); exp2 <= (others => '0');
                contador <= 0; LEDR <= "0000";
            elsif (key0_pulse = '1') then 
                case contador is
                    when 0 =>
                        sign1 <= SW(9);
                        frac1 <= unsigned(SW(8 downto 1));
                        contador <= 1; LEDR <= "0001";
                    when 1 =>
                        exp1 <= unsigned(SW(9 downto 6));
                        contador <= 2; LEDR <= "0010";
                    when 2 =>
                        sign2 <= SW(9);
                        frac2 <= unsigned(SW(8 downto 1));
                        contador <= 3; LEDR <= "0100";
                    when 3 =>
                        exp2 <= unsigned(SW(9 downto 6));
                        contador <= 0; LEDR <= "1000";
                    when others =>
                        contador <= 0;
                end case;
            end if;
        end if;
    end process;

    -- 3. Ordenação (Qual é o maior número)
    process (exp1, frac1, exp2, frac2, sign1, sign2)
    begin
        if (exp1 & frac1) > (exp2 & frac2) then
            signb <= sign1; signs <= sign2; expb <= exp1; exps <= exp2; fracb <= frac1; fracs <= frac2;
        else
            signb <= sign2; signs <= sign1; expb <= exp2; exps <= exp1; fracb <= frac2; fracs <= frac1;
        end if;
    end process;

    -- 4. Alinhamento
    exp_diff <= expb - exps;
    with exp_diff select fraca <=
        fracs when "0000",
        "0" & fracs (7 downto 1) when "0001",
        "00" & fracs (7 downto 2) when "0010",
        "000" & fracs (7 downto 3) when "0011",
        "0000" & fracs (7 downto 4) when "0100",
        "00000" & fracs (7 downto 5) when "0101",
        "000000" & fracs (7 downto 6) when "0110",
        "0000000" & fracs (7) when "0111",
        "00000000" when others;

    -- 5. Soma/Subtração
    sum <= ('0' & fracb) + ('0' & fraca) when signb = signs else
           ('0' & fracb) - ('0' & fraca);

    -- 6. Normalização
    leado <= "000" when (sum(7) = '1') else
             "001" when (sum(6) = '1') else
             "010" when (sum(5) = '1') else
             "011" when (sum(4) = '1') else
             "100" when (sum(3) = '1') else
             "101" when (sum(2) = '1') else
             "110" when (sum(1) = '1') else
             "111";

    with leado select sum_norm <=
        sum(7 downto 0) when "000",
        sum(6 downto 0) & '0' when "001",
        sum(5 downto 0) & "00" when "010",
        sum(4 downto 0) & "000" when "011",
        sum(3 downto 0) & "0000" when "100",
        sum(2 downto 0) & "00000" when "101",
        sum(1 downto 0) & "000000" when "110",
        sum(0) & "0000000" when others;

    process (sum, sum_norm, expb, leado)
    begin
        if sum(8) = '1' then
            expn <= expb + 1;
            fracn <= sum(8 downto 1);
        elsif (leado > expb) then
            expn <= (others => '0');
            fracn <= (others => '0');
        else
            expn <= expb - leado;
            fracn <= sum_norm;
        end if;
    end process;


    -- =================================================================
    -- CONVERSÃO: Binário para BCD (Decimal)
    -- =================================================================
    process(fracn, expn)
        variable f_int : integer range 0 to 255;
        variable e_int : integer range 0 to 15;
    begin
        -- Transforma os vetores binários em números inteiros do VHDL
        f_int := to_integer(fracn);
        e_int := to_integer(expn);

        -- Separa os dígitos do Expoente (0 a 15)
        exp_dez <= to_unsigned(e_int / 10, 4);
        exp_uni <= to_unsigned(e_int mod 10, 4);

        -- Separa os dígitos da Fração (0 a 255)
        frac_cen <= to_unsigned(f_int / 100, 4);
        frac_dez <= to_unsigned((f_int mod 100) / 10, 4);
        frac_uni <= to_unsigned(f_int mod 10, 4);
    end process;

    
    -- =================================================================
    -- ATRIBUIÇÃO DOS RESULTADOS AOS DISPLAYS DE 7 SEGMENTOS
    -- Ordem física (Esquerda -> Direita): HEX5, HEX4, HEX3, HEX2, HEX1, HEX0
    -- =================================================================
    
    sign_out <= signb; 
    exp_out  <= std_logic_vector(expn);
    frac_out <= std_logic_vector(fracn);

    -- HEX 5: Exibe o SINAL do resultado na extrema esquerda (0 ou 1)
    with signb select HEX5 <=
        "1000000" when '0',
        "1111001" when '1',
        "1111111" when others;

    -- HEX 4, 3 e 2: Fração convertida para Decimal no meio
    HEX4 <= decode_7seg(frac_cen);
    HEX3 <= decode_7seg(frac_dez);
    HEX2 <= decode_7seg(frac_uni);

    -- HEX 1 e 0: Expoente convertido para Decimal na extrema direita
    HEX1 <= decode_7seg(exp_dez);
    HEX0 <= decode_7seg(exp_uni);

end arch;
