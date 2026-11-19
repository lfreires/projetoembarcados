-- top_central.vhd
-- Topo da central escrito so em VHDL (sem Block Design).
--
-- O projeto oficial e montado no IP Integrator (scripts/cria_projeto.tcl),
-- onde o Clocking Wizard, o Binary Counter, os Slices, os Concats e a
-- logica de vetor fazem o que aqui esta escrito a mao. Este arquivo existe
-- por dois motivos:
--   1. simular o sistema inteiro no testbench tb_top
--   2. servir de plano B: da para gerar o bitstream direto dele
--
-- Chaves:
--   SW3..0    habilita zona 1..4 (0 = zona isolada)
--   SW7..4    seleciona zona(s) em TESTE
--   SW8       forca R      SW9  forca U      SW10  injeta falha F
--   SW13..11  atraso: 0, 5, 10, 20, 30, 60, 90, 120 s
--   SW15..14  Tcorr: 0,1 s / 0,5 s / 1 s / 2 s
-- Botoes: BTNC reset | BTNU armar | BTND desarmar | BTNL reconhecer DEG
--         BTNR calibrar d0 dos ultrassonicos
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_central is
  generic (
    CLK_HZ    : positive := 100000000;   -- sem Clocking Wizard: 100 MHz direto
    BIT_SEL   : natural  := 18;          -- bits do contador para o display
    BIT_PISCA : natural  := 25;          -- pisca lento (~1,5 Hz): pre-alarme e LED15
    BIT_RAPIDO: natural  := 24           -- pisca rapido (~3 Hz): LED de alarme no disparo
  );
  port (
    clk        : in  std_logic;
    btnC       : in  std_logic;
    btnU       : in  std_logic;
    btnD       : in  std_logic;
    btnL       : in  std_logic;
    btnR       : in  std_logic;
    sw         : in  std_logic_vector(15 downto 0);
    led        : out std_logic_vector(15 downto 0);
    seg        : out std_logic_vector(6 downto 0);
    dp         : out std_logic;
    an         : out std_logic_vector(3 downto 0);
    -- sensores
    z1_pir    : in  std_logic;
    z1_trig    : out std_logic;
    z1_echo    : in  std_logic;
    z2_reed    : in  std_logic;
    z2_trig    : out std_logic;
    z2_echo    : in  std_logic;
    z3_pir     : in  std_logic;
    z3_trig    : out std_logic;
    z3_echo    : in  std_logic;
    z4_ir      : in  std_logic;
    z4_trig    : out std_logic;
    z4_echo    : in  std_logic;
    -- atuadores
    sirene     : out std_logic;
    estrobo    : out std_logic;
    nevoa      : out std_logic;
    cerca      : out std_logic;
    -- ESP32
    esp_rst    : out std_logic;
    esp_hb     : in  std_logic;
    esp_d      : out std_logic_vector(3 downto 0);
    esp_sof    : out std_logic;
    esp_req    : out std_logic;
    esp_ack    : in  std_logic;
    modo_deg   : out std_logic;
    arm_req    : in  std_logic;
    disarm_req : in  std_logic;
    cmd_ack    : out std_logic;
    cmd_ok     : out std_logic
  );
end top_central;

architecture rtl of top_central is
  signal rst      : std_logic;
  signal contador : unsigned(26 downto 0) := (others => '0');
  signal sel_disp : std_logic_vector(1 downto 0);
  signal pisca    : std_logic;
  signal rapido   : std_logic;

  signal p_armar, p_desarm, p_rec, p_calib : std_logic;
  signal r, u, f : std_logic_vector(3 downto 0);
  signal al_z, deg_z, pronta_z, viu_r_z, viu_u_z : std_logic_vector(3 downto 0);
  signal est_z    : std_logic_vector(11 downto 0);
  signal motivo_z : std_logic_vector(7 downto 0);

  signal armada, pre_alarme, disparo : std_logic;
  signal est_central : std_logic_vector(1 downto 0);
  signal arm_c, disarm_c, cmd_feito, cmd_ok_c : std_logic;
  signal cmd_ack_i, cmd_res : std_logic;
  signal rest_c, rest_d, rest_u : std_logic_vector(3 downto 0);
  signal esp_ok, falha_esp : std_logic;
  signal teste, modo_deg_i : std_logic;
  signal sw_s : std_logic_vector(15 downto 0);
begin

  u_sw : entity work.chaves
    port map (clk => clk, sw => sw, sw_s => sw_s);

  -- reset (aqui nao tem Clocking Wizard, entao locked = '1')
  u_rst : entity work.reset_ger
    port map (clk => clk, locked => '1', btn => btnC, rst => rst);

  -- contador livre (no Block Design e o IP Binary Counter)
  process(clk)
  begin
    if rising_edge(clk) then
      contador <= contador + 1;
    end if;
  end process;
  sel_disp <= std_logic_vector(contador(BIT_SEL downto BIT_SEL - 1));
  pisca    <= contador(BIT_PISCA);
  rapido   <= contador(BIT_RAPIDO);

  u_btn : entity work.botoes
    generic map (CLK_HZ => CLK_HZ)
    port map (clk => clk, rst => rst,
              btn_armar => btnU, btn_desarm => btnD, btn_rec => btnL, btn_calib => btnR,
              p_armar => p_armar, p_desarm => p_desarm, p_rec => p_rec, p_calib => p_calib);

  u_sens : entity work.sensores
    generic map (CLK_HZ => CLK_HZ)
    port map (clk => clk, rst => rst,
              z1_pir => z1_pir, z1_echo => z1_echo, z1_trig => z1_trig,
              z2_reed => z2_reed, z2_echo => z2_echo, z2_trig => z2_trig,
              z3_pir => z3_pir, z3_echo => z3_echo, z3_trig => z3_trig,
              z4_ir => z4_ir, z4_echo => z4_echo, z4_trig => z4_trig,
              calibra => p_calib,
              sel_teste => sw_s(7 downto 4), forca_r => sw_s(8), forca_u => sw_s(9), inj_f => sw_s(10),
              r1 => r(0), u1 => u(0), f1 => f(0),
              r2 => r(1), u2 => u(1), f2 => f(1),
              r3 => r(2), u3 => u(2), f3 => f(2),
              r4 => r(3), u4 => u(3), f4 => f(3),
              f_vec => open, dist1_us => open);

  -- as 4 MEFs de zona
  gen_zonas : for i in 0 to 3 generate
    u_zona : entity work.mef_zona
      generic map (CLK_HZ => CLK_HZ)
      port map (clk => clk, rst => rst,
                en => sw_s(i), armada => armada,
                r => r(i), u => u(i), f => f(i),
                rec_deg => p_rec, tcorr_sel => sw_s(15 downto 14),
                al => al_z(i), deg => deg_z(i), pronta => pronta_z(i),
                estado => est_z(3*i + 2 downto 3*i),
                motivo => motivo_z(2*i + 1 downto 2*i),
                viu_r => viu_r_z(i), viu_u => viu_u_z(i));
  end generate;

  u_cmd : entity work.cmd_esp
    generic map (CLK_HZ => CLK_HZ)
    port map (clk => clk, rst => rst, esp_ok => esp_ok,
              arm_esp => arm_req, disarm_esp => disarm_req,
              btn_armar => p_armar, btn_desarm => p_desarm,
              cmd_feito => cmd_feito, cmd_ok => cmd_ok_c,
              arm_req => arm_c, disarm_req => disarm_c,
              cmd_ack => cmd_ack_i, cmd_res => cmd_res);

  u_central : entity work.mef_central
    generic map (CLK_HZ => CLK_HZ, NEVOA_S => 10)
    port map (clk => clk, rst => rst,
              arm_req => arm_c, disarm_req => disarm_c,
              al_z => al_z, en_z => sw_s(3 downto 0), pronta_z => pronta_z,
              atraso_sel => sw_s(13 downto 11),
              armada => armada, pre_alarme => pre_alarme, disparo => disparo,
              estrobo => estrobo, nevoa => nevoa, cerca => cerca,
              estado => est_central,
              cmd_feito => cmd_feito, cmd_ok => cmd_ok_c,
              rest_c => rest_c, rest_d => rest_d, rest_u => rest_u);

  u_wdt : entity work.wdt_esp
    generic map (CLK_HZ => CLK_HZ)
    port map (clk => clk, rst => rst, hb => esp_hb,
              esp_ok => esp_ok, esp_rst => esp_rst, falha_esp => falha_esp);

  -- no Block Design estas duas linhas sao o IP Utility Reduced Logic (OR)
  modo_deg_i <= deg_z(0) or deg_z(1) or deg_z(2) or deg_z(3);
  teste      <= sw_s(4) or sw_s(5) or sw_s(6) or sw_s(7);

  u_gpio : entity work.gpio_esp
    generic map (CLK_HZ => CLK_HZ)
    port map (clk => clk, rst => rst,
              est_central => est_central, teste => teste, modo_deg => modo_deg_i,
              est_z => est_z, deg_z => deg_z, motivo_z => motivo_z,
              viu_r_z => viu_r_z, viu_u_z => viu_u_z, f_z => f,
              cmd_res => cmd_res, falha_esp => falha_esp,
              ack => esp_ack, dados => esp_d, sof => esp_sof, req => esp_req);

  u_disp : entity work.display
    port map (sel => sel_disp, est_central => est_central, teste => teste,
              rest_c => rest_c, rest_d => rest_d, rest_u => rest_u,
              seg => seg, dp => dp, an => an);

  -- saida "sirene" = LED de alarme: pisca rapido no disparo, lento no pre-alarme
  -- (no Block Design: Utility Vector Logic AND + OR)
  sirene   <= (disparo and rapido) or (pre_alarme and pisca);
  modo_deg <= modo_deg_i;
  cmd_ack  <= cmd_ack_i;
  cmd_ok   <= cmd_res;

  led(3 downto 0) <= al_z;
  led(7 downto 4) <= deg_z;
  led(8)  <= armada;
  led(9)  <= disparo;
  led(10) <= modo_deg_i;
  led(11) <= teste;
  led(12) <= esp_ok;
  led(13) <= falha_esp;
  led(14) <= cmd_ack_i;
  led(15) <= pisca;

end rtl;
