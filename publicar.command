#!/bin/bash
# Publica la guía Cardiocete 2026 en GitHub Pages.
# Doble clic en macOS (o: bash publicar.command). Idempotente: se puede volver a ejecutar para actualizar.
set -e
cd "$(dirname "$0")"
OWNER="nestorguerra"
REPO="cardiocete-2026"
URL="https://${OWNER}.github.io/${REPO}/"

echo "▶ Comprobando GitHub CLI…"
if ! command -v gh >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then brew install gh; else
    echo "✗ Falta 'gh' (GitHub CLI). Instálalo desde https://cli.github.com y vuelve a ejecutar."; exit 1; fi
fi
gh auth status >/dev/null 2>&1 || gh auth login --web --git-protocol https

echo "▶ Preparando repositorio local…"
if [ ! -d .git ]; then git init -q; fi
git checkout -q -B main
git add -A
git -c user.name="Néstor Guerra" -c user.email="nestor@ncompany.es" commit -q -m "Cardiocete 2026 · guía móvil" || echo "  (sin cambios nuevos)"

echo "▶ Creando/actualizando repo ${OWNER}/${REPO} en GitHub…"
if gh repo view "${OWNER}/${REPO}" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/${OWNER}/${REPO}.git"
  git push -u origin main
else
  gh repo create "${OWNER}/${REPO}" --public --source=. --remote=origin --push \
    --description "Guía móvil del V Congreso de Cardiología Cardiocete 2026"
fi

echo "▶ Activando GitHub Pages (rama main, raíz)…"
if ! gh api "repos/${OWNER}/${REPO}/pages" >/dev/null 2>&1; then
  gh api -X POST "repos/${OWNER}/${REPO}/pages" --input - <<< '{"source":{"branch":"main","path":"/"}}' >/dev/null
fi

echo "▶ Esperando a que la página esté en línea…"
for i in $(seq 1 40); do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || true)
  if [ "$code" = "200" ]; then echo "✓ En línea: $URL"; open "$URL" 2>/dev/null || true; exit 0; fi
  sleep 5
done
echo "⚠ Todavía no responde (suele tardar 1–3 min la primera vez). Comprueba en: https://github.com/${OWNER}/${REPO}/settings/pages"
echo "URL final: $URL"
