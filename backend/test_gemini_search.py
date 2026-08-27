import requests
import json

key = 'AIzaSyDTlyRRgfFXjpWMehOhHwghAtrZZ4Ki72g'
url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}'

prompt = """Voce e um assistente nutricional. Busque na web informacoes sobre o codigo de barras EAN/GTIN 7891164029074 ou Batata Crinkle Aurora Congelada.
Encontre o nome oficial, marca, ingredientes e valores nutricionais por 100g.

Responda APENAS em formato JSON:
{
  "nome": "string",
  "marca": "string",
  "quantidade": "string",
  "ingredientes": "string",
  "nova": 1, 2, 3 ou 4,
  "acucar_100g": float ou null,
  "gordura_saturada_100g": float ou null,
  "sal_100g": float ou null,
  "fibra_100g": float ou null,
  "proteina_100g": float ou null
}"""

payload = {
    "contents": [{"parts": [{"text": prompt}]}],
    "tools": [{"googleSearch": {}}],
    "generationConfig": {
        "response_mime_type": "application/json"
    }
}

r = requests.post(url, json=payload, timeout=25)
print('STATUS:', r.status_code)
if r.status_code == 200:
    data = r.json()
    part = data['candidates'][0]['content']['parts'][0]
    print('RESULTADO:', part.get('text'))
else:
    print('ERRO:', r.text)
