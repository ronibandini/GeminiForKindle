# KindleGemini

Chat con Google Gemini desde un Kindle jailbreakeado, corriendo directamente en Busybox Linux via KTerm.

<img width="400" height="519" alt="KindleGemini" src="https://github.com/user-attachments/assets/0f565b3a-4575-4f3a-87c9-0cb1f237a8a3" />

---

## Requisitos

- Kindle con jailbreak instalado
- [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326) (Kindle Unified Application Launcher)
- [KTerm](https://www.mobileread.com/forums/showthread.php?t=296625) instalado como extensión de KUAL
- API Key de [Google Gemini](https://aistudio.google.com/app/apikey) (gratis)
- Conexión WiFi activa en el Kindle

---

## Instalación

### 1. Obtener el script

Descargar `kindlegemini.sh` desde este repositorio.

### 2. Configurar el script

Abrir `kindlegemini.sh` con cualquier editor de texto y completar las variables al inicio del archivo:

```sh
API_KEY=""              # Tu API Key de Google Gemini
MODEL="gemini-2.5-flash-lite"
MAX_TOKENS=300          # Largo máximo de cada respuesta
TEMPERATURE="0.7"       # 0 = respuestas precisas, 1 = más creativas
```

### 3. Copiar al Kindle

Conectar el Kindle por USB y copiar el archivo a:

```
/mnt/us/extensions/kterm/
```

### 4. Desconectar el USB

Expulsar el Kindle desde el sistema operativo antes de desconectar el cable.

### 5. Dar permisos y ejecutar

Abrir KUAL → iniciar KTerm y ejecutar:

```sh
chmod +x kindlegemini.sh
bash kindlegemini.sh
```

---

## Uso

Una vez iniciado aparece el banner y el prompt `Vos:`. Escribir el mensaje y presionar Enter para obtener la respuesta de Gemini.

```
**********************************************
*                                            *
*         K I N D L E G E M I N I           *
*         Roni Bandini  -  4/2026            *
*         Kindle Busybox Linux               *
*                                            *
**********************************************

Cuando quieras salir escribi: chau
----------------------------------------------

Vos: que es la fotosíntesis?

Gemini: La fotosíntesis es el proceso por el
cual las plantas convierten luz solar en
glucosa usando CO2 y agua como insumos.
```

Para salir escribir `chau`.

---

## Solución de problemas

**El script da errores al ejecutar**

Si el archivo fue copiado desde Windows puede traer saltos de línea incorrectos (`^M`). Solucionarlo con:

```sh
sed -i 's/\r//' kindlegemini.sh
```

**Error de API Key**

Verificar que la API Key esté correctamente pegada en el script, sin espacios ni comillas extras. La key se obtiene gratis en [Google AI Studio](https://aistudio.google.com/app/apikey).

**Sin respuesta o respuesta vacía**

Verificar que el Kindle tenga WiFi activo y que el modelo configurado esté disponible en tu cuenta de Gemini.

---

## Notas técnicas

- El historial de conversación se mantiene durante la sesión y se envía en cada request para que Gemini tenga contexto
- Las respuestas se ajustan automáticamente al ancho de la pantalla (46 caracteres) sin cortar palabras
- El JSON de debug de cada respuesta queda guardado en la misma carpeta del script (`gemini_resp.json`)
- Compatible con Busybox v1.34+, sin dependencias adicionales (usa solo `awk`, `sed` y `curl`)

---

## Autor

**Roni Bandini**  
[bandini.medium.com](https://bandini.medium.com) · [@RoniBandini](https://twitter.com/RoniBandini)

*Buenos Aires, Argentina — Abril 2026*

---

## Licencia

MIT License — libre para usar, modificar y distribuir.


