# Montagem e configuração passo a passo

Este guia permite reproduzir o projeto do zero. Custo de nuvem: R$ 0.

## Parte 1. Testar o software sem nenhuma placa

1. Instalar o Python 3.10 ou mais novo (python.org). No Windows, marcar "Add Python to PATH".
2. Abrir um terminal na pasta do projeto e rodar:
   ```
   python -m pip install -r backend/requirements.txt pytest
   python -m pytest modelo -q
   cd backend
   python -m pytest -q
   python app.py
   ```
3. Abrir <http://localhost:8000> e entrar com `admin@exemplo.com` / `admin`.
4. Em **Ajustes > Central simulada** marcar e desmarcar os sensores. Em **Painel**, armar. Marcar o sensor A da zona 1 e ver o disparo, o histórico e o alerta.

## Parte 2. FPGA (no laboratório, com a Basys 3)

1. Copiar a pasta do projeto para o PC do laboratório. Evitar caminho com espaço ou acento (ex.: `C:/proj/alarme-perimetrico-fpga`).
2. **Simular primeiro.** Abrir o "Vivado Tcl Shell" e rodar:
   ```
   cd C:/proj/alarme-perimetrico-fpga/fpga
   vivado -mode batch -source scripts/simula.tcl
   ```
   Tem que aparecer `OK` nos cinco testbenches. O `tb_top` simula 9 segundos e demora alguns minutos.
3. **Criar o projeto.** Abrir o Vivado e, no Tcl Console:
   ```
   cd C:/proj/alarme-perimetrico-fpga/fpga
   source scripts/cria_projeto.tcl
   ```
   O diagrama abre montado. Conferir em *Validate Design* (F6).
4. **Gerar o bitstream:** `source scripts/gera_bitstream.tcl`. No final o console mostra o WNS, que precisa ser positivo. Os relatórios ficam em `docs/relatorios_vivado/`.
5. **Gravar:** *Open Hardware Manager > Open Target > Auto Connect > Program Device*.
6. **Teste rápido só com a placa** (sem sensores): SW0 para cima e SW3..1 para baixo (só a zona 1 habilitada; os LEDs 5 a 7 acendem porque as outras estão isoladas), SW4 para cima (zona 1 em teste) e SW15..14 = 11 (Tcorr de 2 s). Apertar BTNU: o display mostra `A`. Subir SW8: o LED0 acende e o display mostra `U`; depois de 2 s o LED4 acende (degradado). BTND desarma.
7. **Plano B sem Block Design:** criar um projeto RTL comum, adicionar todos os arquivos de `src/` e o XDC, e definir `top_central` como topo.

## Parte 3. Central de cabos e sensores

1. Montar a placa da central de cabos com quatro conectores de barra de pinos 2×6 para JA, JB, JC e JXADC, seguindo a tabela de pinos do relatório (seção 3.3) ou o arquivo `fpga/constr/basys3_central.xdc`.
2. Divisor do ECHO de cada HC-SR04: 1 kΩ entre o ECHO e o pino do FPGA, 2 kΩ do pino do FPGA para o GND.
3. Reed: um terminal no pino do FPGA, o outro no GND. O pull-up é interno.
4. Alimentar os sensores com 5 V do regulador. **Unir os GNDs** da fonte, do FPGA e da ESP32.
5. Um cabo UTP por zona, etiquetado nas duas pontas (Z1 a Z4).
6. O IR FC-51 vai alimentado em 3,3 V (pino 6 do Pmod) e a saída dele vai a 0 quando detecta (`IR_ATV = 0` em `fpga/src/sensores.vhd`). Se o de vocês funcionar ao contrário, mude `IR_ATV` para 1 (no Block Design, duplo clique no bloco `sensores_0`).
7. Com o cômodo vazio, apertar **BTNR** para calibrar a distância de referência dos ultrassônicos.

## Parte 4. Estágio de potência

Circuitos e cálculos no relatório, capítulo 4. Ordem sugerida:

1. Montar um canal (PC817 + IRF540N) e testar com um LED comum e resistor no lugar da carga.
2. Sirene no canal 1.
3. Estrobo: montar o 555, medir a frequência no pino 3 com o osciloscópio e só então ligar o LED de 10 W com o resistor de 1,8 Ω / 5 W.
4. Bomba no canal 3, com o diodo e o capacitor. Reservatório longe das placas.
5. Módulo de relé na saída `cerca`, com uma lâmpada de 12 V no contato.

Ligar os 12 V por último e sempre com o professor ou o técnico presente nos testes das contramedidas.

## Parte 5. Azure IoT Hub (gratuito)

1. Entrar em <https://portal.azure.com> com a conta de estudante.
2. *Create a resource > IoT Hub*. Escolher um nome (ex.: `alarme-mack-g`), região *Brazil South* e, em *Tier*, **Free (F1)**. Criar.
   O F1 não gasta crédito. Só é permitido um hub gratuito por assinatura e o limite é de 8 000 mensagens por dia.
3. No hub, *Device management > Devices > Add Device*. Device ID: `central01`. Autenticação por chave simétrica, chaves geradas automaticamente. Salvar.
4. Abrir o dispositivo e copiar a **Primary key** (vai no `secrets.h` da ESP32).
5. *Security settings > Shared access policies > service* e copiar a **Primary connection string** (vai em `IOTHUB_SERVICE_CONN` no `.env`).
6. *Hub settings > Built-in endpoints* e copiar o **Event Hub-compatible endpoint** (vai em `IOTHUB_EVENTHUB_CONN` no `.env`).

Depois da apresentação o hub pode ser apagado (*Delete*). Enquanto estiver no F1 ele não gera cobrança.

## Parte 6. ESP32

1. Instalar o VS Code e a extensão **PlatformIO IDE**.
2. *File > Open Folder* e escolher a pasta `esp32/`.
3. Copiar `include/secrets.example.h` para `include/secrets.h` e preencher:
   - `WIFI_SSID` e `WIFI_SENHA` (rede de 2,4 GHz; pode ser o roteador do celular);
   - `IOTHUB_HOST`: `nome-do-hub.azure-devices.net`;
   - `DEVICE_ID`: `central01`;
   - `DEVICE_KEY`: a Primary key do passo 5.4.
4. Ligar a ESP32 no USB e clicar em *Upload* (seta na barra de baixo). A primeira compilação baixa as bibliotecas.
5. Abrir o *Serial Monitor* (115200). Deve aparecer `Wi-Fi ok` e `MQTT conectado ao IoT Hub`.
6. Ligar a ESP32 ao FPGA conforme a tabela:

| ESP32 | Basys 3 | Sinal |
|---|---|---|
| GPIO34, 35, 32, 33 | JC1, JC2, JC3, JC4 | DADOS 0 a 3 |
| GPIO25 | JC7 | SOF |
| GPIO26 | JC8 | REQ |
| GPIO27 | JC9 | ACK |
| GPIO14 | JC10 | MODO_DEGRADADO |
| GPIO16 | JXA1 | ARM_REQ |
| GPIO17 | JXA2 | DISARM_REQ |
| GPIO18 | JXA3 | CMD_ACK |
| GPIO19 | JXA4 | CMD_OK |
| GPIO21 | JB10 | HEARTBEAT |
| EN | JB9, pelo transistor BC547 | reset |
| GND | GND de qualquer Pmod | terra comum |

Com tudo ligado, o LED12 da Basys 3 acende (ESP32 viva).

## Parte 7. Backend ligado na central de verdade

1. Na pasta `backend/`, copiar `.env.example` para `.env` e preencher. Trocar `SIMULADOR=1` por `SIMULADOR=0` e colar as duas strings do Azure. Trocar a senha, o PIN e a `SECRET_KEY`.
2. `python app.py`. O terminal mostra "modo AZURE IoT HUB" e "lendo eventos do IoT Hub".
3. Abrir o painel: o estado mostrado é o da placa. Mexer em um sensor e conferir o histórico.

## Parte 8. Alertas (gratuitos)

- **E-mail (Gmail):** ativar a verificação em duas etapas na conta, criar uma senha de app em <https://myaccount.google.com/apppasswords> e preencher `SMTP_USER` e `SMTP_SENHA` no `.env`.
- **WhatsApp (CallMeBot):** seguir a ativação descrita em <https://www.callmebot.com/blog/free-api-whatsapp-messages/> (adicionar o número do bot, mandar a mensagem de autorização e receber a chave). No aplicativo, em **Ajustes**, cadastrar o contato com o número no formato `+5511999990000` e a chave recebida.
- **Telegram (opcional):** criar um bot no @BotFather, colocar o token em `TELEGRAM_TOKEN` e cadastrar o chat ID no contato.
- Em **Ajustes**, usar **Enviar alerta de teste** e conferir em **Histórico > Alertas enviados**.

## Parte 9. Abrir no celular

O reconhecimento de voz e a instalação do aplicativo só funcionam em endereço seguro (HTTPS). Duas formas gratuitas:

- **Túnel:** instalar o `cloudflared` e rodar `cloudflared tunnel --url http://localhost:8000`. Ele mostra um endereço `https://....trycloudflare.com` que abre em qualquer celular.
- **Mesma rede Wi-Fi, sem voz:** abrir `http://IP-DO-PC:8000` no celular. O painel funciona; a voz não.

No Chrome do celular: menu > *Adicionar à tela inicial*.

## Parte 10. Agente com modelo local (opcional)

1. Instalar o Ollama (<https://ollama.com>) no PC do grupo.
2. `ollama pull llama3.2`
3. Conferir `OLLAMA_URL=http://localhost:11434` no `.env` e reiniciar o backend.

Sem o Ollama o agente continua funcionando no modo por regras.

## Mudar o aplicativo

O aplicativo pronto está em `app/dist`. Para alterar e gerar de novo é preciso o Node.js:

```
cd app
npm install
npm run build
```
