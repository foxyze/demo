# Azure App Service – IaC, CI/CD and Monitoring

A Piranha CMS (.NET 10) app deployed to Azure App Service on an existing Linux App Service Plan.
Infrastructure is Terraform, pipelines are GitHub Actions, and Azure login uses OIDC (no client secrets).

Live: https://prod.org

## Stack

| Area | Choice |
|---|---|
| App | Piranha CMS 12.2 on .NET 10 (LTS), xUnit smoke tests |
| Hosting | Azure App Service (Linux) on plan P0v3, slot `preprod` |
| Database | Azure SQL, Basic tier |
| IaC | Terraform 1.17, `azurerm ~> 5.11`, remote state in Azure Storage |
| CI/CD | GitHub Actions, OIDC federated credentials |
| Security checks | Gitleaks (secrets), Semgrep (C# SAST), Trivy (Terraform misconfig) |
| Monitoring | Application Insights + Log Analytics, Azure Monitor alerts on SQL |
| Local dev | Docker/Podman Compose with SQL Server 2022 |



## Architecture

```
            Internet                               GitHub Actions (OIDC)
               │                                            │ deploy / swap
               ▼                                            ▼
  prod.org ──► App Service  app-demo-<id>  ◄─── slot preprod
                       │  (P0v3 Linux, existing plan)
   Private Endpoint ◄──┤ inbound, snet-endpoints 10.10.2.0/24
                       │
   VNet integration ───┘ outbound, snet-integration 10.10.1.0/24
                       │  service endpoint Microsoft.Sql
                       ▼
                 Azure SQL (Basic) ── VNet rule: only snet-integration
                       │
                 Azure Monitor alerts ──► email
  App Insights ◄── app + slot telemetry ──► Log Analytics
```

**00-platform** stands in for infrastructure owned by another team. **01-app** reads it by name with `data` blocks, not remote state, so it behaves like it would against a real existing plan.

01-app creates:

- **App Service + `preprod` slot**: .NET 10, HTTPS only, health check `/`, app settings, and the `piranha` connection string (type `SQLAzure`). The connection string and the App Insights key are sticky, so they stay with their slot on swap.
- **VNet integration** for the app and the slot, so outbound traffic to SQL goes through `snet-integration`.
- **SQL VNet rule**: SQL accepts traffic only from that subnet. There are no firewall IP rules and no "Allow Azure services".
- **Private endpoints** for the app (`sites`) and the slot (`sites-preprod`), plus the private DNS zone `privatelink.azurewebsites.net` linked to the VNet.
- **Access restrictions**: default deny, allow list from `allowed_ips` (currently `0.0.0.0/0` for the demo). The SCM site stays open for deploys, which are protected by OIDC.
- **Custom domain** `prod.org` with a free App Service managed certificate, behind the `enable_custom_domain` flag.
- **Monitoring** (bonus): Log Analytics, workspace-based App Insights, an email action group, and SQL alerts for CPU > 80 %, storage > 80 % and deadlocks > 0.

## Pipelines

```
push (any branch) / PR → main ──► ci.yml
tag QA-* on main ──────────────► qa.yml ──► cd.yml (preprod → approval → prod)
manual "Run workflow" ─────────► cd.yml (rollback to any QA tag)
```

**ci.yml** runs on every push and on PRs to `main`. `dorny/paths-filter` splits it into two independent chains, so app changes don't run Terraform checks and the other way round.
- App chain: `lint` (`dotnet format`) → `test` → `build`, with `gitleaks` and `semgrep` running in parallel.
- Infra chain: `tf-fmt` → `tf-validate` (both layers, `-backend=false`) → `trivy`.

**qa.yml** runs on a `QA-*` tag.
- `guard`: fails if the tag isn't on `main`, and stops cleanly when nothing in `application/` changed since the previous QA tag.
- Then `test` (coverage gate 15 %, current ≈ 20 %), `quality` (format + Semgrep) and `build` (artifact `app-<tag>`) run in parallel.
- `release` calls `cd.yml`.

**cd.yml**
1. `deploy-preprod`: deploy the artifact to the `preprod` slot, smoke test it, then route 20 % of production traffic to it (canary).
2. `promote-prod`: waits for manual approval (environment `prod`). It then clears routing, swaps `preprod` into production and smoke tests ``. If anything fails after the swap, it swaps back.

A `main` ruleset requires a PR plus green `lint`, `test`, `build`, `gitleaks` and `semgrep` checks. Terraform is never run from a pipeline.

## Setup from scratch

**Prerequisites:** `az`, `terraform` ≥ 1.5, `gh`, .NET 10 SDK. Log in with `az login` and `gh auth login`.

1. **Bootstrap** (once). In `infrastructure/scripts/bootstrap.sh`, set `GITHUB_SUBJECT` using your owner and repo IDs:
   ```bash
   gh api repos/OWNER/REPO --jq '"\(.owner.id) \(.id)"'   # -> repo:OWNER@<owner_id>/REPO@<repo_id>
   ./infrastructure/scripts/bootstrap.sh
   ```
   It creates the state storage and the app registration with federated credentials for environments `preprod` and `prod`. It prints the IDs you need next.

2. **GitHub settings**
   - Secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
   - Variables: `AZURE_WEBAPP_NAME`, `AZURE_RG`, `PROD_URL`.
   - Environments: `preprod` with no rules, and `prod` with a required reviewer.
   - Ruleset on `main`: require a PR and the CI checks.

3. **Platform layer**
   ```bash
   cd infrastructure/terraform/00-platform
   cp terraform.tfvars.example terraform.tfvars   # subscription_id, deployer_sp_object_id, sql_admin_password
   terraform init && terraform apply
   ```

4. **App layer**
   ```bash
   az provider register -n Microsoft.Insights --wait   # new subscriptions only
   cd ../01-app
   cp terraform.tfvars.example terraform.tfvars       # names from 00-platform outputs, alert_email, allowed_ips
   terraform init && terraform apply
   ```

5. **Custom domain** (optional). Create these DNS records with the proxy off, then set `enable_custom_domain = true` and `custom_domain`, and apply again:
   - `TXT asuid.<sub>` = `terraform output -raw custom_domain_verification_id`
   - `CNAME <sub>` = `<app>.azurewebsites.net`

6. **First release**: create tag `QA-1` on `main` (git or GitHub Releases), then approve the `prod` deployment in Actions.

7. **After the first deploy**, sign in at `/manager` with the seeded `admin` / `password` and change the password under **Settings → Users**.

**Local run:** see `application/README.md`. In short: `cp .env.example .env && docker compose up --build`.

## Operations

| Task | How |
|---|---|
| Release | tag `QA-<n>` on `main` → approve `prod` in Actions |
| Rollback | Actions → `cd` → Run workflow → enter an earlier tag (artifacts are kept 90 days) |
| Check canary | `az webapp traffic-routing show -g <rg> -n <app>` |
| SQL alert fired | Portal → SQL database → Metrics. For app errors: App Insights → Failures / Live Metrics |
| Stuck Terraform lock | `terraform force-unlock <lock-id>` (only when no apply is running) |

## Decisions

| Decision | Why |
|---|---|
| Deploy on QA tag, not on merge to `main` | Merge means integrated, a release is a deliberate step. QA gates run before anything is deployed, every release maps to a tag and an artifact, and rollback is a re-run. `preprod` covers DEV/TEST, `prod` is production. |
| Two Terraform layers, `data` blocks | Simulates an existing plan owned by someone else. The app layer only depends on resource names. |
| P0v3 instead of S1/B1 | Standard is legacy and Basic has no deployment slots, which canary and swap need. |
| SQL Basic | Cheapest tier, enough for a demo. |
| .NET 10 | The Piranha 12 template targets net9, whose support ends in Nov 2026. 10 is LTS. |
| Sweden Central | West Europe didn't accept new customers on this subscription. |
| SQL VNet rule, not "Allow Azure services" | That rule would open SQL to every Azure tenant. |
| Public access on, plus private endpoint | Hosted GitHub runners and the managed certificate need public reach. Production-grade would be public access off with a self-hosted runner in the VNet. |
| No custom domain on the slot | `azurerm` 5.11 can't bind a managed certificate to a slot. The slot keeps its `azurewebsites.net` name. |
| OIDC immutable subject (`owner@id/repo@id`) | GitHub's default for this repo. It survives a repo rename and can't be claimed by a new repo with the same name. |
| Trivy instead of tfsec | tfsec has moved into Trivy and is no longer developed on its own. |
| Tests on SQLite (`Testing` environment) | Piranha migrates on startup, so EF InMemory doesn't work. A temp SQLite file needs no Docker. |
| Clear routing before swap | After the swap, `preprod` holds the old version, so the 20 % would hit old code. |
| SQL password in local `terraform.tfvars` | Git-ignored and fine for a demo. In production it would come from a secret store (OpenBao/Key Vault). |

## Known limitations

- NuGet audit warnings for ImageSharp and AutoMapper are transitive through Piranha 12.2. The fixes need major versions that Piranha doesn't support yet.
- `allowed_ips = ["0.0.0.0/0"]` keeps the demo public. Put real CIDRs there to lock it down.
- One SQL database is shared by both slots, as is usual for slot swaps.
