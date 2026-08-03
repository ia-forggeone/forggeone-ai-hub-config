#!/usr/bin/env bash

set -Eeuo pipefail

CONFIG_URL="https://raw.githubusercontent.com/ia-forggeone/forggeone-ai-hub-config/refs/heads/main/config.yaml"

IA_HUB_BASE_URL="${IA_HUB_BASE_URL:-http://ia-hub.local:4000/v1}"
IA_HUB_API_KEY="${IA_HUB_API_KEY:-sk-hub-ia-key}"

OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://ia-hub.local:11434/v1}"
OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"

TEMP_DIR=""

log() {
    printf '[opencode-setup] %s\n' "$*"
}

error() {
    printf '[opencode-setup] ERRO: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

detect_os() {
    case "$(uname -s)" in
        Linux*)
            OS="linux"
            ;;

        Darwin*)
            OS="mac"
            ;;

        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            ;;

        *)
            error "Sistema operacional não suportado."
            ;;
    esac

    log "Sistema detectado: $OS"
}

get_config_directory() {
    case "$OS" in
        linux|mac)
            CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
            ;;

        windows)
            if [[ -n "${APPDATA:-}" ]]; then
                if command -v cygpath >/dev/null 2>&1; then
                    CONFIG_DIR="$(cygpath -u "$APPDATA")/opencode"
                else
                    CONFIG_DIR="$APPDATA/opencode"
                fi
            else
                CONFIG_DIR="${HOME:-$USERPROFILE}/.config/opencode"
            fi
            ;;
    esac

    # O nome padrão oficial é opencode.jsonc.
    # Se o usuário já possuir config.jsonc, ele será usado.
    if [[ -f "$CONFIG_DIR/opencode.jsonc" ]]; then
        CONFIG_FILE="$CONFIG_DIR/opencode.jsonc"
    elif [[ -f "$CONFIG_DIR/config.jsonc" ]]; then
        CONFIG_FILE="$CONFIG_DIR/config.jsonc"
    else
        CONFIG_FILE="$CONFIG_DIR/opencode.jsonc"
    fi

    log "Arquivo de destino: $CONFIG_FILE"
}

download_yaml() {
    TEMP_DIR="$(mktemp -d)"
    YAML_FILE="$TEMP_DIR/config.yaml"

    log "Baixando configuração..."

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$CONFIG_URL" -o "$YAML_FILE"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$CONFIG_URL" -O "$YAML_FILE"
    else
        error "É necessário ter curl ou wget instalado."
    fi

    [[ -s "$YAML_FILE" ]] || error "O config.yaml foi baixado vazio."

    log "config.yaml baixado com sucesso."
}

json_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '%s' "$value"
}

get_model_id() {
    local model="$1"

    model="${model#\"}"
    model="${model%\"}"
    model="${model#\'}"
    model="${model%\'}"

    case "$model" in
        openrouter/*)
            model="${model#openrouter/}"
            model="${model##*/}"
            ;;

        ollama/*)
            model="${model#ollama/}"
            ;;
    esac

    printf '%s' "$model"
}

parse_models() {
    REMOTE_MODELS=()
    LOCAL_MODELS=()

    # O parser abaixo é específico para a estrutura:
    #
    # - model_name: "Nome"
    #   litellm_params:
    #     model: provedor/modelo
    #
    # Não depende de Python, PyYAML ou jq.
    awk '
    function clean(value) {
        gsub(/^[ \t]+|[ \t]+$/, "", value)
        gsub(/^"/, "", value)
        gsub(/"$/, "", value)
        gsub(/^'\''/, "", value)
        gsub(/'\''$/, "", value)
        return value
    }

    /^[ \t]*-[ \t]+model_name:/ {
        name = $0
        sub(/^[ \t]*-[ \t]+model_name:[ \t]*/, "", name)
        name = clean(name)
        current_name = name
        next
    }

    current_name != "" && /^[ \t]+model:[ \t]*/ {
        model = $0
        sub(/^[ \t]+model:[ \t]*/, "", model)
        model = clean(model)

        print current_name "\t" model
        current_name = ""
    }
    ' "$YAML_FILE" > "$TEMP_DIR/models.tsv"

    while IFS=$'\t' read -r model_name lite_model; do
        [[ -z "$model_name" ]] && continue
        [[ -z "$lite_model" ]] && continue

        model_id="$(get_model_id "$lite_model")"

        if [[ "$lite_model" == ollama/* ]]; then
            LOCAL_MODELS+=("$model_id"$'\t'"$model_name")
        else
            REMOTE_MODELS+=("$model_id"$'\t'"$model_name")
        fi
    done < "$TEMP_DIR/models.tsv"

    if [[ ${#REMOTE_MODELS[@]} -eq 0 && ${#LOCAL_MODELS[@]} -eq 0 ]]; then
        error "Nenhum modelo foi encontrado no config.yaml."
    fi

    log "Modelos remotos encontrados: ${#REMOTE_MODELS[@]}"
    log "Modelos locais encontrados: ${#LOCAL_MODELS[@]}"
}

write_models_json() {
    local entries=("$@")
    local total="${#entries[@]}"
    local index=0

    printf '{\n'

    for item in "${entries[@]}"; do
        IFS=$'\t' read -r model_id model_name <<< "$item"

        escaped_id="$(json_escape "$model_id")"
        escaped_name="$(json_escape "$model_name")"

        printf '        "%s": {\n' "$escaped_id"
        printf '          "name": "%s",\n' "$escaped_name"
        printf '          "id": "%s"\n' "$escaped_name"
        printf '        }' "$escaped_name"

        index=$((index + 1))

        if [[ "$index" -lt "$total" ]]; then
            printf ','
        fi

        printf '\n'
    done

    printf '      }'
}

backup_config() {
    mkdir -p "$CONFIG_DIR"

    if [[ -f "$CONFIG_FILE" ]]; then
        BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        log "Backup criado em: $BACKUP_FILE"
    fi
}

generate_config() {
    local first_provider=true

    backup_config

    {
        printf '{\n'
        printf '  "$schema": "https://opencode.ai/config.json",\n'
        printf '  "provider": {\n'

        printf '    "ia-hub": {\n'
        printf '      "npm": "@ai-sdk/openai-compatible",\n'
        printf '      "name": "IA Hub (LiteLLM)",\n'
        printf '      "options": {\n'
        printf '        "baseURL": "%s",\n' "$(json_escape "$IA_HUB_BASE_URL")"
        printf '        "apiKey": "%s"\n' "$(json_escape "$IA_HUB_API_KEY")"
        printf '      },\n'
        printf '      "models": '
        write_models_json "${REMOTE_MODELS[@]}"
        printf '\n'
        printf '    }'

        # O Ollama local será adicionado somente no macOS.
        if [[ "$OS" == "mac" && ${#LOCAL_MODELS[@]} -gt 0 ]]; then
            printf ',\n'
            printf '    "mac-ollama": {\n'
            printf '      "npm": "@ai-sdk/openai-compatible",\n'
            printf '      "name": "Ollama Local",\n'
            printf '      "options": {\n'
            printf '        "baseURL": "%s",\n' "$(json_escape "$OLLAMA_BASE_URL")"
            printf '        "apiKey": "%s"\n' "$(json_escape "$OLLAMA_API_KEY")"
            printf '      },\n'
            printf '      "models": '
            write_models_json "${LOCAL_MODELS[@]}"
            printf '\n'
            printf '    }'
        fi

        printf '\n'
        printf '  }\n'
        printf '}\n'
    } > "$CONFIG_FILE"

    log "Arquivo gerado com sucesso."
    log "Configuração salva em: $CONFIG_FILE"
}

main() {
    detect_os
    get_config_directory
    download_yaml
    parse_models
    generate_config

    echo
    log "Instalação concluída."
}

main "$@"
