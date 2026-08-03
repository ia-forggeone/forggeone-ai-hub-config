#requires -Version 5.1

$ErrorActionPreference = "Stop"

$configUrl = "https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/config.yaml"

$iaHubBaseUrl = if ($env:IA_HUB_BASE_URL) {
    $env:IA_HUB_BASE_URL
} else {
    "http://ia-hub.local:4000/v1"
}

$iaHubApiKey = if ($env:IA_HUB_API_KEY) {
    $env:IA_HUB_API_KEY
} else {
    "sk-hub-ia-key"
}

$ollamaBaseUrl = if ($env:OLLAMA_BASE_URL) {
    $env:OLLAMA_BASE_URL
} else {
    "http://ia-hub.local:11434/v1"
}

$ollamaApiKey = if ($env:OLLAMA_API_KEY) {
    $env:OLLAMA_API_KEY
} else {
    "ollama"
}

function Write-Log {
    param([string]$Message)

    Write-Host "[opencode-setup] $Message"
}

function Get-OperatingSystem {
    if ($env:OS -eq "Windows_NT") {
        return "windows"
    }

    if ($PSVersionTable.Platform -eq "Unix") {
        $uname = & uname -s

        if ($uname -like "Darwin*") {
            return "mac"
        }

        if ($uname -like "Linux*") {
            return "linux"
        }
    }

    throw "Sistema operacional não suportado."
}

function Get-ConfigFile {
    param([string]$OperatingSystem)

    if ($OperatingSystem -eq "windows") {
        if (-not $env:APPDATA) {
            throw "A variável APPDATA não foi encontrada."
        }

        $configDirectory = Join-Path $env:APPDATA "opencode"
    }
    else {
        $configHome = if ($env:XDG_CONFIG_HOME) {
            $env:XDG_CONFIG_HOME
        }
        else {
            Join-Path $HOME ".config"
        }

        $configDirectory = Join-Path $configHome "opencode"
    }

    $opencodeFile = Join-Path $configDirectory "opencode.jsonc"
    $configFile = Join-Path $configDirectory "config.jsonc"

    if (Test-Path $opencodeFile) {
        return $opencodeFile
    }

    if (Test-Path $configFile) {
        return $configFile
    }

    # Nome padrão utilizado pelo OpenCode
    return $opencodeFile
}

function Get-ModelId {
    param([string]$Model)

    $model = $Model.Trim().Trim('"').Trim("'")

    if ($model.StartsWith("openrouter/")) {
        $model = $model.Substring("openrouter/".Length)
        $model = ($model -split "/")[-1]
    }
    elseif ($model.StartsWith("ollama/")) {
        $model = $model.Substring("ollama/".Length)
    }

    return $model
}

function Get-ModelsFromYaml {
    param([string]$Yaml)

    $remoteModels = [ordered]@{}
    $localModels = [ordered]@{}

    $blockPattern = '(?ms)^\s*-\s+model_name:\s*"(?<name>[^"]+)"(?<block>.*?)(?=^\s*-\s+model_name:|\z)'

    $blocks = [regex]::Matches($Yaml, $blockPattern)

    foreach ($block in $blocks) {
        $modelName = $block.Groups["name"].Value.Trim()
        $blockContent = $block.Groups["block"].Value

        $modelMatch = [regex]::Match(
            $blockContent,
            '(?m)^\s*model:\s*(?<model>[^\s#]+)'
        )

        if (-not $modelMatch.Success) {
            continue
        }

        $liteModel = $modelMatch.Groups["model"].Value.Trim().Trim('"').Trim("'")
        $modelId = Get-ModelId $liteModel

        $modelObject = [ordered]@{
            name = $modelName
            id   = $modelName
        }

        if ($liteModel.StartsWith("ollama/")) {
            $localModels[$modelId] = $modelObject
        }
        else {
            $remoteModels[$modelId] = $modelObject
        }
    }

    if ($remoteModels.Count -eq 0 -and $localModels.Count -eq 0) {
        throw "Nenhum modelo foi encontrado no config.yaml."
    }

    return @{
        Remote = $remoteModels
        Local  = $localModels
    }
}

try {
    $operatingSystem = Get-OperatingSystem
    $configFile = Get-ConfigFile $operatingSystem
    $configDirectory = Split-Path $configFile -Parent

    Write-Log "Sistema detectado: $operatingSystem"
    Write-Log "Arquivo de destino: $configFile"
    Write-Log "Baixando config.yaml..."

    $yamlContent = Invoke-RestMethod `
        -Uri $configUrl `
        -Method Get

    if ([string]::IsNullOrWhiteSpace($yamlContent)) {
        throw "O config.yaml foi baixado vazio."
    }

    $models = Get-ModelsFromYaml $yamlContent

    $providers = [ordered]@{}

    $providers["ia-hub"] = [ordered]@{
        npm     = "@ai-sdk/openai-compatible"
        name    = "IA Hub (LiteLLM)"
        options = [ordered]@{
            baseURL = $iaHubBaseUrl
            apiKey  = $iaHubApiKey
        }
        models  = $models.Remote
    }

    # O provedor local somente será adicionado no macOS.
    if ($operatingSystem -eq "mac" -and $models.Local.Count -gt 0) {
        $providers["mac-ollama"] = [ordered]@{
            npm     = "@ai-sdk/openai-compatible"
            name    = "Ollama Local"
            options = [ordered]@{
                baseURL = $ollamaBaseUrl
                apiKey  = $ollamaApiKey
            }
            models  = $models.Local
        }
    }

    $config = [ordered]@{
        '$schema' = "https://opencode.ai/config.json"
        provider  = $providers
    }

    New-Item `
        -ItemType Directory `
        -Path $configDirectory `
        -Force `
        | Out-Null

    if (Test-Path $configFile) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupFile = "$configFile.backup.$timestamp"

        Copy-Item `
            -Path $configFile `
            -Destination $backupFile `
            -Force

        Write-Log "Backup criado em: $backupFile"
    }

    $json = $config | ConvertTo-Json -Depth 20

    # Grava UTF-8 sem BOM
    [System.IO.File]::WriteAllText(
        $configFile,
        $json + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Log "Arquivo gerado com sucesso."
    Write-Log "Modelos remotos: $($models.Remote.Count)"
    Write-Log "Modelos locais: $($models.Local.Count)"
    Write-Log "Configuração salva em: $configFile"
}
catch {
    Write-Error "[opencode-setup] ERRO: $($_.Exception.Message)"
    exit 1
}
