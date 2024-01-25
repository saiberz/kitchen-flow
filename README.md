# kitchen-flow

Kitchen order display and ticket router built with Phoenix, RabbitMQ, and React.

Orders are split by preparation station and pushed to live boards over WebSockets. Supports multiple display languages for station screens. Events go through a RabbitMQ topic exchange using an outbox worker so order persistence stays transactional.

## Setup

Start Postgres and RabbitMQ:
```bash
docker compose up -d
```

Setup database and start server:
```bash
mix setup
mix phx.server
```

Start frontend:
```bash
cd web
npm install
npm run dev
```

Append `?demo=true` to the URL to enable sample order generation.

## Tests

```bash
mix test
```
