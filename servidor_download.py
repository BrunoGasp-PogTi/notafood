import os
import socket
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

PORT = 8080
APK_PATH = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        "app",
        "build",
        "app",
        "outputs",
        "flutter-apk",
        "app-debug.apk",
    )
)

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

LOCAL_IP = get_local_ip()
DOWNLOAD_URL = f"http://{LOCAL_IP}:{PORT}/download"

HTML_TEMPLATE = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NotaFood — Baixar Aplicativo</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
  <style>
    * {{
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      font-family: 'Plus Jakarta Sans', sans-serif;
    }}
    body {{
      background: #F8FAFC;
      color: #0F172A;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 30px 16px 50px;
    }}
    .card {{
      background: #FFFFFF;
      max-width: 480px;
      width: 100%;
      border-radius: 28px;
      box-shadow: 0 10px 40px -10px rgba(0, 0, 0, 0.08);
      border: 1px solid #E2E8F0;
      padding: 32px 24px;
      text-align: center;
    }}
    .logo-container {{
      width: 84px;
      height: 84px;
      background: #ECFDF5;
      border: 2px solid #A7F3D0;
      border-radius: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 20px;
      font-size: 42px;
      box-shadow: 0 8px 20px -6px rgba(16, 185, 129, 0.25);
    }}
    h1 {{
      font-size: 26px;
      font-weight: 800;
      color: #0F172A;
      letter-spacing: -0.5px;
      margin-bottom: 6px;
    }}
    .subtitle {{
      color: #64748B;
      font-size: 14.5px;
      line-height: 1.4;
      margin-bottom: 24px;
    }}
    .badge {{
      display: inline-block;
      background: #D1FAE5;
      color: #065F46;
      font-size: 12px;
      font-weight: 700;
      padding: 4px 12px;
      border-radius: 20px;
      margin-bottom: 24px;
    }}
    .btn-download {{
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      background: #059669;
      color: #FFFFFF;
      text-decoration: none;
      font-size: 16px;
      font-weight: 700;
      padding: 16px 24px;
      border-radius: 18px;
      box-shadow: 0 10px 25px -5px rgba(5, 150, 105, 0.4);
      transition: all 0.2s ease;
      margin-bottom: 28px;
    }}
    .btn-download:hover {{
      background: #047857;
      transform: translateY(-2px);
      box-shadow: 0 12px 30px -5px rgba(5, 150, 105, 0.5);
    }}
    .btn-download:active {{
      transform: translateY(0);
    }}
    .qr-section {{
      background: #F8FAFC;
      border: 1px solid #E2E8F0;
      border-radius: 20px;
      padding: 20px;
      margin-bottom: 24px;
    }}
    .qr-title {{
      font-size: 13.5px;
      font-weight: 700;
      color: #334155;
      margin-bottom: 12px;
    }}
    #qrcode {{
      display: inline-block;
      padding: 10px;
      background: #FFFFFF;
      border-radius: 14px;
      border: 1px solid #E2E8F0;
    }}
    .steps {{
      text-align: left;
      background: #F1F5F9;
      border-radius: 18px;
      padding: 18px 20px;
    }}
    .steps h3 {{
      font-size: 14px;
      font-weight: 800;
      color: #1E293B;
      margin-bottom: 10px;
    }}
    .steps ol {{
      padding-left: 18px;
      font-size: 13px;
      color: #475569;
      line-height: 1.6;
    }}
    .footer {{
      margin-top: 24px;
      font-size: 12px;
      color: #94A3B8;
    }}
  </style>
</head>
<body>
  <div class="card">
    <div class="logo-container">🥗</div>
    <h1>NotaFood</h1>
    <p class="subtitle">Análise Nutricional Inteligente & Saúde dos Alimentos</p>
    
    <div>
      <span class="badge">Versão Android (APK) • Debug</span>
    </div>

    <a href="/download" class="btn-download">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
        <polyline points="7 10 12 15 17 10"></polyline>
        <line x1="12" y1="15" x2="12" y2="3"></line>
      </svg>
      Baixar NotaFood.apk
    </a>

    <div class="qr-section">
      <div class="qr-title">📱 Ou aponte a câmera do celular para baixar:</div>
      <div id="qrcode"></div>
    </div>

    <div class="steps">
      <h3>📋 Como instalar no Android:</h3>
      <ol>
        <li>Toque no botão <b>Baixar</b> ou escaneie o QR Code acima.</li>
        <li>Ao terminar o download, abra o arquivo <b>NotaFood.apk</b>.</li>
        <li>Se o Android solicitar, permita a instalação de fontes desconhecidas no navegador.</li>
        <li>Toque em <b>Instalar</b> e abra o aplicativo!</li>
      </ol>
    </div>
  </div>

  <div class="footer">
    Servidor Local: <b>http://{LOCAL_IP}:{PORT}</b>
  </div>

  <script>
    new QRCode(document.getElementById("qrcode"), {{
      text: "{DOWNLOAD_URL}",
      width: 160,
      height: 160,
      colorDark : "#0F172A",
      colorLight : "#FFFFFF",
      correctLevel : QRCode.CorrectLevel.M
    }});
  </script>
</body>
</html>
"""

class DownloadHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")

    def do_GET(self):
        parsed = urlparse(self.path)
        
        if parsed.path == "/" or parsed.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_TEMPLATE.encode("utf-8"))
            return

        elif parsed.path == "/download" or parsed.path.endswith(".apk"):
            if not os.path.exists(APK_PATH):
                self.send_response(404)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"Arquivo APK não encontrado em: {APK_PATH}".encode("utf-8"))
                return

            file_size = os.path.getsize(APK_PATH)
            self.send_response(200)
            self.send_header("Content-Type", "application/vnd.android.package-archive")
            self.send_header("Content-Disposition", 'attachment; filename="NotaFood.apk"')
            self.send_header("Content-Length", str(file_size))
            self.end_headers()

            with open(APK_PATH, "rb") as f:
                while chunk := f.read(64 * 1024):
                    self.wfile.write(chunk)
            return

        else:
            self.send_response(404)
            self.end_headers()

def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

    print("=" * 65)
    print(" SERVIDOR DE DOWNLOAD DO NOTAFOOD INICIADO COM SUCESSO!")
    print("=" * 65)
    print(f" Acesse pelo navegador do celular ou PC na mesma rede Wi-Fi:")
    print(f" -> http://{LOCAL_IP}:{PORT}")
    print(f" Link direto do APK: http://{LOCAL_IP}:{PORT}/download")
    print(f" Arquivo servido: {APK_PATH}")
    print("=" * 65)
    print(" Pressione Ctrl+C para encerrar o servidor a qualquer momento.\n")

    server = HTTPServer(("0.0.0.0", PORT), DownloadHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor encerrado.")
        server.server_close()

if __name__ == "__main__":
    main()
