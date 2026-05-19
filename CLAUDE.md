# FIAP Secure Systems — Analisador de Diagramas com IA

MVP de microsserviços em **Go** para análise automática de diagramas de arquitetura via LLM.

## Arquitetura

4 microsserviços independentes + infraestrutura local via Docker Compose:

| Serviço | Porta | Responsabilidade | Banco |
|---|---|---|---|
| `api-gateway` | 8080 | Entrada única, auth JWT, rate limiting, validação de upload | — |
| `upload-orchestrator` | 8081 | Recebe arquivo, persiste S3/MinIO, orquestra estados | PostgreSQL |
| `processing-service` | — | Consumer RabbitMQ, chama LLM (visão), grava DynamoDB | DynamoDB Local |
| `report-service` | 8083 | Consumer RabbitMQ, consolida relatório, expõe via REST | MongoDB |

**Brokers:** RabbitMQ — `process.queue` (ponto a ponto), `processing.topic` e `report.topic` (pub/sub)  
**Storage:** MinIO (bucket `diagrams`)

## Como rodar

```bash
cp .env.example .env
# Edite .env com as credenciais reais e LLM_API_KEY
docker compose up --build
```

Healthchecks: `GET /ping` em gateway (8080), orchestrator (8081) e report (8083).

## Fluxo de dados

```
POST /api/diagrams
  → api-gateway (valida MIME, tamanho, JWT)
  → upload-orchestrator (salva MinIO, insere PostgreSQL, publica process.queue)
    → processing-service (consome, chama LLM, grava DynamoDB, publica report.queue + processing.topic)
      → report-service (consome, salva MongoDB, publica report.topic)
        → upload-orchestrator (atualiza status para ANALISADO)
```

## Estados do processo

`RECEBIDO` → `EM_PROCESSAMENTO` → `ANALISADO` | `ERRO`

## Padrões técnicos obrigatórios

| Padrão | Lib | Aplicação |
|---|---|---|
| Arquitetura | Clean Architecture | Todos os serviços |
| REST | `github.com/gin-gonic/gin v1.10+` | api-gateway, upload-orchestrator, report-service |
| ORM | `gorm.io/gorm v1.25+` + driver postgres | upload-orchestrator (PostgreSQL) |
| Observabilidade | `github.com/newrelic/go-agent/v3 v3.35+` | Todos os serviços |

Camadas internas de cada serviço: `domain` → `usecase` → `repository` (implementa interfaces do usecase) + `handler`/`consumer` (entrada).  
New Relic: serviços HTTP usam `nrgin.Middleware`; consumers abrem `nrApp.StartTransaction` por mensagem.  
GORM: usar `db.Where("campo = ?", val)` — nunca SQL raw sem prepared statements.

## Segurança embutida no design

- **JWT obrigatório** em todas as rotas `/api/*` (HS256, secret mínimo 32 chars)
- **Detecção de MIME** por conteúdo binário (não pela extensão do arquivo)
- **Rate limiting** 100 req/min por IP no gateway
- **Nenhuma credencial em código** — tudo via variáveis de ambiente
- **Imagens Docker distroless/nonroot** — surface de ataque mínima
- **Timeouts** em todos os servidores HTTP e clientes HTTP
- **MaxBytesReader** antes de qualquer parse de multipart

## Estrutura de pastas

```
.
├── api-gateway/
│   └── internal/{handler,middleware,config}/
├── upload-orchestrator/
│   └── internal/{handler,service,repository,domain,queue,config}/
├── processing-service/
│   └── internal/{consumer,service,repository,ai,config}/
├── report-service/
│   └── internal/{consumer,handler,service,repository,config}/
├── infra/scripts/
├── docker-compose.yml
├── .env.example
├── AGENT.MD          ← Arquitetura detalhada
└── FUNCTIONAL_SPEC.MD ← Casos de uso e API
```

## Especificações completas

- Arquitetura: `AGENT.MD`
- Casos de uso e endpoints: `FUNCTIONAL_SPEC.MD`

## Repositórios GIT

- O diretório atual não deve possuir um repositório git.
- Os repos estão nos diretórios internos, sempre execute os comandos git nesses repositório internos, avaliando em qual dependendo do contexto.
- Ao commitar, sempre dar um skip no pre commit. Ex: PRE_COMMIT_ALLOW_NO_CONFIG=1 git commit -m <mensagem>
