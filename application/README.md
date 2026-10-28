# PiranhaDemo

Piranha CMS 12 on .NET 10, SQL Server.

## Run locally

```bash
cp .env.example .env
podman compose up --build   # or: docker compose up --build
```

- Site: http://localhost:8080
- Manager: http://localhost:8080/manager (admin / password)

Reset database: `podman compose down -v`

