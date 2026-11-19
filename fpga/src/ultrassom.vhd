-- ultrassom.vhd
-- Leitura do HC-SR04 e comparacao com a distancia de referencia d0.
--
--  * a cada PERIODO_US dispara um pulso de 10 us no TRIG
--  * mede a largura do ECHO em microssegundos (58 us ~ 1 cm)
--  * calibra = '1' : a proxima amostra valida vira a referencia d0
--  * alterado = '1' quando PERSIST amostras seguidas ficam fora de
--    d0 +- TOL_US (filtro de persistencia, evita falso positivo)
--  * falha = '1' quando FALHA_N amostras seguidas nao tem eco valido
--    (sensor desconectado, sem alimentacao ou eco preso)
--
-- Com varios sensores, FASE_US defasa o disparo de cada um para que o eco
-- de um nao seja lido pelo outro.
--
-- O ECHO do sensor e de 5 V. Usar divisor resistivo (1k / 2k) antes do FPGA.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ultrassom is
  generic (
    CLK_HZ     : positive := 10000000;
    PERIODO_US : positive := 60000;   -- uma medida a cada 60 ms
    TIMEOUT_US : positive := 30000;   -- eco maior que isso = invalido
    TOL_US     : positive := 290;     -- tolerancia (~5 cm)
    PERSIST    : positive := 3;       -- amostras seguidas para "alterado"
    FALHA_N    : positive := 5;       -- amostras invalidas seguidas para falha
    FASE_US    : natural  := 0        -- atraso do 1o disparo (defasa os sensores)
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    echo     : in  std_logic;
    calibra  : in  std_logic;
    trig     : out std_logic;
    alterado : out std_logic;
    falha    : out std_logic;
    dist_us  : out std_logic_vector(15 downto 0)   -- ultima medida (para o ILA)
  );
end ultrassom;

architecture rtl of ultrassom is
  constant DIV_US : positive := CLK_HZ / 1000000;

  signal cnt_div  : natural range 0 to DIV_US := 0;
  signal tick_us  : std_logic := '0';

  signal t_us     : natural range 0 to PERIODO_US := 0;
  signal echo1    : std_logic := '0';
  signal echo2    : std_logic := '0';
  signal echo_ant : std_logic := '0';

  signal larg       : natural range 0 to 65535 := 0;
  signal amostra    : natural range 0 to 65535 := 0;
  signal tem_amost  : std_logic := '0';

  signal d0         : natural range 0 to 65535 := 0;
  signal tem_d0     : std_logic := '0';
  signal cal_pend   : std_logic := '1';   -- calibra sozinho na primeira medida

  signal cnt_alt    : natural range 0 to PERSIST := 0;
  signal cnt_falha  : natural range 0 to FALHA_N := 0;
begin

  -- gera um pulso por microssegundo
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or cnt_div = DIV_US - 1 then
        cnt_div <= 0;
      else
        cnt_div <= cnt_div + 1;
      end if;
      if rst = '0' and cnt_div = DIV_US - 1 then
        tick_us <= '1';
      else
        tick_us <= '0';
      end if;
    end if;
  end process;

  process(clk)
    variable dif : natural range 0 to 65535;
  begin
    if rising_edge(clk) then
      echo1    <= echo;
      echo2    <= echo1;
      echo_ant <= echo2;

      if rst = '1' then
        t_us      <= (PERIODO_US - (FASE_US mod PERIODO_US)) mod PERIODO_US;
        larg      <= 0;
        amostra   <= 0;
        tem_amost <= '0';
        d0        <= 0;
        tem_d0    <= '0';
        cal_pend  <= '1';
        cnt_alt   <= 0;
        cnt_falha <= 0;
      else
        if calibra = '1' then
          cal_pend <= '1';
        end if;

        -- fim do pulso de eco: guarda a largura medida
        if echo_ant = '1' and echo2 = '0' then
          amostra   <= larg;
          tem_amost <= '1';
        end if;

        if tick_us = '1' then
          -- mede a largura do eco
          if echo2 = '1' then
            if larg < 65535 then
              larg <= larg + 1;
            end if;
          end if;

          if t_us = PERIODO_US - 1 then
            -- fim do periodo: avalia a amostra e comeca outra medida
            t_us      <= 0;
            larg      <= 0;
            tem_amost <= '0';

            if tem_amost = '1' and amostra > 0 and amostra < TIMEOUT_US then
              cnt_falha <= 0;
              if cal_pend = '1' then
                d0       <= amostra;
                tem_d0   <= '1';
                cal_pend <= '0';
                cnt_alt  <= 0;
              elsif tem_d0 = '1' then
                if amostra > d0 then
                  dif := amostra - d0;
                else
                  dif := d0 - amostra;
                end if;
                if dif > TOL_US then
                  if cnt_alt < PERSIST then
                    cnt_alt <= cnt_alt + 1;
                  end if;
                else
                  cnt_alt <= 0;
                end if;
              end if;
            else
              -- sem eco valido neste periodo
              if cnt_falha < FALHA_N then
                cnt_falha <= cnt_falha + 1;
              end if;
            end if;
          else
            t_us <= t_us + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  trig     <= '1' when t_us < 10 and rst = '0' else '0';
  alterado <= '1' when cnt_alt = PERSIST else '0';
  falha    <= '1' when cnt_falha = FALHA_N else '0';
  dist_us  <= std_logic_vector(to_unsigned(amostra, 16));

end rtl;
