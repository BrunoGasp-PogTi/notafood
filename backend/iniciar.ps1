Set-Location "C:\Users\admin\notafood\backend"
& "C:\Users\admin\notafood\backend\venv\Scripts\python.exe" app_sqlite.py *>> "C:\Users\admin\notafood\backend\server.log"

# Repassa o codigo de saida do Python pro Task Scheduler, senao o
# PowerShell sempre sai com 0 e o restart automatico nunca dispara.
exit $LASTEXITCODE
