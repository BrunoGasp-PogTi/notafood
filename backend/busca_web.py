import requests
import re
from bs4 import BeautifulSoup

def buscar_produto_web(codigo):
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
    try:
        r = requests.post(
            'https://html.duckduckgo.com/html/',
            data={'q': f'"{codigo}"'},
            headers=headers,
            timeout=5
        )
        if r.status_code == 200:
            soup = BeautifulSoup(r.text, 'html.parser')
            for a in soup.select('.result__title'):
                texto = a.text.strip()
                m = re.search(r'^(.*?)\s*[-|–]\s*(?:GTIN|EAN|UPC|Cosmos|Preço|Comprar)', texto, re.IGNORECASE)
                if m and len(m.group(1).strip()) > 3:
                    return m.group(1).strip()
                if codigo in texto:
                    limpo = texto.replace(codigo, '').replace('-', '').strip()
                    if len(limpo) > 4:
                        return limpo
    except Exception as e:
        print(f"Erro busca web: {e}")
    return None

if __name__ == '__main__':
    for cod in ['7891164029074', '7897844304165', '7891515634186']:
        print(f"{cod} -> {buscar_produto_web(cod)}")
