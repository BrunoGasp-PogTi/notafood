Set-Location "C:\Projetos\notafood\backend"
$env:GEMINI_API_KEY = "AIzaSyDTlyRRgfFXjpWMehOhHwghAtrZZ4Ki72g"
& "C:\Program Files\Python311\python.exe" app_sqlite.py *>> "C:\Projetos\notafood\backend\server.log"
exit $LASTEXITCODE
