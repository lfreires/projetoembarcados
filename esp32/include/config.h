// config.h - pinos e tempos do firmware
#pragma once
#include <Arduino.h>

// ---------------- pinos (ESP32 DevKit V1) ----------------
// barramento FPGA -> ESP (Pmod JC da Basys 3)
#define PIN_D0        34    // JC1  (so entrada)
#define PIN_D1        35    // JC2  (so entrada)
#define PIN_D2        32    // JC3
#define PIN_D3        33    // JC4
#define PIN_SOF       25    // JC7
#define PIN_REQ       26    // JC8
#define PIN_ACK       27    // JC9  (saida)
#define PIN_MODO_DEG  14    // JC10
// comandos ESP -> FPGA (Pmod JXADC)
#define PIN_ARM_REQ   22    // JXA1 (saida)
#define PIN_DIS_REQ   23    // JXA2 (saida)
#define PIN_CMD_ACK   18    // JXA3
#define PIN_CMD_OK    19    // JXA4
// supervisao (Pmod JB)
#define PIN_HEARTBEAT 21    // JB10 (saida)
// O pino EN da ESP e puxado pelo FPGA (JB9) por um transistor NPN.

// ---------------- tempos ----------------
#define WDT_TAREFA_S        6       // task watchdog interno
#define HEARTBEAT_MS        500     // FPGA espera uma borda a cada 5 s no maximo
#define PROGRESSO_MAX_MS    3000    // sem progresso por 3 s -> para o heartbeat
#define STATUS_PERIODO_MS   60000   // mensagem de status ("estou vivo")
#define STATUS_MINIMO_MS    2000    // intervalo minimo entre status por mudanca
#define PUB_TIMEOUT_MS      10000   // espera do PUBACK (QoS 1)
#define TOKEN_VALIDADE_S    86400   // SAS token de 24 h
#define FILA_TAM            64      // eventos guardados sem Wi-Fi
#define WIFI_ESPERA_MAX_MS  60000   // teto da espera progressiva
