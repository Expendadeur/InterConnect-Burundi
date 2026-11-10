# 🌍 InterConnect Burundi

> Plateforme sociale multilingue avec traduction IA en temps réel, messagerie instantanée, et appels audio/vidéo — conçue pour connecter les communautés du Burundi et de la diaspora.

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│          Flutter Mobile App    •    Web App (React)             │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS / WSS
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     NGINX (Reverse Proxy)                       │
│          :80 / :443  —  SSL Termination  —  Load Balancing      │
└───┬────────────┬────────────┬────────────┬────────────┬─────────┘
    │            │            │            │            │
    ▼            ▼            ▼            ▼            ▼
┌────────┐ ┌──────────┐ ┌────────┐ ┌────────┐ ┌────────────┐
│Backend │ │   AI     │ │   AI   │ │   AI   │ │  LiveKit   │
│NestJS  │ │Translate │ │  STT   │ │  TTS   │ │  Server    │
│:3000   │ │:8001     │ │:8002   │ │:8003   │ │:7880-7882  │
└───┬────┘ └──────────┘ └────────┘ └────────┘ └────────────┘
    │
    ├──────────────────────────┐
    ▼                          ▼
┌──────────┐             ┌──────────┐
│PostgreSQL│             │  Redis   │
│  :5432   │             │  :6379   │
│(Volumes) │             │(Volumes) │
└──────────┘             └──────────┘
```

---

## ✅ Prérequis

| Outil | Version minimale |
|---|---|
| Docker | 24+ |
| Docker Compose | v2.20+ |
| GNU Make | 4+ *(optionnel)* |

---

## 🚀 Installation & Démarrage

### 1. Cloner le dépôt
```bash
git clone https://github.com/your-org/interconnect-burundi.git
cd "InterConnect Burundi"
```

### 2. Configurer les variables d'environnement
```bash
cp .env.example .env
# Éditez .env avec vos vraies valeurs
nano .env
```

### 3. Lancer l'infrastructure
```bash
# Développement (foreground, avec logs)
make dev

# Production (arrière-plan)
make prod
```

### 4. Vérifier que tout tourne
```bash
make ps
# ou
docker-compose ps
```

---

## 🔧 Variables d'Environnement

### Application
| Variable | Description | Exemple |
|---|---|---|
| `NODE_ENV` | Environnement Node.js | `production` |
| `APP_URL` | URL publique de l'application | `https://interconnect.bi` |
| `BACKEND_PORT` | Port du backend NestJS | `3000` |

### Base de données PostgreSQL
| Variable | Description |
|---|---|
| `POSTGRES_HOST` | Hôte PostgreSQL (nom du service Docker) |
| `POSTGRES_PORT` | Port PostgreSQL (`5432`) |
| `POSTGRES_DB` | Nom de la base de données |
| `POSTGRES_USER` | Utilisateur PostgreSQL |
| `POSTGRES_PASSWORD` | **Secret** — mot de passe fort requis |

### Redis
| Variable | Description |
|---|---|
| `REDIS_HOST` | Hôte Redis (`redis`) |
| `REDIS_PORT` | Port Redis (`6379`) |
| `REDIS_PASSWORD` | **Secret** — mot de passe fort requis |

### JWT
| Variable | Description |
|---|---|
| `JWT_ACCESS_SECRET` | Secret de signature des access tokens (64+ chars) |
| `JWT_REFRESH_SECRET` | Secret de signature des refresh tokens (64+ chars) |
| `JWT_ACCESS_EXPIRY` | Durée de vie access token (ex: `15m`) |
| `JWT_REFRESH_EXPIRY` | Durée de vie refresh token (ex: `7d`) |

### Services IA
| Variable | Description |
|---|---|
| `GOOGLE_TRANSLATE_API_KEY` | Clé API Google Translate |
| `GOOGLE_SPEECH_API_KEY` | Clé API Google Speech-to-Text |
| `GOOGLE_TTS_API_KEY` | Clé API Google Text-to-Speech |
| `DEEPL_API_KEY` | Clé API DeepL (traduction alternative) |
| `WHISPER_MODEL` | Modèle Whisper local (`base`, `small`, `medium`) |

---

## 📡 Endpoints API Principaux

### Authentification
```
POST   /api/auth/register        — Créer un compte
POST   /api/auth/login           — Se connecter
POST   /api/auth/refresh         — Rafraîchir le token
POST   /api/auth/logout          — Se déconnecter
```

### Utilisateurs
```
GET    /api/users/:id            — Profil utilisateur
PATCH  /api/users/:id            — Mettre à jour le profil
GET    /api/users/:id/followers  — Liste des abonnés
POST   /api/users/:id/follow     — Suivre un utilisateur
```

### Posts & Feed
```
GET    /api/posts                — Feed principal (paginé)
POST   /api/posts                — Créer un post
GET    /api/posts/:id            — Détail d'un post
DELETE /api/posts/:id            — Supprimer un post
POST   /api/posts/:id/react      — Réagir à un post
GET    /api/posts/:id/comments   — Commentaires d'un post
POST   /api/posts/:id/comments   — Commenter un post
```

### Messagerie
```
GET    /api/conversations        — Toutes les conversations
POST   /api/conversations        — Nouvelle conversation
GET    /api/conversations/:id/messages — Messages
POST   /api/conversations/:id/messages — Envoyer un message
```

### Appels (LiveKit)
```
POST   /api/calls/token          — Générer un token LiveKit
POST   /api/calls/initiate       — Initier un appel
PATCH  /api/calls/:id/end        — Terminer un appel
```

### Services IA
```
POST   /ai/translate/            — Traduire un texte
POST   /ai/stt/                  — Audio → Texte
POST   /ai/tts/                  — Texte → Audio
```

### Santé
```
GET    /health                   — Health check global
```

---

## 🛠️ Commandes Utiles (Makefile)

```bash
make dev            # Lancer en développement
make prod           # Lancer en production
make down           # Arrêter les services
make logs           # Suivre les logs
make ps             # Statut des containers
make clean          # Tout supprimer (⚠ données incluses)
make migrate        # Exécuter la migration SQL manuellement
make backend-shell  # Shell dans le container backend
make db-shell       # Shell psql dans postgres
make redis-shell    # Shell redis-cli
```

---

## 🗄️ Structure du Projet

```
InterConnect Burundi/
├── backend/                # NestJS API (TypeScript)
│   ├── Dockerfile
│   └── src/
├── ai-services/            # Microservices Python FastAPI
│   ├── Dockerfile
│   ├── translation/        # Service de traduction
│   ├── speech-to-text/     # Service STT (Whisper)
│   └── text-to-speech/     # Service TTS
├── database/
│   └── migrations/
│       └── 001_initial_schema.sql
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
├── docker-compose.yml
├── .env.example
├── .gitignore
├── Makefile
└── README.md
```

---

## 🤝 Contribuer

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/ma-fonctionnalite`)
3. Committez vos changements (`git commit -m 'feat: ajout fonctionnalité X'`)
4. Poussez la branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvrez une Pull Request

Merci de suivre la convention [Conventional Commits](https://www.conventionalcommits.org/).

---

## 🔒 Sécurité

- **Ne committez jamais `.env`** — utilisez `.env.example` comme modèle
- Rotez vos secrets JWT régulièrement
- Activez HTTPS en production (décommentez le redirect dans `nginx/conf.d/default.conf`)
- Utilisez des mots de passe forts pour PostgreSQL et Redis

---

## 📄 Licence

MIT © 2025 InterConnect Burundi Team
