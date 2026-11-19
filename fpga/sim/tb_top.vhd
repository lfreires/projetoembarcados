-- tb_top.vhd
-- Testbench de integracao: simula a central inteira (top_central) com
-- modelos simples dos quatro HC-SR04 e da ESP32 (heartbeat, ACK dos nibbles
-- e linhas de comando). Clock de 1 MHz para a simulacao andar rapido.
--
-- Cenarios:
--   A. arme remoto pela ESP32 (ARM_REQ / CMD_ACK / CMD_OK)
--   B. zona 1: PIR + ultrassom confirmam dentro de Tcorr -> alarme normal
--   C. desarme remoto
--   D. zona 2: so o ultrassom 2 -> alarme imediato e DEG depois de Tcorr
--   E. ESP32 travada: FPGA reseta a ESP e a central continua em disparo;
--      pedido remoto com a ESP "morta" e ignorado; desarme local funciona
--
-- Tempo simulado: cerca de 9 s (rodar com "run all").
library ieee;
use ieee.std_logic_1164.all;

entity tb_top is
end tb_top;

architecture sim of tb_top is
  constant T : time := 1 us;

  signal clk : std_logic := '0';
  signal btnC, btnU, btnD, btnL, btnR : std_logic := '0';
  signal sw  : std_logic_vector(15 downto 0) := x"400F";  -- Tcorr 0,5 s, atraso 0, 4 zonas
  signal led : std_logic_vector(15 downto 0);
  signal seg : std_logic_vector(6 downto 0);
  signal dp  : std_logic;
  signal an  : std_logic_vector(3 downto 0);

  signal z1_pir, z2_reed, z3_reed : std_logic := '0';
  signal z4_ir : std_logic := '1';     -- FC-51 em repouso fica em '1'
  signal z1_trig, z2_trig, z3_trig, z4_trig : std_logic;
  signal z1_echo, z2_echo, z3_echo, z4_echo : std_logic := '0';
  signal larg1 : time := 1200 us;      -- ~20 cm
  signal larg2 : time := 1500 us;      -- ~26 cm
  signal larg3 : time := 1800 us;      -- ~31 cm
  signal larg4 : time := 2100 us;      -- ~36 cm

  signal sirene, estrobo, nevoa, cerca : std_logic;
  signal esp_rst, esp_sof, esp_req, modo_deg, cmd_ack, cmd_ok : std_logic;
  signal esp_hb, esp_ack, arm_req, disarm_req : std_logic := '0';
  signal esp_d : std_logic_vector(3 downto 0);

  type t_quadro is array (0 to 12) of std_logic_vector(3 downto 0);
  signal quadro : t_quadro := (others => "0000");
  signal n_quadros : natural := 0;
  signal hb_on : boolean := true;
  signal viu_reset_esp : boolean := false;
  signal fim : boolean := false;
begin

  clk <= not clk after T / 2 when not fim else '0';

  dut : entity work.top_central
    generic map (CLK_HZ => 1000000, BIT_SEL => 4, BIT_PISCA => 12, BIT_RAPIDO => 11)
    port map (clk => clk, btnC => btnC, btnU => btnU, btnD => btnD, btnL => btnL, btnR => btnR,
              sw => sw, led => led, seg => seg, dp => dp, an => an,
              z1_pir => z1_pir, z1_trig => z1_trig, z1_echo => z1_echo,
              z2_reed => z2_reed, z2_trig => z2_trig, z2_echo => z2_echo,
              z3_reed => z3_reed, z3_trig => z3_trig, z3_echo => z3_echo,
              z4_ir => z4_ir, z4_trig => z4_trig, z4_echo => z4_echo,
              sirene => sirene, estrobo => estrobo, nevoa => nevoa, cerca => cerca,
              esp_rst => esp_rst, esp_hb => esp_hb, esp_d => esp_d, esp_sof => esp_sof,
              esp_req => esp_req, esp_ack => esp_ack, modo_deg => modo_deg,
              arm_req => arm_req, disarm_req => disarm_req,
              cmd_ack => cmd_ack, cmd_ok => cmd_ok);

  -- modelos dos HC-SR04: eco 400 us depois do TRIG, com largura larg
  hc1 : process
  begin
    wait until falling_edge(z1_trig);
    wait for 400 us;
    z1_echo <= '1';
    wait for larg1;
    z1_echo <= '0';
  end process;

  hc2 : process
  begin
    wait until falling_edge(z2_trig);
    wait for 400 us;
    z2_echo <= '1';
    wait for larg2;
    z2_echo <= '0';
  end process;

  hc4 : process
  begin
    wait until falling_edge(z4_trig);
    wait for 400 us;
    z4_echo <= '1';
    wait for larg4;
    z4_echo <= '0';
  end process;

  hc3 : process
  begin
    wait until falling_edge(z3_trig);
    wait for 400 us;
    z3_echo <= '1';
    wait for larg3;
    z3_echo <= '0';
  end process;

  -- modelo da ESP32: heartbeat
  hb : process
  begin
    wait for 100 ms;
    if hb_on then
      esp_hb <= not esp_hb;
    end if;
    if fim then
      wait;
    end if;
  end process;

  -- modelo da ESP32: recebe os quadros
  esp : process
    variable i : natural := 0;
  begin
    wait until esp_req = '1';
    wait for 3 * T;
    if esp_sof = '1' then
      i := 0;
    end if;
    quadro(i) <= esp_d;
    esp_ack <= '1';
    wait until esp_req = '0';
    wait for 2 * T;
    esp_ack <= '0';
    if i = 12 then
      n_quadros <= n_quadros + 1;
      i := 0;
    else
      i := i + 1;
    end if;
  end process;

  process(esp_rst)
  begin
    if rising_edge(esp_rst) then
      viu_reset_esp <= true;
    end if;
  end process;

  estimulo : process

    procedure comando(signal linha : out std_logic; esperado : in std_logic; nome : in string) is
    begin
      linha <= '1';
      wait until cmd_ack = '1' for 200 ms;
      assert cmd_ack = '1' report nome & ": sem CMD_ACK" severity error;
      assert cmd_ok = esperado report nome & ": CMD_OK diferente do esperado" severity error;
      linha <= '0';
      wait until cmd_ack = '0' for 200 ms;
      assert cmd_ack = '0' report nome & ": CMD_ACK nao baixou" severity error;
      report nome & " conferido";
    end procedure;

  begin
    btnC <= '1';
    wait for 50 us;
    btnC <= '0';

    -- espera diagnostico (0,5 s), calibracao do d0 e heartbeat
    wait for 800 ms;
    assert led(12) = '1' report "ESP deveria estar viva (LED12)" severity error;
    assert led(8) = '0'  report "deveria comecar desarmado" severity error;
    assert n_quadros > 0 report "nenhum quadro recebido" severity error;

    -- A. arme remoto
    comando(arm_req, '1', "A arme remoto");
    assert led(8) = '1' report "A: nao armou" severity error;

    -- B. zona 1: PIR detecta e a distancia muda
    z1_pir <= '1';
    larg1   <= 600 us;
    wait for 80 ms;                     -- filtro do PIR = 50 ms
    assert estrobo = '1' and estrobo = '1' and cerca = '1' and nevoa = '1'
      report "B: saidas nao acionaram" severity error;
    assert led(0) = '1' and led(4) = '0' report "B: AL_Z1 = 1 e DEG_Z1 = 0" severity error;
    wait for 700 ms;
    assert led(4) = '0' and modo_deg = '0' report "B: nao deveria degradar (confirmou)" severity error;
    assert quadro(2) = "0100" report "B: quadro Z1 deveria ser AL_NORMAL" severity error;
    assert quadro(3) = "0011" report "B: quadro Z1 evidencias R e U" severity error;
    assert quadro(1)(3 downto 2) = "11" report "B: quadro central em DISPARO" severity error;
    -- o LED de alarme (saida sirene) tem que piscar no disparo
    wait until sirene = '1' for 10 ms;
    assert sirene = '1' report "B: LED de alarme nao acendeu" severity error;
    wait until sirene = '0' for 10 ms;
    assert sirene = '0' report "B: LED de alarme nao pisca" severity error;
    report "B alarme confirmado conferido";

    -- C. desarme remoto
    comando(disarm_req, '1', "C desarme remoto");
    assert estrobo = '0' and led(8) = '0' report "C: nao desarmou" severity error;
    z1_pir <= '0';
    larg1   <= 1200 us;
    wait for 400 ms;

    -- D. zona 2: so o ultrassom 2 (distancia muda, janela continua fechada)
    comando(arm_req, '1', "D arme remoto");
    larg2 <= 2600 us;
    wait for 250 ms;                    -- 3 medidas seguidas fora da faixa
    assert estrobo = '1' and led(1) = '1' and led(5) = '0'
      report "D: alarme imediato sem DEG" severity error;
    wait for 600 ms;
    assert led(5) = '1' and modo_deg = '1' report "D: deveria degradar apos Tcorr" severity error;
    wait for 50 ms;
    assert quadro(4) = "1101" report "D: quadro Z2 deveria ser DEG + AL_DEG" severity error;
    assert quadro(5) = "0110" report "D: quadro Z2 motivo Tcorr + viu_U" severity error;
    report "D alarme degradado conferido";

    -- E. ESP32 travada
    hb_on <= false;
    wait for 5300 ms;
    assert viu_reset_esp report "E: FPGA nao resetou a ESP" severity error;
    assert led(12) = '0' report "E: ESP deveria constar como fora" severity error;
    assert estrobo = '1' report "E: central parou sem a ESP" severity error;
    disarm_req <= '1';                  -- pedido remoto com a ESP morta
    wait for 100 ms;
    assert estrobo = '1' and cmd_ack = '0' report "E: aceitou comando indevido" severity error;
    disarm_req <= '0';
    btnD <= '1';                        -- desarme local continua valendo
    wait for 40 ms;
    btnD <= '0';
    wait for 5 ms;
    assert estrobo = '0' and led(8) = '0' report "E: desarme local falhou" severity error;
    report "E watchdog externo e operacao local conferidos";

    report "TB_TOP OK";
    fim <= true;
    wait;
  end process;

end sim;
