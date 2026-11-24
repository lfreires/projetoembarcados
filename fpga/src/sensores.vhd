-- sensores.vhd
-- Frente de sensores das 4 zonas: sincroniza, filtra e entrega para cada
-- MEF de zona as tres entradas qualificadas R, U e F.
--
-- Kit do grupo: 4 ultrassonicos HC-SR04, 2 reed, 1 PIR e 1 IR de obstaculo
-- (FC-51). Cada zona tem um ultrassonico e um sensor de outro tipo:
--
--   Zona   local na maquete   sensor A ("R")             sensor B ("U")
--   Z1     ambiente 1         reed da janela             ultrassonico 1 (outra janela)
--   Z2     ambiente 2         PIR                        ultrassonico 2 (mesma janela)
--   Z3     ambiente 3         PIR                        ultrassonico 3 (mesma janela)
--   Z4     quintal            IR FC-51 (cerca da frente) ultrassonico 4 (portinhola)
--
-- F de cada zona = ultrassonico da zona sem eco valido (FALHA_N medidas).
-- Os 4 ultrassonicos disparam defasados de 1/4 de periodo (15 ms) para que o
-- eco de um nao seja lido pelo outro.
--
-- Injecao de falhas (modo TESTE): quando a zona esta selecionada em
-- sel_teste, as leituras reais sao trocadas pelas chaves forca_r / forca_u
-- e a falha passa a ser a da chave inj_f (a leitura real fica de fora). As
-- chaves chegam aqui ja sincronizadas pelo bloco chaves.vhd.
library ieee;
use ieee.std_logic_1164.all;

entity sensores is
  generic (
    CLK_HZ     : positive := 10000000;
    PERIODO_US : positive := 60000;                -- periodo de cada ultrassonico
    REED_ATV   : integer range 0 to 1 := 1;   -- reed com pull-up: aberto = '1'
    IR_ATV     : integer range 0 to 1 := 0;   -- FC-51: saida vai a '0' ao detectar
    PIR_ATV    : integer range 0 to 1 := 1
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    -- pinos dos sensores
    z1_reed   : in  std_logic;
    z1_echo   : in  std_logic;
    z1_trig   : out std_logic;
    z2_pir    : in  std_logic;
    z2_echo   : in  std_logic;
    z2_trig   : out std_logic;
    z3_pir    : in  std_logic;
    z3_echo   : in  std_logic;
    z3_trig   : out std_logic;
    z4_ir     : in  std_logic;
    z4_echo   : in  std_logic;
    z4_trig   : out std_logic;
    -- calibracao do d0 dos ultrassonicos
    calibra   : in  std_logic;
    -- injecao de falhas
    sel_teste : in  std_logic_vector(3 downto 0);
    forca_r   : in  std_logic;
    forca_u   : in  std_logic;
    inj_f     : in  std_logic;
    -- saidas qualificadas por zona
    r1, u1, f1 : out std_logic;
    r2, u2, f2 : out std_logic;
    r3, u3, f3 : out std_logic;
    r4, u4, f4 : out std_logic;
    f_vec      : out std_logic_vector(3 downto 0);
    dist1_us   : out std_logic_vector(15 downto 0)
  );
end sensores;

architecture rtl of sensores is
  constant N_REED : positive := CLK_HZ / 50;    -- 20 ms
  constant N_IR   : positive := CLK_HZ / 100;   -- 10 ms
  constant N_PIR  : positive := CLK_HZ / 20;    -- 50 ms
  constant FASE   : natural  := PERIODO_US / 4; -- 15 ms entre os disparos

  signal rq, uq, fq : std_logic_vector(3 downto 0);   -- leituras reais
  signal ro, uo, fo : std_logic_vector(3 downto 0);   -- depois do teste
begin

  -- ---------------- Zona 1: reed da janela + ultrassom 1 ----------------
  z1a : entity work.sinc_debounce
    generic map (N_CICLOS => N_REED, ATIVO => REED_ATV)
    port map (clk => clk, rst => rst, d => z1_reed, q => rq(0));

  z1b : entity work.ultrassom
    generic map (CLK_HZ => CLK_HZ, PERIODO_US => PERIODO_US, FASE_US => 0)
    port map (clk => clk, rst => rst, echo => z1_echo, calibra => calibra,
              trig => z1_trig, alterado => uq(0), falha => fq(0),
              dist_us => dist1_us);

  -- ---------------- Zona 2: PIR + ultrassom 2 ----------------
  z2a : entity work.sinc_debounce
    generic map (N_CICLOS => N_PIR, ATIVO => PIR_ATV)
    port map (clk => clk, rst => rst, d => z2_pir, q => rq(1));

  z2b : entity work.ultrassom
    generic map (CLK_HZ => CLK_HZ, PERIODO_US => PERIODO_US, FASE_US => FASE)
    port map (clk => clk, rst => rst, echo => z2_echo, calibra => calibra,
              trig => z2_trig, alterado => uq(1), falha => fq(1),
              dist_us => open);

  -- ---------------- Zona 3: PIR + ultrassom 3 ----------------
  z3a : entity work.sinc_debounce
    generic map (N_CICLOS => N_PIR, ATIVO => PIR_ATV)
    port map (clk => clk, rst => rst, d => z3_pir, q => rq(2));

  z3b : entity work.ultrassom
    generic map (CLK_HZ => CLK_HZ, PERIODO_US => PERIODO_US, FASE_US => 2 * FASE)
    port map (clk => clk, rst => rst, echo => z3_echo, calibra => calibra,
              trig => z3_trig, alterado => uq(2), falha => fq(2),
              dist_us => open);

  -- ---------------- Zona 4: IR FC-51 + ultrassom 4 ----------------
  z4a : entity work.sinc_debounce
    generic map (N_CICLOS => N_IR, ATIVO => IR_ATV)
    port map (clk => clk, rst => rst, d => z4_ir, q => rq(3));

  z4b : entity work.ultrassom
    generic map (CLK_HZ => CLK_HZ, PERIODO_US => PERIODO_US, FASE_US => 3 * FASE)
    port map (clk => clk, rst => rst, echo => z4_echo, calibra => calibra,
              trig => z4_trig, alterado => uq(3), falha => fq(3),
              dist_us => open);

  -- ---------------- injecao de falhas ----------------
  gen_teste : for i in 0 to 3 generate
    ro(i) <= forca_r when sel_teste(i) = '1' else rq(i);
    uo(i) <= forca_u when sel_teste(i) = '1' else uq(i);
    fo(i) <= inj_f   when sel_teste(i) = '1' else fq(i);
  end generate;

  r1 <= ro(0);  u1 <= uo(0);  f1 <= fo(0);
  r2 <= ro(1);  u2 <= uo(1);  f2 <= fo(1);
  r3 <= ro(2);  u3 <= uo(2);  f3 <= fo(2);
  r4 <= ro(3);  u4 <= uo(3);  f4 <= fo(3);
  f_vec <= fo;

end rtl;
