# Central de alarme perimétrico de 4 zonas em FPGA

Projeto final de **Sistemas Embarcados** - Engenharia da Computação - Universidade Presbiteriana Mackenzie - Prof. Newton Licciardi - 2º semestre de 2026.

**Grupo:** Guilherme Meira (TIA 10401198) e Lucas Freires (TIA 10419841)

**Palavras-chave:** sistemas embarcados, FPGA, Artix-7, Basys 3, VHDL, Vivado, IP Integrator, máquina de estados, ESP32, MQTT, TLS, Azure IoT Hub, IoT, alarme perimétrico, React, PWA.

**Vídeo no YouTube:** _[colocar o link aqui]_

---

## O que é

Uma central de alarme residencial com quatro zonas. A central fica em um FPGA (Basys 3) e decide tudo sozinha, mesmo sem internet.

- Cada zona tem **dois sensores diferentes** e uma **máquina de estados**. Qualquer sensor dispara o alarme na hora. Se o segundo não confirmar dentro de Tcorr, a zona entra em **modo degradado** e avisa que a cobertura está reduzida.
- Uma **MEF central** aplica o atraso (0 a 120 s) e aciona sirene, estrobo de 10 W, névoa de água e a interface isolada da cerca.
- Uma **ESP32** lê o estado do FPGA por GPIO, guarda os eventos em fila e publica por **MQTT com TLS** no Azure IoT Hub. Tem watchdog interno e é vigiada pelo FPGA.
- Um **backend** grava o histórico, manda **alertas por e-mail e WhatsApp dizendo quais zonas foram violadas**, calcula estatísticas e dá nota de falso-positivo.
- Um **aplicativo** (PWA em React) mostra o painel no PC e no celular, e um **agente** responde por texto ou voz e pede arme e desarme.

![Arquitetura](docs/figuras/arquitetura.png)

| Zona | Local | Sensor A | Sensor B |
|---|---|---|---|
| Z1 | Ambiente 1 | reed na janela | ultrassônico HC-SR04 |
| Z2 | Ambiente 2 | PIR HC-SR501 | ultrassônico HC-SR04 |
| Z3 | Ambiente 3 | PIR HC-SR501 | ultrassônico HC-SR04 |
| Z4 | Quintal | IR de obstáculo FC-51 na cerca da frente | ultrassônico HC-SR04 na portinhola |

## Pastas

```
fpga/
  src/        VHDL: MEFs, sensores, interface com a ESP32, watchdog, display, topo
  sim/        testbenches (tb_mef_zona, tb_mef_central, tb_gpio_esp, tb_wdt_esp, tb_top)
  constr/     basys3_central.xdc (pinos)
  scripts/    cria_projeto.tcl (Block Design), simula.tcl, gera_bitstream.tcl
esp32/        firmware (PlatformIO)
backend/      API em Flask, banco, alertas, estatísticas, agente, central simulada
app/          aplicativo React (PWA). app/dist já vem pronto
modelo/       modelo de referência das MEFs em Python + testes
docs/         relatório, apresentação, figuras, montagem passo a passo, roteiro do vídeo
```

## Como rodar

### 0. No GitHub Codespaces (sem instalar nada)

1. No repositório, clicar em **Code → Codespaces → Create codespace on main**.
2. Esperar a criação (uns 2 a 3 minutos). Ela instala o Python e o Node, as dependências, e gera o `app/dist`.
3. No terminal:

```
cd backend
python app.py
```

4. O Codespace abre a porta 8000 sozinho. Se não abrir, vá na aba **Portas** e clique no globo da porta 8000.
5. Login: `admin@exemplo.com`, senha `admin`, PIN `1234`.

Os testes rodam no mesmo terminal: `python -m pytest modelo -q` e `cd backend && python -m pytest -q`.

### 1. Só o aplicativo, sem placa (2 minutos)

O backend tem uma central simulada que gera as mesmas mensagens da ESP32.

```
cd backend
pip install -r requirements.txt
python app.py
```

Abrir <http://localhost:8000>. Login: `admin@exemplo.com`, senha `admin`, PIN `1234` (mudar no arquivo `.env`, modelo em `.env.example`). Em **Ajustes** aparecem os sensores da central simulada.

### 2. FPGA

No Tcl Console do Vivado:

```
cd C:/caminho/alarme-perimetrico-fpga/fpga
source scripts/cria_projeto.tcl
source scripts/gera_bitstream.tcl
```

O primeiro script cria o projeto e monta o Block Design. Para rodar os cinco testbenches de uma vez: `vivado -mode batch -source scripts/simula.tcl`.

### 3. ESP32

Abrir a pasta `esp32/` no VS Code com PlatformIO, copiar `include/secrets.example.h` para `include/secrets.h`, preencher Wi-Fi e os dados do IoT Hub e gravar.

### 4. Nuvem

Criar o IoT Hub no plano gratuito F1, cadastrar o dispositivo e preencher o `.env` do backend com `SIMULADOR=0`. O passo a passo completo está em [docs/montagem_passo_a_passo.md](docs/montagem_passo_a_passo.md).

## Testes

| O que | Comando | Situação |
|---|---|---|
| Modelo das MEFs (Python) | `python -m pytest modelo -q` | 19 testes passando |
| Backend com central simulada | `cd backend && python -m pytest -q` | 16 testes passando |
| Testbenches VHDL | `vivado -mode batch -source fpga/scripts/simula.tcl` | ver relatório, capítulo 7 |
| Roteiro de aceitação em bancada | relatório, seção 7.4 | ver relatório |

## Documentação

- [Relatório (PDF)](docs/Relatorio_Projeto_Final.pdf) e [Word](docs/Relatorio_Projeto_Final.docx)
- [Apresentação](docs/Apresentacao_Projeto_Final.pptx)
- [Montagem e configuração passo a passo](docs/montagem_passo_a_passo.md)
- [Roteiro do vídeo](docs/roteiro_video.md)
- Capítulos do relatório em Markdown: [docs/relatorio/](docs/relatorio/)

## Segurança

- Os 12 V ficam só no estágio de potência, isolados do FPGA por optoacopladores.
- A cerca é só uma interface isolada (relé) para energizador comercial. Não há circuito de alta tensão neste projeto.
- A névoa usa apenas água. O estrobo fica confinado e nunca apontado para pessoas.
- Os testes de contramedidas são feitos no laboratório, com o professor.
- Senhas e chaves ficam em `secrets.h` e `.env`, que não vão para o repositório.

## Licença

MIT. Ver [LICENSE](LICENSE).
