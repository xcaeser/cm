#!/bin/bash
set -e

# Usage: ./release.sh 0.1.0
# This script commits changes, tags a new version, and pushes to GitHub.
# The GitHub Action workflow will handle the release creation.

VERSION=$1
NOTES_FILE="RELEASE-NOTES.md"

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

if [ ! -f "$NOTES_FILE" ]; then
  echo "❌ Release notes file '$NOTES_FILE' not found. Please create it before releasing."
  exit 1
fi

echo "Releasing v$VERSION..."


git add .

git commit -m "docs: Prepare release v$VERSION" || true

echo "Tagging and pushing..."

git tag -a "v$VERSION" -F "$NOTES_FILE"
git push origin main
git push origin "v$VERSION"

echo "✅ Tag v$VERSION pushed to GitHub. The release workflow has been triggered."
echo "   Check the 'Actions' tab in your repository for progress."