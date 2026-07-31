library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade agora utiliza a nomenclatura padrão da placa DE10-Lite
entity fp_adder_de10_lite is
   port(
      -- Entradas da DE10-Lite
      MAX10_CLK1_50 : in std_logic; -- Clock de 50 MHz (Caso o hex_to_sseg precise, embora usualmente seja combinacional)
      SW   : in std_logic_vector (9 downto 0); -- A DE10-Lite possui 10 chaves deslizantes
      KEY  : in std_logic_vector (1 downto 0); -- A DE10-Lite possui apenas 2 botões (ativos em nível baixo)
      
      -- Saídas diretas e dedicadas para os 6 displays de 7 segmentos da placa
      HEX0 : out std_logic_vector (7 downto 0);
      HEX1 : out std_logic_vector (7 downto 0);
      HEX2 : out std_logic_vector (7 downto 0);
      HEX3 : out std_logic_vector (7 downto 0);
      HEX4 : out std_logic_vector (7 downto 0);
      HEX5 : out std_logic_vector (7 downto 0)
   );
end fp_adder_de10_lite;

architecture arch of fp_adder_de10_lite is
   
   -- Sinais internos para interligar com o módulo somador original (Listagem 3.19)
   signal sign1, sign2: std_logic;
   signal exp1, exp2: std_logic_vector (3 downto 0);
   signal frac1, frac2: std_logic_vector (7 downto 0);
   
   signal sign_out: std_logic;
   signal exp_out: std_logic_vector (3 downto 0);
   signal frac_out: std_logic_vector (7 downto 0);

begin
   -- =====================================================================
   -- 1. ADAPTAÇÃO DAS ENTRADAS PARA A DE10-LITE
   -- =====================================================================
   
   -- Número 1: Lógica mantida do original (parcialmente fixa)
   sign1 <= '0';
   exp1 <= "1000";
   frac1 <= '1' & SW(1) & SW(0) & "10101"; 

   -- Número 2: Controlado pelo Usuário com o hardware disponível
   sign2 <= SW(7);
   
   -- Como temos apenas 2 KEYs, pegamos as chaves SW9 e SW8 emprestadas para 
   -- completar os 4 bits necessários para o exp2.
   -- *Nota: Botões KEY na DE10-Lite costumam ser "1" soltos e "0" pressionados.
   exp2 <= SW(9) & SW(8) & KEY(1) & KEY(0); 
   
   frac2 <= '1' & SW(6 downto 0); 

   -- =====================================================================
   -- 2. INSTANCIAÇÃO DO SOMADOR DE PONTO FLUTUANTE
   -- =====================================================================
   fp_add_unit: entity work.fp_adder
      port map (
         sign1=>sign1, sign2=>sign2, exp1=>exp1, exp2=>exp2,
         frac1=>frac1, frac2=>frac2,
         sign_out=>sign_out, exp_out=>exp_out,
         frac_out=>frac_out
      );

   -- =====================================================================
   -- 3. SAÍDAS PARA OS DISPLAYS DA DE10-LITE (Sem Multiplexação)
   -- =====================================================================
   
   -- Display HEX0: Exibe o expoente (Conectado diretamente)
   sseg_unit_0: entity work.hex_to_sseg
      port map (hex=>exp_out, dp=>'0', sseg=>HEX0);

   -- Display HEX1: Exibe os 4 bits menos significativos da fração
   sseg_unit_1: entity work.hex_to_sseg
      port map (hex=>frac_out(3 downto 0), dp=>'1', sseg=>HEX1);

   -- Display HEX2: Exibe os 4 bits mais significativos da fração
   sseg_unit_2: entity work.hex_to_sseg
      port map (hex=>frac_out(7 downto 4), dp=>'0', sseg=>HEX2);

   -- Display HEX3: Indicador visual de sinal (Negativo ou Positivo)
   -- Usando o mapeamento original (onde "11111110" acende o traço do meio).
   -- Obs: Se o traço ficar no lugar errado na DE10-Lite, troque por "01111111" ou similar.
   HEX3 <= "11111110" when sign_out='1' else 
           "11111111"; 

   -- Desligando os displays não utilizados da placa (Anodo comum = '1' apaga)
   HEX4 <= "11111111";
   HEX5 <= "11111111";

end arch;