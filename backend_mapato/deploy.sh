#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy.sh  —  Release + deploy pipeline for depot backend
#
# Usage:
#   ./deploy.sh release          # git commit/push → build image → deploy live
#   ./deploy.sh release "msg"    # same with a custom commit message
#   ./deploy.sh deploy           # build image → deploy live (no git push)
#   ./deploy.sh migrate          # run pending migrations on production only
# ---------------------------------------------------------------------------

set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────────────
IMAGE="magaiwa/depot:latest"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
REMOTE_USER="deploy"
REMOTE_HOST="169.58.188.122"
REMOTE_DIR="/www/depot"
CONTAINER="depot_backend"

# ── Helpers ─────────────────────────────────────────────────────────────────
log()  { echo -e "\033[1;34m[depot]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[ok]\033[0m $*"; }
err()  { echo -e "\033[1;31m[error]\033[0m $*" >&2; exit 1; }

ssh_run() {
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$@"
}

git_push() {
  local msg="${1:-Deploy $(date '+%Y-%m-%d %H:%M')}"

  log "Staging all changes..."
  git add -A

  if git diff --cached --quiet; then
    log "Nothing new to commit — skipping git commit."
  else
    log "Committing: $msg"
    git commit -m "$msg

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
  fi

  log "Pushing to origin/master..."
  git push origin master
  ok "Git push done."
}

build_image() {
  log "Building Docker image: $IMAGE ..."
  docker build -t "$IMAGE" .
  ok "Image built."
}

push_image() {
  log "Pushing image to Docker Hub: $IMAGE ..."
  docker push "$IMAGE"
  ok "Image pushed."
}

deploy_server() {
  log "Pulling new image on server..."
  ssh_run "cd $REMOTE_DIR && docker compose pull"

  log "Restarting container..."
  ssh_run "cd $REMOTE_DIR && docker compose up -d"
  ok "Container restarted."
}

run_migrations() {
  log "Running migrations on production..."
  ssh_run "docker exec $CONTAINER php artisan migrate --force"
  ok "Migrations done."
}

# ── Commands ────────────────────────────────────────────────────────────────
CMD="${1:-help}"
MSG="${2:-}"

case "$CMD" in
  release)
    log "=== RELEASE ==="
    git_push "${MSG:-Deploy $(date '+%Y-%m-%d %H:%M')}"
    build_image
    push_image
    deploy_server
    run_migrations
    ok "=== Release complete. Live at https://depot.magrethschools.sc.tz ==="
    ;;

  deploy)
    log "=== DEPLOY (no git push) ==="
    build_image
    push_image
    deploy_server
    run_migrations
    ok "=== Deploy complete. Live at https://depot.magrethschools.sc.tz ==="
    ;;

  migrate)
    log "=== MIGRATE ONLY ==="
    run_migrations
    ;;

  *)
    echo "Usage:"
    echo "  ./deploy.sh release [\"commit message\"]   # git push + build + deploy"
    echo "  ./deploy.sh deploy                        # build + deploy (no git)"
    echo "  ./deploy.sh migrate                       # run migrations only"
    exit 1
    ;;
esac
