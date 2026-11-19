"""Configuracao do backend, lida do arquivo .env (ou das variaveis de ambiente)."""
import os

try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
except ImportError:          # sem python-dotenv: usa so as variaveis de ambiente
    pass


def _env(nome, padrao=""):
    return os.environ.get(nome, padrao).strip()


BANCO = _env("BANCO", os.path.join(os.path.dirname(__file__), "alarme.db"))
SECRET_KEY = _env("SECRET_KEY", "dev-nao-usar-em-producao-troque-no-arquivo-env")
ADMIN_EMAIL = _env("ADMIN_EMAIL", "admin@exemplo.com")
ADMIN_SENHA = _env("ADMIN_SENHA", "admin")
ADMIN_PIN = _env("ADMIN_PIN", "1234")

SIMULADOR = _env("SIMULADOR", "1") == "1"
IOTHUB_SERVICE_CONN = _env("IOTHUB_SERVICE_CONN")
IOTHUB_EVENTHUB_CONN = _env("IOTHUB_EVENTHUB_CONN")
DEVICE_ID = _env("DEVICE_ID", "central01")

SMTP_HOST = _env("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(_env("SMTP_PORT", "587"))
SMTP_USER = _env("SMTP_USER")
SMTP_SENHA = _env("SMTP_SENHA")
TELEGRAM_TOKEN = _env("TELEGRAM_TOKEN")

OLLAMA_URL = _env("OLLAMA_URL")
OLLAMA_MODELO = _env("OLLAMA_MODELO", "llama3.2")

ZONAS = {
    1: _env("ZONA1", "Ambiente 1 (PIR + ultrassom)"),
    2: _env("ZONA2", "Ambiente 2 (porta + ultrassom)"),
    3: _env("ZONA3", "Ambiente 3 (PIR + ultrassom)"),
    4: _env("ZONA4", "Quintal (IR + ultrassom)"),
}
# nome dos dois sensores de cada zona (sensor A = "R", sensor B = "U" no FPGA)
SENSORES = {
    1: ("PIR", "ultrassonico"),
    2: ("reed da porta", "ultrassonico"),
    3: ("PIR", "ultrassonico"),
    4: ("IR de obstaculo", "ultrassonico"),
}

VALIDADE_COMANDO_S = 15      # o comando vence depois disso
TIMEOUT_COMANDO_S = 10       # espera pela resposta da central
ESTADO_VELHO_S = 150         # sem status por mais que isso = "sem conexao"
LIMITE_MSG_DIA = 8000        # cota do IoT Hub F1
