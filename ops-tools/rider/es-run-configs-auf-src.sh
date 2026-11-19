#!/bin/bash
# Stellt die Rider-Run-/Debug-Konfigurationen von Meesenburg.ES auf die neue Ordnerstruktur um (18.11.2026: Projekte unter src/,
# ESDataWorker → src/Meesenburg.ES.DataWorker, Meesenburg.de.ES.API.ESData → src/Meesenburg.ES.API.ESData).
# NUR bei geschlossenem Rider ausführen – Rider schreibt workspace.xml beim Schließen neu. Legt vorher eine Sicherung an.
set -euo pipefail
W="$HOME/repos/Meesenburg.ES/.idea/.idea.Meesenburg.ES/.idea/workspace.xml"
pgrep -f "Rider.app/Contents/MacOS/rider" >/dev/null && { echo "Rider läuft noch – bitte erst schließen."; exit 1; }
cp "$W" "$W.bak-$(date +%Y%m%d-%H%M%S)"
python3 - "$W" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p,encoding='utf-8').read(); o=s
s=re.sub(r'\$PROJECT_DIR\$/ESDataWorker(?=[/"])', '$PROJECT_DIR$/src/Meesenburg.ES.DataWorker', s)
s=re.sub(r'\$PROJECT_DIR\$/Meesenburg\.de\.ES\.API\.ESData(?=[/"])', '$PROJECT_DIR$/src/Meesenburg.ES.API.ESData', s)
s=re.sub(r'\$PROJECT_DIR\$/(Meesenburg\.(?:ES|SAP)\.[A-Za-z.]+?)(?=[/"])', r'$PROJECT_DIR$/src/\1', s)
s=s.replace('All in Meesenburg.de.ES.API.ESData','All in Meesenburg.ES.API.ESData')
alt=len(re.findall(r'\$PROJECT_DIR\$/(?:ESDataWorker|Meesenburg\.[A-Za-z.]+)(?=[/"])',s))
open(p,'w',encoding='utf-8').write(s)
print(f"Pfade auf src/: {s.count('$PROJECT_DIR$/src/')}; alte Pfade übrig: {alt}")
PY
echo "Fertig. Sicherung: $W.bak-*  – Rider öffnen, Run-Konfigurationen prüfen."
