# ForgegOne AI Hub Config

Scripts para instalar e gerar automaticamente o arquivo de configuração do [OpenCode](https://opencode.ai), utilizando os modelos definidos no arquivo `config.yaml` deste repositório.

A configuração gerada utiliza o provedor compatível com OpenAI do **IA Hub** (com URL padrão `http://ia-hub.local:4000/v1`). No macOS, o modelo local do Ollama também é configurado através do provedor **mac-ollama** (`http://ia-hub.local:11434/v1`).

---

## 📌 Funcionalidades

- **Multiplataforma:** Detecta automaticamente Linux, macOS e Windows (suporta PowerShell, Git Bash e WSL).
- **Sem Dependências Externas:** Não depende de Python, PyYAML ou `jq`.
- **Automação:** Baixa o `config.yaml` do repositório, identifica os modelos da `model_list` e gera/substitui o `opencode.jsonc`.
- **Segurança & Backup:** Cria backup automático da configuração anterior com carimbo de data/hora.
- **Gestão de Provedores:** Separa modelos remotos e locais (configurando o Ollama local apenas no macOS).
- **Setup Inteligente:** Cria automaticamente a pasta de configuração do OpenCode caso não exista.

---

## 📁 Estrutura do Projeto

```text
.
├── config.yaml
├── setup.sh
├── setup.ps1
└── README.md
```

> **Nota:** Coloque o arquivo `README.md` na raiz do seu projeto, junto com `setup.sh`, `setup.ps1` e `config.yaml`.

---

## 🚀 Instalação Rápida

### Linux e macOS

Execute o comando abaixo no terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh | bash
```

**O que o script faz:**
1. Detecta o sistema operacional;
2. Baixa o `config.yaml`;
3. Lê a lista de modelos;
4. Cria um backup da configuração existente;
5. Gera o arquivo do OpenCode;
6. Salva a nova configuração no caminho correto.

### Windows PowerShell

No PowerShell, execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass; irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex
```

Para **PowerShell 7**:

```powershell
pwsh -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex"
```

*A alteração da política de execução vale somente para a sessão atual.*

---

## 📍 Caminhos dos Arquivos

| Sistema | Caminho Padrão |
| :--- | :--- |
| **Linux** | `~/.config/opencode/opencode.jsonc` |
| **macOS** | `~/.config/opencode/opencode.jsonc` |
| **Windows** | `%APPDATA%\opencode\opencode.jsonc` |

> O nome padrão utilizado é `opencode.jsonc`. Caso já exista um arquivo chamado `config.jsonc` e não exista `opencode.jsonc`, o script utilizará o `config.jsonc` existente.

### 💾 Backup Automático

Antes de substituir uma configuração existente, o instalador cria um backup com data e hora.  
**Exemplo:** `opencode.jsonc.backup.20260401-153000`

---

## ⚙️ Configuração Padrão

- **IA Hub:** `http://ia-hub.local:4000/v1` (Chave: `sk-hub-ia-key`)
- **Ollama:** `http://ia-hub.local:11434/v1` (Chave: `ollama`)

### Estrutura do `config.yaml`

Os modelos são lidos automaticamente do arquivo `config.yaml`. O formato esperado é:

```yaml
model_list:
  - model_name: "$ DeepSeek V4 Pro"
    litellm_params:
      model: openrouter/deepseek/deepseek-v4-pro

  - model_name: "Qwen 3.5 (free local)"
    litellm_params:
      model: ollama/qwen3.5:9b-mlx
```

- Modelos cujo campo `model` começa com `ollama/` são considerados **modelos locais**.
- Os demais modelos são considerados **remotos** e ficam disponíveis através do provedor `ia-hub`.

---

## 💻 Comportamento por Sistema Operacional

- **Linux:** Configura apenas modelos remotos via IA Hub. O Ollama local não é adicionado automaticamente.
- **macOS:** Configura modelos remotos via IA Hub e modelos locais via Ollama (provedor chamado `mac-ollama`).
- **Windows:** Suporta execução nativa via PowerShell ou via Git Bash / WSL executando o `setup.sh`.

---

## 🔧 Personalizando as URLs e Chaves

### Linux e macOS

```bash
export IA_HUB_BASE_URL="http://192.168.1.100:4000/v1"
export IA_HUB_API_KEY="minha-chave"
export OLLAMA_BASE_URL="http://192.168.1.100:11434/v1"
export OLLAMA_API_KEY="ollama"

curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh | bash
```

Para execução local do script:

```bash
IA_HUB_BASE_URL="http://192.168.1.100:4000/v1" IA_HUB_API_KEY="minha-chave" OLLAMA_BASE_URL="http://192.168.1.100:11434/v1" ./setup.sh
```

### Windows PowerShell

```powershell
$env:IA_HUB_BASE_URL = "http://192.168.1.100:4000/v1"
$env:IA_HUB_API_KEY = "minha-chave"
$env:OLLAMA_BASE_URL = "http://192.168.1.100:11434/v1"
$env:OLLAMA_API_KEY = "ollama"

irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex
```

---

## 🔄 Atualizando a Configuração

Após alterar o `config.yaml`, basta reexecutar o instalador. A configuração anterior será salva automaticamente no backup.

---

## 🛡️ Segurança

Recomenda-se revisar os scripts antes de executá-los diretamente da internet:

### Linux e macOS
```bash
curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh -o setup.sh
less setup.sh
bash setup.sh
```

### Windows PowerShell
```powershell
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1" `
  -OutFile setup.ps1

Get-Content .\setup.ps1
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

---

## 📋 Requisitos

### Linux e macOS
- Bash
- `curl` ou `wget`
- `awk`
- Conexão com a internet

### Windows
- Windows PowerShell 5.1 ou PowerShell 7
- Conexão com a internet

*(Não requer Python, PyYAML, jq, Node.js ou Git).*

---

## ❓ Solução de Problemas

1. **O arquivo não foi encontrado pelo OpenCode**
   - Confirme se o arquivo foi gerado em `~/.config/opencode/opencode.jsonc` (Linux/macOS) ou `%APPDATA%\opencode\opencode.jsonc` (Windows).
   - Verifique se a sua versão do OpenCode exige `opencode.jsonc` ou `config.jsonc`.

2. **O IA Hub não responde**
   - Teste a conectividade: `curl http://ia-hub.local:4000/v1`
   - Se estiver em outro servidor, ajuste a variável de ambiente `IA_HUB_BASE_URL`.

3. **O Ollama não responde no macOS**
   - Verifique o status: `curl http://ia-hub.local:11434/v1/models`
   - Se necessário, altere para localhost: `export OLLAMA_BASE_URL="http://localhost:11434/v1"` e execute o setup novamente.

4. **Nenhum modelo foi encontrado**
   - Garanta que o `config.yaml` contenha a chave `model_list` formatada corretamente.
