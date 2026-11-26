"""
Ligacao do backend com a central pelo Azure IoT Hub (plano F1, gratuito).

  * LER eventos: o IoT Hub entrega as mensagens da ESP32 no "Built-in endpoint",
    que e compativel com Event Hub. Uma thread fica lendo e chama ingestao.processa.
  * MANDAR comando: direct method "comando" pela API REST do IoT Hub. A chamada
    so retorna quando a ESP32 responde (ou quando vence o tempo), entao o painel
    sabe se a central confirmou, recusou ou nao respondeu.
"""
import base64
import hashlib
import hmac
import json
import threading
import time
import urllib.parse
from datetime import datetime, timezone

import requests

import config
import db
import ingestao

API = "2021-04-12"


def _partes(conn):
    """'HostName=a;SharedAccessKeyName=b;SharedAccessKey=c' -> dict"""
    return dict(p.split("=", 1) for p in conn.split(";") if "=" in p)


def sas_token(host, chave_b64, politica, validade_s=3600, agora=None):
    """SAS token de servico: assina '<host>\\n<expira>' com HMAC-SHA256."""
    expira = int(agora if agora is not None else time.time()) + validade_s
    recurso = urllib.parse.quote(host, safe="")
    assinatura = hmac.new(base64.b64decode(chave_b64), f"{recurso}\n{expira}".encode(),
                          hashlib.sha256).digest()
    sig = urllib.parse.quote(base64.b64encode(assinatura), safe="")
    return f"SharedAccessSignature sr={recurso}&sig={sig}&se={expira}&skn={politica}"


class AzureTransporte:
    nome = "azure"

    def __init__(self):
        p = _partes(config.IOTHUB_SERVICE_CONN)
        self.host = p["HostName"]
        self.politica = p["SharedAccessKeyName"]
        self.chave = p["SharedAccessKey"]

    def comando(self, payload):
        """Devolve (resultado, detalhe). resultado: confirmado | recusado | expirado |
        sem_resposta_fpga | sem_conexao | erro"""
        url = f"https://{self.host}/twins/{config.DEVICE_ID}/methods?api-version={API}"
        corpo = {"methodName": "comando", "responseTimeoutInSeconds": config.TIMEOUT_COMANDO_S,
                 "connectTimeoutInSeconds": 5, "payload": payload}
        try:
            r = requests.post(url, json=corpo, timeout=config.TIMEOUT_COMANDO_S + 10,
                              headers={"Authorization": sas_token(self.host, self.chave, self.politica)})
            # hubs novos exigem o endereco <hub>.service.azure-devices.net para operacoes de servico
            if r.status_code == 400 and "service hostname" in r.text and ".service." not in self.host:
                self.host = self.host.replace(".azure-devices.net", ".service.azure-devices.net")
                print("[azure] usando o endereco de servico", self.host)
                return self.comando(payload)
        except requests.RequestException as e:
            return "erro", f"sem acesso ao IoT Hub: {e}"
        if r.status_code == 200:
            resp = r.json().get("payload") or {}
            return resp.get("resultado", "erro"), "resposta da central"
        if r.status_code in (404, 504):
            return "sem_conexao", "a central nao esta conectada ou nao respondeu no prazo"
        return "erro", f"IoT Hub respondeu HTTP {r.status_code}: {r.text[:200]}"

    def inicia(self):
        if not config.IOTHUB_EVENTHUB_CONN:
            print("[azure] IOTHUB_EVENTHUB_CONN vazio: nao vou ler eventos")
            return
        threading.Thread(target=self._coletor, daemon=True).start()

    def _coletor(self):
        from azure.eventhub import EventHubConsumerClient

        def ao_receber(particao, evento):
            if evento is None:
                return
            try:
                disp = (evento.system_properties or {}).get(b"iothub-connection-device-id", b"").decode()
                if disp and disp != config.DEVICE_ID:
                    return
                bruto = evento.body_as_str()
                ingestao.processa(json.loads(bruto), len(bruto))
                if evento.enqueued_time:
                    db.meta_grava("ultimo_enfileirado", evento.enqueued_time.timestamp())
            except Exception as e:                      # mensagem estranha nao derruba o coletor
                print("[azure] mensagem ignorada:", e)

        while True:
            try:
                # retoma de onde parou (mensagens repetidas sao descartadas pelo event_id)
                ultimo = db.meta_le("ultimo_enfileirado")
                inicio = datetime.fromtimestamp(float(ultimo), timezone.utc) if ultimo else "@latest"
                cliente = EventHubConsumerClient.from_connection_string(
                    config.IOTHUB_EVENTHUB_CONN, consumer_group="$Default")
                print("[azure] lendo eventos do IoT Hub...")
                with cliente:
                    cliente.receive(on_event=ao_receber, starting_position=inicio)
            except Exception as e:
                print("[azure] coletor caiu, tentando de novo em 10 s:", e)
                time.sleep(10)


def cria():
    if config.SIMULADOR or not config.IOTHUB_SERVICE_CONN:
        import simulador
        return simulador.Simulador()
    return AzureTransporte()
