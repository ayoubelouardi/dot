# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"        # Load NVM
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load NVM bash completion

nvm use 24 >/dev/null 2>&1 || true  # Activate installed Node version

# Self-heal: recreate npm/npx symlinks if missing (broken by interrupted root installs)
if command -v node >/dev/null 2>&1; then
  node_bin="$(dirname "$(command -v node)")"
  for pkg in npm npx; do
    if [ ! -e "$node_bin/$pkg" ]; then
      cli="$node_bin/../lib/node_modules/npm/bin/$pkg-cli.js"
      if [ -f "$cli" ]; then
        ln -sf "../lib/node_modules/npm/bin/$pkg-cli.js" "$node_bin/$pkg"
      fi
    fi
  done
fi
