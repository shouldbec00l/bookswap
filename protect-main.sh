#!/usr/bin/env bash
# Налаштовує Branch Protection для main. Потрібен gh CLI (gh auth login) і права admin.
# ENFORCE_ADMINS=true ./scripts/protect-main.sh  — діє і на власника репозиторію.
set -euo pipefail
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
ENFORCE_ADMINS="${ENFORCE_ADMINS:-false}"

gh api -X PUT "repos/${REPO}/branches/main/protection" --input - <<JSON
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Lint Dockerfiles",
      "Lint (backend)", "Lint (frontend)",
      "Test (backend)", "Test (frontend)",
      "Security (SCA)",
      "Build, scan & push (backend)", "Build, scan & push (frontend)"
    ]
  },
  "enforce_admins": ${ENFORCE_ADMINS},
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
echo "Protection enabled for ${REPO}:main"
