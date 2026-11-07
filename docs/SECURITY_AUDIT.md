# Security audit & remediation

**Scope:** whole repository: Terraform (AWS), GitHub Actions CI/CD, Docker / Compose,
kubespray bootstrap scripts, committed WordPress content, git history.
**Date:** 2026-11
**Tools:** manual review, [Checkov](https://www.checkov.io/) 3.x, `git log -p` history
scanning, `git-filter-repo`, Gitleaks (in CI).

## Summary

| Severity | Found | Fixed |
|----------|------:|------:|
| Critical | 3 | 3 |
| High     | 6 | 6 |
| Medium   | 5 | 4 |

Checkov, development stack: **21 failed checks → 0** (6 low-severity checks accepted
with a written justification in [`.checkov.yaml`](../.checkov.yaml)).

---

## Critical

### C1. Production `wp-config.php` in git history
`website/wp-config.php` (a full hosting dump) was committed and later deleted, but it
stayed in history with the hosting MySQL user/password and all `AUTH_KEY`/`SALT`
values.
**Fix:** [`scripts/purge-history.sh`](../scripts/purge-history.sh) uses `git-filter-repo`
to remove it from every commit. `wp-config.php` is git-ignored. Gitleaks runs over the
full history in CI. The hosting account was decommissioned, so there are no live
credentials to rotate.

### C2. WordPress database dump committed and baked into a public image
`wordpress_static_data/schema/*.sql` contained `wp_users` (phpass password hashes,
emails of the site owner and a third person), Jetpack private options and other site
data. `mysql.Dockerfile` copied it into the public Docker Hub image `mysql_ypip`.
**Fix:** dump deleted and purged from history. `*.sql` and `schema/` are git-ignored.
`mysql.Dockerfile` removed: the official `mysql:8.4` image is used, and you can seed it
locally from a private, git-ignored dump.

### C3. `wp-file-manager` plugin shipped
This plugin has a long record of critical vulnerabilities (e.g. CVE-2020-25213,
unauthenticated RCE through the bundled elFinder connector) and is a common way in
for WordPress compromises.
**Fix:** removed, together with other unused or hosting-specific plugins (`hello-dolly`,
`wp-plugin-hostgator`, the `endurance-page-cache` mu-plugin) and leftover
`temp-write-test-*` files.

## High

### H1. Hard-coded credentials
`rootPassword` / `wp-pass` were written in both compose files and in both Dockerfiles
(as `ENV`, which bakes them into image layers).
**Fix:** all credentials come from a git-ignored `.env` (see [`.env.example`](../.env.example)).
Compose fails fast if they are missing (`${VAR:?}`). Images contain no credentials.

### H2. Security group open to the world
SSH (22) plus unused ports 8080/1541/9092 and ICMP were open to `0.0.0.0/0`, and no
rules existed for node-to-node Kubernetes traffic.
**Fix:** [`aws_security_group`](../terraform/modules/aws_security_group/main.tf) module rewritten:
- only 80/443 are public;
- 22/6443 are allowed only from `admin_cidr_blocks`. This variable is required, has no
  default, and validation rejects `0.0.0.0/0`. In CI the runner IP is added just in time;
- intra-cluster traffic is allowed only through a self-referencing SG rule.

### H3. Database and admin tools exposed on the host
MySQL `3306` and phpMyAdmin were published on all interfaces.
**Fix:** MySQL is not published. WordPress and phpMyAdmin bind to `127.0.0.1`.
phpMyAdmin only starts on demand (`--profile tools`).

### H4. CI/CD credential handling
- Long-lived AWS access keys lived in GitHub Secrets and were passed as `sudo bash script.sh <secret> <key>`
  (visible in the process list and in traces).
- `docker login -p <password>` was used.
- Secrets were set at workflow level, so every job and step (linter, third-party actions) could read them.
- `appleboy/telegram-action@master` (mutable ref) ran in the same job as the AWS credentials,
  which is a supply-chain risk.
- Feature branches pushed `:latest` images.

**Fix:**
- AWS auth via **GitHub OIDC**: no static keys. [`terraform/bootstrap`](../terraform/bootstrap/main.tf)
  creates a read-only *plan* role and an *apply* role that trusts **only** the protected
  `production` environment.
- Every action is pinned to a full commit SHA. Top-level `permissions: contents: read`.
  `id-token: write` is granted only to the Terraform jobs. `persist-credentials: false`.
- `docker/login-action` with an access token. The notification runs in an isolated job with no cloud credentials.
- Feature branches only build images. `master` pushes `:<sha>` and `:latest`.
- New `security_scan` job: Gitleaks (full history) + Checkov (Terraform, Dockerfile,
  GitHub Actions, secrets). `terraform fmt` / `validate` job.

### H5. No remote state; SSH private key handled insecurely
State only existed on the ephemeral CI runner. Every run forgot the previous
infrastructure and created new instances, leaving the old ones orphaned. The private
key was written with `echo '<key>' > key.pem` from `local-exec`.
**Fix:** S3 backend (SSE, versioning, TLS-only bucket policy, public access block,
native S3 locking `use_lockfile`). The key is written with `local_sensitive_file`
(mode 0400). The `private_key` output was removed. The kubespray script loads the key
into the agent and removes it on exit.

### H6. SSH host key verification disabled
`ssh -oStrictHostKeyChecking=no` was used.
**Fix:** `StrictHostKeyChecking=accept-new` with a dedicated known_hosts file. Ansible
no longer runs with `-vvv` (which dumps variables, tokens and certificates into CI logs).

## Medium

| # | Issue | Status |
|---|-------|--------|
| M1 | EBS unencrypted, IMDSv1 allowed | Fixed: `encrypted = true`, `http_tokens = "required"` |
| M2 | EOL / unpinned software: Ubuntu 18.04, MySQL 5.7, `wordpress:latest`, unpinned kubespray `master` | Fixed: Ubuntu 22.04 (Canonical-owned AMI), MySQL 8.4 LTS, `wordpress:6-php8.3-apache`, kubespray `v2.26.0` |
| M3 | Root `main.tf` ran `git add . && git commit && git push` from Terraform (risk of committing secrets/state) | Fixed: removed |
| M4 | 377 client photos (166 MB) in a public repo: third-party copyright and likenesses | Fixed: removed from tree and history, git-ignored |
| M6 | CI apply role had `AmazonEC2FullAccess` | Fixed: custom policy with only the actions the stack uses, locked to the region and this account; destructive actions are allowed only on resources tagged `Project` |
| M5 | Third-party plugins in the repo are not updated automatically | Open: plugins should be managed with Composer/WP-CLI instead of being vendored |

## Kubernetes workload hardening (`k8s/`)

- Namespace `ypip` with Pod Security Admission: `enforce: baseline`, `warn: restricted`.
- NetworkPolicies: default-deny ingress; only `ingress-nginx → wordpress:80`
  and `wordpress → mysql:3306` are allowed.
- DB credentials live in a Kubernetes Secret created at deploy time by
  `deploy_app.sh` from GitHub environment secrets. They are mounted as **files** (`*_FILE`), not env vars.
- MySQL runs as non-root (UID 999). WordPress drops all capabilities except the
  six Apache needs. `allowPrivilegeEscalation: false`, `seccomp: RuntimeDefault`,
  and no service-account token is mounted.
- Immutable image tags (git SHA) at deploy time, memory limits, liveness/readiness probes.
- `production` overlay: TLS via cert-manager + Let's Encrypt, HTTP→HTTPS redirect.
- Accepted risks are annotated on each workload (`checkov.io/skip*`) with the reason.

> The securityContext settings were validated statically (kustomize build + Checkov),
> not yet on a running cluster.

## Applying the history rewrite

```bash
pip install git-filter-repo
./scripts/purge-history.sh https://github.com/PavelMalachovski/YourPhotographerInPrague.git
cd ypip-clean.git && git push --force --mirror origin
```

Afterwards:
- re-clone all local copies;
- delete or make private the old Docker Hub image `pavelmalachovski/mysql_ypip`;
- optionally, ask GitHub Support to purge cached views of the removed commits.

## CI setup checklist

1. `cd terraform/bootstrap && terraform init && terraform apply -var state_bucket_name=<unique>`
2. Repository **variables**: `TF_STATE_BUCKET`, `AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN`, `ADMIN_CIDR` (e.g. `203.0.113.10/32`).
3. Repository **secrets**: `MY_DOCKERHUB_USERNAME`, `MY_DOCKERHUB_TOKEN` (Docker Hub access token, not the password), `TELEGRAM_TO`, `TELEGRAM_TOKEN`.
   **Environment `production` secrets**: `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD` (`openssl rand -base64 24`).
   Optional variable `K8S_OVERLAY=production`, after you set the domain and e-mail in `k8s/overlays/production/`.
   Delete the old `MY_AWS_ACCESS_KEY`, `MY_AWS_SECRET_KEY` and `MY_DOCKERHUB_PASSWORD`, and deactivate that IAM access key.
4. Settings → Environments → `production`: required reviewer, deployment branch `master`.
