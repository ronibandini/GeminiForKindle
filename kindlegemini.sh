#!/bin/sh
# KindleGemini - Roni Bandini 4/2026

# Config
API_KEY=""
MODEL="gemini-2.5-flash-lite"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}"
MAX_TOKENS=300
TEMPERATURE="0.7"
WRAP_WIDTH=46

# File de debug por las dudas :(
SCRIPT_DIR=$(dirname "$0")
TMP_FILE="${SCRIPT_DIR}/gemini_resp.json"
HISTORY_FILE="${SCRIPT_DIR}/gemini_history.json"

clear
echo ""
echo "**********************************************"
echo "*                                            *"
echo "*         K I N D L E G E M I N I            *"
echo "*         Roni Bandini  -  4/2026            *"
echo "*                                            *"
echo "**********************************************"
echo ""

# Validacion 
if [ -z "$API_KEY" ] || [ "$API_KEY" = "TU_NUEVA_CLAVE_AQUI" ]; then
    echo "Error: Debes editar el script y poner tu API_KEY real en la variable API_KEY."
    exit 1
fi

# Inicializar historial
echo '[]' > "$HISTORY_FILE"

# Extrae txt del JSON que devuelve Gemini con awk
extract_text() {
    awk '
    BEGIN { found=0; result=""; in_text=0 }
    {
        line = $0
        while (length(line) > 0) {
            if (!found) {
                idx = index(line, "\"text\"")
                if (idx > 0) {
                    line = substr(line, idx + 6)
                    while (substr(line,1,1) == " " || substr(line,1,1) == ":") {
                        line = substr(line, 2)
                    }
                    if (substr(line,1,1) == "\"") {
                        line = substr(line, 2)
                        found = 1
                        in_text = 1
                    }
                } else {
                    break
                }
            }
            if (found && in_text) {
                i = 1
                while (i <= length(line)) {
                    ch = substr(line, i, 1)
                    if (ch == "\\") {
                        next_ch = substr(line, i+1, 1)
                        if (next_ch == "n")       { result = result "\n" }
                        else if (next_ch == "t")  { result = result "\t" }
                        else if (next_ch == "\"") { result = result "\"" }
                        else if (next_ch == "\\") { result = result "\\" }
                        else                      { result = result next_ch }
                        i = i + 2
                    } else if (ch == "\"") {
                        print result
                        exit
                    } else {
                        result = result ch
                        i = i + 1
                    }
                }
                line = ""
            }
        }
    }
    ' "$1"
}

# Word-wrap: respeta saltos de linea y corta en espacios
wrap_text() {
    awk -v width="$WRAP_WIDTH" '
    {
        # Procesar cada linea del input
        line = $0
        # Si la linea es vacia, imprimirla tal cual
        if (length(line) == 0) {
            print ""
            next
        }
        # Partir la linea en palabras y reensamblar respetando width
        current = ""
        n = split(line, words, " ")
        for (i = 1; i <= n; i++) {
            word = words[i]
            if (current == "") {
                current = word
            } else if (length(current) + 1 + length(word) <= width) {
                current = current " " word
            } else {
                print current
                current = word
            }
        }
        if (current != "") print current
    }
    '
}

# Escapa txt para json
escape_json() {
    printf '%s' "$1" | awk '{
        out = ""
        for (i=1; i<=length($0); i++) {
            c = substr($0,i,1)
            if      (c == "\\") out = out "\\\\"
            else if (c == "\"") out = out "\\\""
            else if (c == "\n") out = out "\\n"
            else if (c == "\r") out = out "\\r"
            else if (c == "\t") out = out "\\t"
            else out = out c
        }
        printf "%s", out
    }'
}

# Construye body json con historial 
build_request_body() {
    USER_TEXT="$1"
    ESCAPED_TEXT=$(escape_json "$USER_TEXT")
    HISTORY=$(cat "$HISTORY_FILE")
    NEW_TURN="{\"role\":\"user\",\"parts\":[{\"text\":\"${ESCAPED_TEXT}\"}]}"

    if [ "$HISTORY" = "[]" ]; then
        CONTENTS="[${NEW_TURN}]"
    else
        HISTORY_BASE=$(echo "$HISTORY" | sed 's/]$//')
        CONTENTS="${HISTORY_BASE},${NEW_TURN}]"
    fi

    printf '{
  "system_instruction": {
    "parts": [{"text": "Responder breve y conciso. Maximo 3 oraciones. Sin listas ni explicaciones extensas."}]
  },
  "generationConfig": {
    "maxOutputTokens": %d,
    "temperature": %s,
    "stopSequences": []
  },
  "contents": %s
}' "$MAX_TOKENS" "$TEMPERATURE" "$CONTENTS"
}

# Actualiza historial
update_history() {
    USER_TEXT="$1"
    MODEL_TEXT="$2"
    ESCAPED_USER=$(escape_json "$USER_TEXT")
    ESCAPED_MODEL=$(escape_json "$MODEL_TEXT")
    HISTORY=$(cat "$HISTORY_FILE")
    NEW_USER_TURN="{\"role\":\"user\",\"parts\":[{\"text\":\"${ESCAPED_USER}\"}]}"
    NEW_MODEL_TURN="{\"role\":\"model\",\"parts\":[{\"text\":\"${ESCAPED_MODEL}\"}]}"

    if [ "$HISTORY" = "[]" ]; then
        echo "[${NEW_USER_TURN},${NEW_MODEL_TURN}]" > "$HISTORY_FILE"
    else
        HISTORY_BASE=$(echo "$HISTORY" | sed 's/]$//')
        echo "${HISTORY_BASE},${NEW_USER_TURN},${NEW_MODEL_TURN}]" > "$HISTORY_FILE"
    fi
}

echo "Cuando quieras salir escribi: chau"
echo "----------------------------------------------"
echo ""

# Loop ppal :)
while true; do
    printf "Vos: "
    read USER_INPUT

    if [ "$USER_INPUT" = "chau" ] || [ "$USER_INPUT" = "exit" ] || [ "$USER_INPUT" = "quit" ]; then
        echo ""
        echo "Chaucha!"
        rm -f "$HISTORY_FILE"
        exit 0
    fi

    if [ -z "$USER_INPUT" ]; then
        continue
    fi

    REQUEST_BODY=$(build_request_body "$USER_INPUT")

    HTTP_CODE=$(curl -s -o "$TMP_FILE" -w "%{http_code}" -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -d "$REQUEST_BODY")

    if [ "$HTTP_CODE" -eq 200 ]; then
        RESPONSE_TEXT=$(extract_text "$TMP_FILE")

        if [ -z "$RESPONSE_TEXT" ]; then
            echo ""
            echo "Gemini: (respuesta vacia)"
            echo ""
        else
            echo ""
            echo "Gemini:"
            echo "$RESPONSE_TEXT" | wrap_text
            echo ""
            update_history "$USER_INPUT" "$RESPONSE_TEXT"
        fi
    else
        echo ""
        echo "ERROR HTTP $HTTP_CODE"
        echo ""
    fi
done