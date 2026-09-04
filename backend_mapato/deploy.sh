#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy.sh  —  Fully automated release + deploy pipeline for depot backend
#
# Usage:
#   ./deploy.sh release          # git push → build → push image → live deploy
#   ./deploy.sh release "msg"    # same, with custom commit message
#   ./deploy.sh deploy           # build → push image → live deploy (no git)
#   ./deploy.sh migrate          # run migrations on production only
# ---------------------------------------------------------------------------

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
IMAGE="magaiwa/depot:latest"
DOCKERHUB_USER="magaiwa"

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
REMOTE_USER="deploy"
REMOTE_HOST="169.58.188.122"
REMOTE_DIR="/www/depot"
CONTAINER="depot_backend"
LIVE_URL="https://depot.magrethschools.sc.tz"

BOLD="\033[1m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

STEP=0

# ── Helpers ──────────────────────────────────────────────────────────────────
step() {
  STEP=$((STEP + 1))
  echo -e "\n${BLUE}[${STEP}]${RESET} ${BOLD}$*${RESET}"
}
ok()  { echo -e "${GREEN}    ✓ $*${RESET}"; }
warn(){ echo -e "${YELLOW}    ⚠ $*${RESET}"; }
err() { echo -e "${RED}    ✗ $*${RESET}" >&2; exit 1; }

banner() {
  echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║  depot deploy  —  $1${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
}

elapsed() {
  local end=$SECONDS
  local diff=$((end - START))
  printf "%dm %02ds" $((diff / 60)) $((diff % 60))
}

ssh_run() {
  ssh -i "$SSH_KEY" \
      -o StrictHostKeyChecking=no \
      -o ConnectTimeout=15 \
      "${REMOTE_USER}@${REMOTE_HOST}" "$@"
}

# ── Pre-flight checks ────────────────────────────────────────────────────────
check_deps() {
  step "Pre-flight checks"

  command -v docker >/dev/null 2>&1 || err "docker not found — install Docker Desktop"
  command -v git    >/dev/null 2>&1 || err "git not found"
  command -v ssh    >/dev/null 2>&1 || err "ssh not found"

  [ -f "$SSH_KEY" ] || err "SSH key not found: $SSH_KEY"
  ok "Dependencies OK"

  # Docker daemon running?
  docker info >/dev/null 2>&1 || err "Docker daemon is not running — start Docker Desktop"
  ok "Docker daemon running"

  # Docker Hub login — auto-login if credentials stored, else prompt once
  if ! docker info 2>/dev/null | grep -q "Username"; then
    warn "Not logged in to Docker Hub — logging in..."
    docker login --username "$DOCKERHUB_USER" \
      || err "Docker Hub login failed. Run: docker login"
  fi
  ok "Docker Hub authenticated"

  # SSH reachable?
  ssh_run "echo 'SSH OK'" >/dev/null 2>&1 || err "Cannot reach $REMOTE_HOST via SSH"
  ok "SSH to $REMOTE_HOST OK"
}

# ── Steps ────────────────────────────────────────────────────────────────────
git_push() {
  local msg="$1"
  step "Git — commit & push"

  git add -A

  if git diff --cached --quiet; then
    warn "Nothing to commit — skipping commit step"
  else
    git commit -m "${msg}

Co-Authored-By: Samwel Magaiwa <samwelmagaiwa229@gmail.com>"
    ok "Committed: $msg"
  fi

  git push origin master
  ok "Pushed to origin/master"
}

build_image() {
  step "Docker — build image"
  local tag
  tag="${IMAGE%:*}:$(date '+%Y%m%d%H%M')"   # timestamped tag for traceability

  docker build \
    --label "build.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "build.git=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
    -t "$IMAGE" \
    -t "$tag" \
    . \
    || err "Docker build failed"

  ok "Image built → $IMAGE"
  ok "Also tagged  → $tag"
}

push_image() {
  step "Docker Hub — push image"
  docker push "$IMAGE" || err "Docker push failed — are you logged in? (docker login)"
  ok "Pushed $IMAGE"
}

deploy_server() {
  step "Server — pull new image & restart"
  ssh_run "cd $REMOTE_DIR && docker compose pull" \
    || err "docker compose pull failed on server"
  ok "Image pulled on server"

  ssh_run "cd $REMOTE_DIR && docker compose up -d --remove-orphans" \
    || err "docker compose up failed on server"
  ok "Container restarted"

  # Brief wait then health check
  sleep 3
  local http_code
  http_code=$(ssh_run "curl -s -o /dev/null -w '%{http_code}' --max-time 8 $LIVE_URL/api/health || echo 000")
  if [ "$http_code" = "200" ]; then
    ok "Health check passed (HTTP $http_code)"
  else
    warn "Health endpoint returned HTTP $http_code — check logs if needed"
  fi
}

run_migrations() {
  step "Laravel — run migrations"
  ssh_run "docker exec $CONTAINER php artisan migrate --force" \
    || err "Migrations failed"
  ok "Migrations applied"
}

clear_cache() {
  step "Laravel — clear caches"
  ssh_run "docker exec $CONTAINER php artisan config:cache && \
           docker exec $CONTAINER php artisan route:cache && \
           docker exec $CONTAINER php artisan view:clear" 2>/dev/null \
    && ok "Caches cleared" \
    || warn "Cache clear had warnings (non-fatal)"
}

# ── Commands ─────────────────────────────────────────────────────────────────
CMD="${1:-help}"
MSG="${2:-Deploy $(date '+%Y-%m-%d %H:%M')}"
START=$SECONDS

case "$CMD" in

  release)
    banner "RELEASE"
    check_deps
    git_push "$MSG"
    build_image
    push_image
    deploy_server
    run_migrations
    clear_cache
    echo -e "\n${GREEN}${BOLD}✓ Release complete in $(elapsed)${RESET}"
    echo -e "${GREEN}${BOLD}  Live → $LIVE_URL${RESET}\n"
    ;;

  deploy)
    banner "DEPLOY  (no git push)"
    check_deps
    build_image
    push_image
    deploy_server
    run_migrations
    clear_cache
    echo -e "\n${GREEN}${BOLD}✓ Deploy complete in $(elapsed)${RESET}"
    echo -e "${GREEN}${BOLD}  Live → $LIVE_URL${RESET}\n"
    ;;

  migrate)
    banner "MIGRATE ONLY"
    check_deps
    run_migrations
    echo -e "\n${GREEN}${BOLD}✓ Done in $(elapsed)${RESET}\n"
    ;;

  *)
    echo -e "\n${BOLD}Usage:${RESET}"
    echo "  ./deploy.sh release [\"message\"]   git push + build + deploy + migrate"
    echo "  ./deploy.sh deploy                build + deploy + migrate  (no git)"
    echo "  ./deploy.sh migrate               run migrations on server only"
    echo ""
    echo -e "${BOLD}Environment overrides:${RESET}"
    echo "  SSH_KEY=/path/to/key ./deploy.sh release"
    echo ""
    exit 1
    ;;
esac
