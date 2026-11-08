#!/usr/bin/env bash
# Create a new ROI Training course repo from this authoring template.
#
# Usage:
#   scripts/new-course.sh <course-folder> [--github owner/repo] [--private]
#
# Examples:
#   scripts/new-course.sh ../my-terraform-course
#   scripts/new-course.sh ../my-terraform-course --github roitraining/my-terraform-course --private
#
# The script copies this template (without git history, the sample course, the
# factory demo, or a leftover course outline), runs git init, and makes the
# first commit. With --github it creates a GitHub repo and pushes.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/new-course.sh <course-folder> [--github owner/repo] [--private]

  course-folder     Destination directory (created; must not already exist)
  --github owner/repo   Create that GitHub repository with gh and push
  --private         Make the GitHub repository private (default: public)

Windows: run this from Git Bash or WSL.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

DEST_ARG=""
GITHUB_REPO=""
PRIVATE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --github)
      GITHUB_REPO="${2:-}"
      if [[ -z "$GITHUB_REPO" ]]; then
        echo "error: --github requires owner/repo" >&2
        exit 1
      fi
      shift 2
      ;;
    --private)
      PRIVATE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$DEST_ARG" ]]; then
        echo "error: unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      DEST_ARG="$1"
      shift
      ;;
  esac
done

if [[ -z "$DEST_ARG" ]]; then
  echo "error: course-folder is required" >&2
  usage >&2
  exit 1
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: '$1' is not installed or not on PATH." >&2
    echo "$2" >&2
    exit 1
  fi
}

need_cmd git "Install Git: https://git-scm.com/downloads"

if [[ -n "$GITHUB_REPO" ]]; then
  need_cmd gh "Install GitHub CLI: https://cli.github.com/"
  if ! gh auth status >/dev/null 2>&1; then
    echo "error: GitHub CLI is installed but you are not signed in." >&2
    echo "Run: gh auth login" >&2
    exit 1
  fi
  if [[ "$GITHUB_REPO" != */* || "$GITHUB_REPO" == */ || "$GITHUB_REPO" == /* ]]; then
    echo "error: --github must be owner/repo (got: $GITHUB_REPO)" >&2
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$(mkdir -p "$(dirname "$DEST_ARG")" && cd "$(dirname "$DEST_ARG")" && pwd)/$(basename "$DEST_ARG")"

if [[ "$DEST" == "$TEMPLATE_ROOT" ]]; then
  echo "error: destination cannot be the template itself" >&2
  exit 1
fi

if [[ -e "$DEST" ]]; then
  echo "error: destination already exists: $DEST" >&2
  exit 1
fi

echo "Template: $TEMPLATE_ROOT"
echo "New course: $DEST"

mkdir -p "$DEST"

RSYNC_EXCLUDES=(
  --exclude '.git'
  --exclude '.DS_Store'
  --exclude 'introducing-the-roi-course-factory'
  --exclude 'course/sample-course.md'
  --exclude 'course/viewer-toolbar.png'
  --exclude 'course/images/sample-diagram.png'
  --exclude 'course/images/sample-team-of-programmers.png'
  --exclude 'labs/lab-01-sample-lab-viewer-format'
  --exclude 'plan/course-outline.md'
)

if command -v rsync >/dev/null 2>&1; then
  rsync -a "${RSYNC_EXCLUDES[@]}" "$TEMPLATE_ROOT/" "$DEST/"
else
  echo "note: rsync not found; using cp (excludes still applied)"
  # Copy then remove excluded paths so the command works without rsync.
  cp -R "$TEMPLATE_ROOT/." "$DEST/"
  rm -rf "$DEST/.git"
  rm -rf "$DEST/introducing-the-roi-course-factory"
  rm -rf "$DEST/labs/lab-01-sample-lab-viewer-format"
  rm -f "$DEST/course/sample-course.md"
  rm -f "$DEST/course/viewer-toolbar.png"
  rm -f "$DEST/course/images/sample-diagram.png"
  rm -f "$DEST/course/images/sample-team-of-programmers.png"
  rm -f "$DEST/plan/course-outline.md"
  find "$DEST" -name '.DS_Store' -delete
fi

# Empty working folders the author will fill.
mkdir -p "$DEST/plan" "$DEST/reviews" "$DEST/course/images" "$DEST/labs"

# Drop copied git artifacts that rsync might still bring if excludes missed them.
rm -rf "$DEST/.git"

cd "$DEST"
git init
git add .
# Identity comes from the user's existing git config. Do not set it here.
if git commit -m "Initial course repo from ROI Course Authoring Template"; then
  echo "Created first commit."
else
  echo "error: git commit failed. Set user.name and user.email, then commit in $DEST." >&2
  exit 1
fi

if [[ -n "$GITHUB_REPO" ]]; then
  VISIBILITY_FLAG="--public"
  if [[ "$PRIVATE" -eq 1 ]]; then
    VISIBILITY_FLAG="--private"
  fi
  gh repo create "$GITHUB_REPO" $VISIBILITY_FLAG --source=. --remote=origin --push
  echo "GitHub: https://github.com/$GITHUB_REPO"
fi

cat <<EOF

Done. Next:

  1. Open $DEST in Cursor, VS Code (Copilot), Claude Code, or another agent editor.
  2. Follow PIPELINE.md, starting at Step 1 (Course Architect).

EOF
