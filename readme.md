text

Recolher
Salvar
Copiar
1
README.md
Coloque o arquivo na raiz do seu projeto, junto com setup.sh, setup.ps1 e config.yaml.
O arquivo gerado utiliza o provedor ia-hub e, no macOS, o provedor local mac-ollama conforme a configuração do OpenCode 
opencode.jsonc
.

markdown

Recolher
Salvar
Copiar
1
2
3
4
5
6
7
8
⌄
⌄
# ForgegOne AI Hub Config

Scripts para instalar e gerar automaticamente o arquivo de configuração do [OpenCode](https://opencode.ai), utilizando os modelos definidos no arquivo `config.yaml` deste repositório.

A configuração gerada utiliza o provedor compatível com OpenAI do IA Hub, com URL padrão:

```text
http://ia-hub.local:4000/v1
No macOS, o modelo local do Ollama também é configurado através do provedor mac-ollama:

text

Recolher
Salvar
Copiar
1
http://ia-hub.local:11434/v1
Funcionalidades
Detecta automaticamente Linux, macOS e Windows.
Suporta Linux, macOS, Windows PowerShell, Git Bash e WSL.
Não depende de Python.
Não depende de PyYAML.
Não depende de jq.
Baixa automaticamente o config.yaml do repositório.
Identifica os modelos configurados em model_list.
Gera ou substitui o arquivo opencode.jsonc.
Cria backup automático da configuração anterior.
Separa modelos remotos e locais.
Configura o Ollama local somente no macOS.
Cria automaticamente a pasta de configuração do OpenCode.
Estrutura do projeto
text

Recolher
Salvar
Copiar
1
2
3
4
5
.
├── config.yaml
├── setup.sh
├── setup.ps1
└── README.md
Instalação rápida
Linux e macOS
Execute:

bash

Recolher
Salvar
Copiar
1
curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh | bash
O script irá:

Detectar o sistema operacional;
Baixar o config.yaml;
Ler a lista de modelos;
Criar um backup da configuração existente;
Gerar o arquivo do OpenCode;
Salvar a nova configuração no caminho correto.
Windows PowerShell
Execute:

powershell

Recolher
Salvar
Copiar
1
Set-ExecutionPolicy -Scope Process Bypass; irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex
Para PowerShell 7:

powershell

Recolher
Salvar
Copiar
1
pwsh -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex"
A alteração da política de execução vale somente para a sessão atual do PowerShell.

Caminhos dos arquivos
SISTEMA
CAMINHO PADRÃO
Linux
~/.config/opencode/opencode.jsonc
macOS
~/.config/opencode/opencode.jsonc
Windows
%APPDATA%\opencode\opencode.jsonc
O nome padrão utilizado pelo OpenCode é:

text

Recolher
Salvar
Copiar
1
opencode.jsonc
Caso já exista um arquivo chamado config.jsonc e não exista opencode.jsonc, o script poderá utilizar o arquivo config.jsonc existente.

Backup automático
Antes de substituir uma configuração existente, o instalador cria um backup com data e hora.

Exemplo:

text

Recolher
Salvar
Copiar
1
opencode.jsonc.backup.20260401-153000
Assim, é possível restaurar a configuração anterior caso necessário.

Configuração padrão
text

Recolher
Salvar
Copiar
1
2
3
4
5
6
7
8
9
10
11
IA Hub:
http://ia-hub.local:4000/v1

Chave da IA Hub:
sk-hub-ia-key

Ollama:
http://ia-hub.local:11434/v1

Chave do Ollama:
ollama
Modelos
Os modelos são lidos automaticamente do arquivo config.yaml.

O formato esperado é:

yaml

Recolher
Salvar
Copiar
1
2
3
4
5
6
7
8
⌄
⌄
⌄
⌄
⌄
model_list:
  - model_name: "$ DeepSeek V4 Pro"
    litellm_params:
      model: openrouter/deepseek/deepseek-v4-pro

  - model_name: "Qwen 3.5 (free local)"
    litellm_params:
      model: ollama/qwen3.5:9b-mlx
Modelos cujo campo model começa com:

text

Recolher
Salvar
Copiar
1
ollama/
são considerados modelos locais.

Os demais modelos são considerados modelos remotos e ficam disponíveis através do provedor:

text

Recolher
Salvar
Copiar
1
ia-hub
Comportamento por sistema operacional
Linux
No Linux, o script configura os modelos remotos através do IA Hub.

O modelo local do Ollama não é adicionado automaticamente ao OpenCode.

macOS
No macOS, o script configura:

Modelos remotos através do IA Hub;
Modelos locais através do Ollama.
O provedor local será chamado:

text

Recolher
Salvar
Copiar
1
mac-ollama
Windows
No Windows, utilize o script PowerShell:

powershell

Recolher
Salvar
Copiar
1
Set-ExecutionPolicy -Scope Process Bypass; irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex
Também é possível executar o setup.sh pelo Git Bash ou WSL:

bash

Recolher
Salvar
Copiar
1
curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh | bash
Personalizando as URLs
Linux e macOS
bash

Recolher
Salvar
Copiar
1
2
3
4
5
6
export IA_HUB_BASE_URL="http://192.168.1.100:4000/v1"
export IA_HUB_API_KEY="minha-chave"
export OLLAMA_BASE_URL="http://192.168.1.100:11434/v1"
export OLLAMA_API_KEY="ollama"

curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh | bash
Também é possível executar o script localmente:

bash

Recolher
Salvar
Copiar
1
2
3
4
IA_HUB_BASE_URL="http://192.168.1.100:4000/v1" \
IA_HUB_API_KEY="minha-chave" \
OLLAMA_BASE_URL="http://192.168.1.100:11434/v1" \
./setup.sh
Windows PowerShell
powershell

Recolher
Salvar
Copiar
1
2
3
4
5
6
$env:IA_HUB_BASE_URL = "http://192.168.1.100:4000/v1"
$env:IA_HUB_API_KEY = "minha-chave"
$env:OLLAMA_BASE_URL = "http://192.168.1.100:11434/v1"
$env:OLLAMA_API_KEY = "ollama"

irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex
Atualizando a configuração
Após alterar o config.yaml, execute novamente o instalador.

Linux e macOS
bash

Recolher
Salvar
Copiar
1
curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh | bash
Windows
powershell

Recolher
Salvar
Copiar
1
Set-ExecutionPolicy -Scope Process Bypass; irm https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1 | iex
A configuração anterior será salva automaticamente em um arquivo de backup.

Segurança
Os comandos de instalação executam scripts baixados diretamente do GitHub.

Antes de utilizá-los em produção, revise os arquivos:

setup.sh;
setup.ps1;
config.yaml.
Linux e macOS
Para baixar e revisar o script antes de executá-lo:

bash

Recolher
Salvar
Copiar
1
2
3
curl -fsSL https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.sh -o setup.sh
less setup.sh
bash setup.sh
Windows PowerShell
powershell

Recolher
Salvar
Copiar
1
2
3
4
5
6
7
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/setup.ps1" `
  -OutFile setup.ps1

Get-Content .\setup.ps1
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
Requisitos
Linux e macOS
Bash;
curl ou wget;
awk;
acesso à internet.
Essas ferramentas normalmente já estão disponíveis nesses sistemas.

Windows
Windows PowerShell 5.1 ou PowerShell 7;
acesso à internet.
Não é necessário instalar:

Python;
PyYAML;
jq;
Node.js;
Git.
Solução de problemas
O arquivo não foi encontrado pelo OpenCode
Confirme se o arquivo foi gerado no local correto:

text

Recolher
Salvar
Copiar
1
2
Linux/macOS:
~/.config/opencode/opencode.jsonc
text

Recolher
Salvar
Copiar
1
2
Windows:
%APPDATA%\opencode\opencode.jsonc
Também verifique se a versão instalada do OpenCode utiliza opencode.jsonc ou config.jsonc.

O IA Hub não responde
Verifique se o endereço está acessível:

bash

Recolher
Salvar
Copiar
1
curl http://ia-hub.local:4000/v1
Se estiver utilizando outro servidor, execute o script com uma URL personalizada.

O Ollama não responde no macOS
Verifique se o Ollama está em execução:

bash

Recolher
Salvar
Copiar
1
curl http://ia-hub.local:11434/v1/models
Se necessário:

bash

Recolher
Salvar
Copiar
1
export OLLAMA_BASE_URL="http://localhost:11434/v1"
Depois execute o instalador novamente.

Nenhum modelo foi encontrado
Confira se o config.yaml possui a estrutura esperada:

yaml

Recolher
Salvar
Copiar
1
2
3
4
⌄
⌄
⌄
model_list:
  - model_name: "Nome do modelo"
    litellm_params:
      model: provedor/modelo
O script foi desenvolvido para esse formato específico.
