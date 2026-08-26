# Changelog - NotaFood

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.
O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/) e este projeto segue [Semantic Versioning](https://semver.org/).

## [1.2.1] - 2026-08-26

### 🐛 Correções de Estabilidade
- **Correção no Pipeline da Câmera (Scanner):**
  - Removido o ciclo destrutivo de parada/reabertura do `MobileScannerController` durante transições de tela.
  - Implementado sistema de debounce e cooldown de 1 segundo para evitar re-leituras indesejadas e manter a câmera sempre responsiva e fluida após múltiplos scans contínuos.

---

## [1.1.0] - 2026-08-26

### 🚀 Infraestrutura & Domínio de Produção
- **Domínio Oficial Configurado:** `https://notafood.pogti.com.br` como endereço base padrão de produção.
- **Backend Otimizado com Gunicorn & ProxyFix:** Suporte a proxy reverso com SSL/TLS (Nginx/Cloudflare/Caddy).
- **Portal Web e Rota de Download Direto:** Rotas `/`, `/download` e `/health` para monitoramento e distribuição simplificada do APK.
- **Arquitetura Leve de Processamento no Servidor:** O celular envia os dados e recebe a análise nutricional pronta, economizando memória, bateria e dados móveis.

---

## [1.0.0] - 2026-08-26

### 🚀 Novidades e Recursos
- **Redesign Visual Completo:**
  - Nova paleta Health-Tech com tons Emerald (#059669) e Slate (#0F172A).
  - Cards com cantos arredondados (22px squircle), botões pill (16px) e tipografia moderna.
  - Navegação fluida em 4 abas: **Scanner**, **Cesta de Compras**, **Histórico** e **Perfil de Saúde**.
- **Perfil de Saúde Personalizado com Alertas Médicos:**
  - Suporte a restrições: *Hipertensão (Sódio), Diabetes (Açúcares), Celíaco (Glúten), Intolerância à Lactose e Dieta Vegana*.
  - Emissão automática de cartões de aviso caso o produto viole as condições do usuário.
- **Troca Inteligente de Alimentos:**
  - Sugestões curadas de alternativas brasileiras mais saudáveis quando a nota for < 75.
- **Cesta de Compras / Carrinho Saudável:**
  - Cálculo de Nota Média da cesta e discriminativo de produtos saudáveis vs a evitar.
  - Badge dinâmico de contagem no menu inferior.
- **Lupas de Alerta Frontal ANVISA (RDC 429/2020):**
  - Selos automáticos de "Alto em Açúcar Adicionado", "Alto em Gordura Saturada" e "Alto em Sódio".
- **Matriz Visual de Macronutrientes:**
  - Barras de progresso e níveis de Açúcares, Gordura Saturada, Sódio, Fibras e Proteínas.
- **Modo Autônomo e Conexão Direta à Internet:**
  - O aplicativo Flutter funciona 100% autônomo diretamente pelo 4G/5G/Wi-Fi.
  - Integração direta com Open Food Facts e Google Gemini 2.5 Vision.
  - Cache local e histórico salvo no dispositivo.
- **Guia Nutricional Educativo:**
  - Explicações interativas sobre a classificação NOVA (1 a 4) e regras de ingredientes.

---

### 📦 Versões e Tags Git
- `v1.0.0`: Versão inicial estável completa com modo autônomo, IA Gemini Vision, Perfil de Saúde e Troca Inteligente.
