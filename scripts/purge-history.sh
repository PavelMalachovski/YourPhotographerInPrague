#!/usr/bin/env bash
#=============================================================================
# Remove leaked secrets / PII from the ENTIRE git history.
#
# What gets purged from every commit:
#   - website/                 full hosting dump incl. wp-config.php (DB password,
#                              AUTH keys/salts), .htaccess, error_log
#   - db/, schema/, wordpress_static_data/schema/  and every *.sql
#                              WordPress DB dumps: user password hashes, emails
#   - *.wpress                 All-in-One WP Migration archives (site + DB)
#   - wp-content/uploads/     client photos (third-party copyright / likenesses)
#   - wp-config.php, *.pem, *.tfstate*, error_log   anywhere in the tree
#
# This REWRITES HISTORY. Every commit hash changes; anyone with a clone must
# re-clone. Run it once, from a fresh mirror clone, then force-push.
#
# Requirements: git-filter-repo  (pip install git-filter-repo)
#
# Usage:
#   ./scripts/purge-history.sh https://github.com/PavelMalachovski/YourPhotographerInPrague.git
#   # inspect the result in ./ypip-clean.git, then:
#   cd ypip-clean.git && git push --force --mirror origin
#=============================================================================
set -euo pipefail

REPO_URL="${1:?Usage: $0 <repo-url> [workdir]}"
WORKDIR="${2:-ypip-clean.git}"

command -v git-filter-repo >/dev/null || { echo "Install git-filter-repo first: pip install git-filter-repo" >&2; exit 1; }

rm -rf "${WORKDIR}"
git clone --mirror "${REPO_URL}" "${WORKDIR}"
cd "${WORKDIR}"

echo "Size before: $(git count-objects -vH | awk '/size-pack/ {print $2, $3}')"

git filter-repo --force --invert-paths \
  --path website/ \
  --path db/ \
  --path schema/ \
  --path wordpress_static_data/schema/ \
  --path wordpress_static_data/wordpress/wp-content/uploads/ \
  --path wordpress/wp-content/uploads/ \
  --path-glob '*.sql' \
  --path-glob '*.wpress' \
  --path-glob '*wp-config.php' \
  --path-glob '*.pem' \
  --path-glob '*.tfstate' \
  --path-glob '*.tfstate.*' \
  --path-glob '*error_log'

# filter-repo removes the origin remote as a safety measure; restore it.
git remote add origin "${REPO_URL}" 2>/dev/null || git remote set-url origin "${REPO_URL}"

git reflog expire --expire=now --all
git gc --prune=now --aggressive --quiet

echo "Size after:  $(git count-objects -vH | awk '/size-pack/ {print $2, $3}')"

echo
echo "Verification (each line must say 0):"
printf '  wp-config.php blobs : %s\n' "$(git log --all --name-only --pretty=format: | grep -c 'wp-config\.php$' || true)"
printf '  *.sql files         : %s\n' "$(git log --all --name-only --pretty=format: | grep -c '\.sql$' || true)"
printf '  *.wpress files      : %s\n' "$(git log --all --name-only --pretty=format: | grep -c '\.wpress$' || true)"
printf '  uploads/ paths      : %s\n' "$(git log --all --name-only --pretty=format: | grep -c 'wp-content/uploads/' || true)"
printf '  website/ paths      : %s\n' "$(git log --all --name-only --pretty=format: | grep -c '^website/' || true)"
echo
echo "Next steps:"
echo "  cd ${WORKDIR} && git push --force --mirror origin"
echo "  Then ask GitHub Support to purge cached views of the old commits"
echo "  (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)"
