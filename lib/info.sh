# uvenv info  — cheat sheet of underlying mise + uv commands

_uvenv_info() {
    cat <<'EOF'
uvenv info — cheat sheet of the mise + uv commands uvenv wraps

Python version management (mise)
  mise install python@X.Y          install a specific Python
  mise use -g python@X.Y           set as global default       (uvenv set)
  mise current python              show currently-active Python
  mise ls python                   list installed Pythons
  mise exec python@X.Y -- <cmd>    run cmd with that Python

uv — venvs and packages
  uv venv <dir>                    create a venv
  uv venv <dir> --python X.Y       create a venv with a specific Python
  uv pip install <pkg>             install into active venv     (uvenv install)
  uv pip install -r reqs.txt       install from requirements
  uv pip install --upgrade <pkg>   upgrade a package            (uvenv update)
  uv pip list                      list packages
  uv pip list --outdated           list outdated packages
  uv pip uninstall <pkg>           uninstall package

uv — standalone CLI tools
  uv tool install <pkg>            install a CLI tool           (uvenv tool install)
  uv tool uninstall <pkg>          uninstall a CLI tool         (uvenv tool uninstall)
  uv tool list                     list installed tools         (uvenv tool list)

How uvenv composes them
  create     -> mise install + mise exec python@X -- uv venv ~/.uvenv/<name>
  activate   -> source ~/.uvenv/<name>/bin/activate   (shell function!)
  install    -> uv pip install (refuses to touch base Python without -y)
  update     -> uv pip install --upgrade
  tool       -> remembers current mise python, switches, runs uv tool, restores
  set        -> mise use -g python@X.Y
  self-update-> re-runs the bundled install.sh
EOF
}
