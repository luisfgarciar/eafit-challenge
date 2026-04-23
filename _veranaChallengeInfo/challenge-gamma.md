# Reto IA Generativa: Persona AI Agents con Hologram

## Presentación para Estudiantes — Verana Foundation × NODO EAFIT

---

## Slide 1 — Portada

**Reto IA Generativa: Agentes IA Verificables con Hologram**

Beca IA Ser ANDI · NODO EAFIT · Verana Foundation

verana.io | hologram.zone

> Prompt ilustración: A futuristic holographic shield with an AI robot face inside, connected to university students working on laptops, clean modern vector style, blue and teal gradient, dark background with glowing nodes.

---

## Slide 2 — El Problema

**¿En quién confías cuando chateas con un bot?**

- Los chatbots actuales viven en plataformas centralizadas
- No puedes saber quién los opera ni qué hacen con tus datos
- No hay forma de verificar si un agente IA es legítimo
- Cualquiera puede crear un bot que se haga pasar por una empresa o persona

> Prompt ilustración: A person looking confused at their phone surrounded by multiple anonymous chatbot bubbles with masks and question marks, dark moody tone, flat illustration, red and gray palette.

---

## Slide 3 — La Solución: Verana + Hologram

**Una capa de confianza para agentes IA**

- **Verana**: infraestructura abierta de identidad descentralizada (DIDs + Credenciales Verificables W3C)
- **Hologram**: app de mensajería donde cada bot tiene una identidad verificable
- Antes de chatear, el usuario puede confirmar **quién opera el agente**
- Todo respaldado criptográficamente — no hay que "confiar", se puede **verificar**

> Prompt ilustración: A smartphone showing a chat app with a green verified badge on a chatbot profile, digital credential cards floating around, clean UI mockup, blue and white tones, light background.

---

## Slide 4 — Tu Reto

**Construir una plataforma para crear Persona AI Agents**

Un **Persona AI Agent** representa a una persona y actúa en su nombre.

Ejemplo: un plomero tiene un agente IA que gestiona su calendario. Los clientes chatean con el agente en Hologram para agendar una cita.

**Tu misión**: crear una app web donde cualquier persona pueda crear, configurar y publicar su propio Persona AI Agent — sin escribir código.

> Prompt ilustración: A split screen showing on the left a plumber working, and on the right a phone with a chatbot managing his calendar, connected by glowing digital lines, warm professional colors, modern flat illustration.

---

## Slide 5 — Cómo Llegarás Ahí: 3 Pasos

**Aprendizaje progresivo: de lo simple a lo complejo**

| Paso | Qué harás | Peso |
|------|-----------|------|
| **Paso 1** (Aprender) | Configurar y ejecutar un chatbot IA con Hologram en tu máquina | 20% |
| **Paso 2** (Aprender) | Desplegar tu bot en Kubernetes (accesible públicamente) | 15% |
| **Paso 3** (El Reto) | Construir la plataforma web para crear Persona AI Agents | 40% |

El documento **challenge.md** tiene las instrucciones detalladas paso a paso.

> Prompt ilustración: Three ascending steps like a staircase, each with an icon: step 1 a robot chatbot, step 2 a cloud with kubernetes logo, step 3 a web browser with a dashboard, isometric 3D style, vibrant gradient colors, white background.

---

## Slide 6 — Paso 1: Tu Primer Chatbot

**Fork → Configurar → Ejecutar → Chatear en Hologram**

1. Fork del repo `verana-labs/verana-eafit`
2. Configurar variables de entorno (LLM provider, prompt, idiomas)
3. Personalizar el `agent-pack.yaml` (nombre, personalidad, RAG)
4. `docker compose up` — levanta todo localmente
5. Exponer con **ngrok** y conectar desde **Hologram**

Tecnologías: Docker, Node.js, LLMs (OpenAI/Ollama), RAG, VS Agent

> Prompt ilustración: A developer at a laptop with a terminal showing docker compose up, connected by a tunnel to a phone showing a chat conversation with a friendly bot, code editor visible in background, warm dev environment, modern flat style.

---

## Slide 7 — Paso 2: Despliegue en la Nube

**De tu laptop al mundo real con Kubernetes**

1. Recibir credenciales `kubeconfig` de tu namespace
2. Personalizar los manifiestos YAML en `k8s/`
3. Ejecutar el script de despliegue
4. Tu bot queda en: `miagente.tunombre.eafit.testnet.verana.network`

Ya no necesitas ngrok — tu bot está online 24/7.

> Prompt ilustración: A laptop pushing a container box into a cloud with the Kubernetes helm wheel logo, the box transforms into a running chatbot accessible worldwide, clean tech illustration, blue and purple tones.

---

## Slide 8 — Paso 3: La Plataforma Web

**El reto principal: una app para crear bots sin código**

La app web debe permitir:

- **Login** de usuarios (opcional: Google OAuth)
- **Crear** un nuevo Persona AI Agent con un formulario visual
- **Configurar**: prompt, MCP tools, RAG, datos de persona y servicio
- **Publicar/Despublicar** el bot en Kubernetes con un clic
- **Link directo** al bot para escanearlo con Hologram

Incluir al menos **2 servidores MCP** (ej: Google Calendar, X/Twitter)

> Prompt ilustración: A modern web dashboard showing a list of AI bots with status badges (online/offline), a create bot wizard form, and a publish button, clean SaaS-style UI, purple and blue accent colors, light background.

---

## Slide 9 — Herramientas y Soporte

**Todo lo que necesitas para empezar**

| Herramienta | Para qué |
|-------------|----------|
| VS Code / Windsurf / Cursor | Escribir código |
| Git + GitHub | Versionamiento y colaboración |
| Node.js + pnpm | Runtime y dependencias |
| Docker | Ejecutar servicios localmente |
| ngrok | Túnel público para desarrollo |
| Hologram | Probar tu chatbot |
| kubectl | Desplegar en Kubernetes |

**Soporte**: Discord de Verana → canal **#eafit-challenges**
https://discord.com/invite/edjaFn252q

Mentor técnico de Verana acompaña todo el proceso.

> Prompt ilustración: A toolbox opening with icons of VS Code, Docker, GitHub, Kubernetes, and a chat bubble floating out, surrounded by helpful mentor figures, friendly and welcoming tone, colorful flat illustration.

---

## Slide 10 — Evaluación y Siguiente Paso

**Cómo serás evaluado**

| Criterio | Peso |
|----------|------|
| Paso 1 — Chatbot funcionando | 20% |
| Paso 2 — Despliegue k8s | 15% |
| Paso 3 — Aplicación web | 40% |
| Integraciones MCP | 10% |
| Código + Docs + Creatividad | 15% |

**Bonus** (+5% cada uno): más MCP servers, RAG real, UI excepcional, tests, demo en video

**Siguiente paso**: Lee el documento `challenge.md`, instala las herramientas, y únete al Discord. ¡Nos vemos en #eafit-challenges!

> Prompt ilustración: A podium with a glowing trophy shaped like a robot, students celebrating around it with laptops, confetti particles, EAFIT and Verana logos subtly visible, inspiring and aspirational mood, gold and blue tones, modern illustration.
