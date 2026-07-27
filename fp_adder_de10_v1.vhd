library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_adder_de10_v1 is
    port (
        ADC_CLK_10 : in std_logic;
        SW : in std_logic_vector (9 downto 0);
        KEY : in std_logic_vector (1 downto 0);
        sign_out : out std_logic;
        exp_out : out std_logic_vector (3 downto 0);
        frac_out : out std_logic_vector (7 downto 0)
    );
end fp_adder_de10_v1;

architecture arch of fp_adder_de10_v1 is
    -- suffix b, s, a, n for
    -- big, small, aligned, normalized number
    signal contador : integer range 0 to 4;
    signal signb, signs, sign1, sign2 : std_logic;
    signal expb, exps, expn, exp1, exp2 : unsigned (3 downto 0);
    signal fracb, fracs, fraca, fracn, frac1, frac2  : unsigned (7 downto 0);
    signal sum_norm : unsigned (7 downto 0);
    signal exp_diff : unsigned (3 downto 0);
    signal sum : unsigned (8 downto 0); -- one extra for carry
    signal leado : unsigned (2 downto 0);
begin

    -- 1st stage: sort to find the larger number
    process (SW, KEY, ADC_CLK_10)
    begin
        if rising_edge(ADC_CLK_10) then
            if (KEY(1)='0') then
                sign1 <= '0';
                sign2 <= '0';
                frac1 <= "00000000";
                frac2 <= "00000000";
                exp1 <= "0000";
                exp2 <= "0000";
            else
                if (KEY(0)='0') then
                    if contador = 0 then
                        sign1 <= sw(9);
                        frac1 <= unsigned(sw(8 downto 1));
                        contador <= 1;
                    
                    elsif contador = 1 then
                        exp1 <= unsigned(sw(9 downto 6));
                        contador <= 2;
                    
                    elsif contador = 3 then
                        sign2 <= sw(9);
                        frac2 <= unsigned(sw(8 downto 1));
                        contador <= 4;
                    elsif contador = 4 then
                        exp2 <= unsigned(sw(9 downto 6));
                        contador <= 0;
                    end if;
                end if;
            end if;
        end if;

        if (exp1 & frac1) > (exp2 & frac2) then
            signb <= sign1;
            signs <= sign2;
            expb <= unsigned (exp1);
            exps <= unsigned (exp2);
            fracb <= unsigned (frac1);
            fracs <= unsigned (frac2);
        else
            signb <= sign2;
            signs <= sign1;
            expb <= unsigned (exp2);
            exps <= unsigned (exp1);
            fracb <= unsigned (frac2);
            fracs <= unsigned (frac1);
        end if;
    end process;

    -- 2nd stage: align smaller number
    exp_diff <= expb - exps;
    with exp_diff select
    fraca <=
        fracs when "0000",
        "0" & fracs (7 downto 1) when "0001",
        "00" & fracs (7 downto 2) when "0010",
        "000" & fracs (7 downto 3) when "0011",
        "0000" & fracs (7 downto 4) when "0100",
        "00000" & fracs (7 downto 5) when "0101",
        "000000" & fracs (7 downto 6) when "0110",
        "0000000" & fracs (7) when "0111",
        "00000000" when others;

    -- 3rd stage: add / subtract
    sum <=
        ('0' & fracb) + ('0' & fraca) when signb = signs else
        ('0' & fracb) - ('0' & fraca);

    -- 4th stage: normalize
    -- count leading 0s
    leado <= "000" when (sum (7) = '1') else
             "001" when (sum (6) = '1') else
             "010" when (sum (5) = '1') else
             "011" when (sum (4) = '1') else
             "100" when (sum (3) = '1') else
             "101" when (sum (2) = '1') else
             "110" when (sum (1) = '1') else
             "111";

    -- shift significand according to leading 0
    with leado select
        sum_norm <=
            sum (7 downto 0) when "000",
            sum (6 downto 0) & '0' when "001",
            sum (5 downto 0) & "00" when "010",
            sum (4 downto 0) & "000" when "011",
            sum (3 downto 0) & "0000" when "100",
            sum (2 downto 0) & "00000" when "101",
            sum (1 downto 0) & "000000" when "110",
            sum (0) & "0000000" when others;

    -- normalize with special conditions
    process (sum, sum_norm, expb, leado)
    begin
        if sum (8) = '1' then
            expn <= expb + 1;
            -- w/ carry out; shift frac to right
            fracn <= sum (8 downto 1);
        elsif (leado > expb) then
            expn <= (others => '0');
            fracn <= (others => '0');
            -- too small to normalize. set to 0
        else
            expn <= expb - leado;
            fracn <= sum_norm;
        end if;
    end process;

    -- form output
    sign_out <= signb;
    exp_out <= std_logic_vector (expn);
    frac_out <= std_logic_vector (fracn);
end arch;
