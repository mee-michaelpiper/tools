#!/usr/bin/env bash
# Schlanke forensische Sicherung node3 + node2 (SN24) ins Image "Backup Shop".
# Ablauf je Server: Sammeln in /root/sicherung_<ts> (sudo) -> SHA-256 -> rsync -> lokal prüfen -> Server-Temp löschen.
# Am laufenden System wird nichts verändert (keine Neustarts, nur Lesen/Dumps).
# Aufruf:  bash tools/backup_node2_node3.sh node3   bzw.   ... node2
set -euo pipefail

node="${1:?node2 oder node3}"
case $node in
  node3) ip=136.243.110.31 ;;
  node2) ip=136.243.110.39 ;;
  *) echo "unbekannt: $node"; exit 1 ;;
esac

KEY="$HOME/.ssh/hetzner_shop"
KH="$HOME/.ssh/known_hosts_sn24"
ROOT="/Volumes/Backup Shop/SN24_20261009_0545"
TS="$(date -u +%Y%m%d_%H%M)"
SSHOPT="-o BatchMode=yes -o UserKnownHostsFile=$KH -i $KEY"
dest="$ROOT/${node}_${TS}"

log(){ printf '[%s] %s\n' "$(date +%T)" "$*"; }
free_mb(){ df -m "$ROOT" | awk 'NR==2{print $4}'; }
rsh(){ ssh $SSHOPT "mpiper@$ip" "$@" 2> >(grep -v "unable to resolve" >&2); }

[ -d "$ROOT" ] || { echo "Image nicht gemountet: $ROOT"; exit 1; }

# ---------- Remote-Teil (läuft als root auf dem Server) ----------
read -r -d '' remote_common <<EOF || true
set -u
T=/root/sicherung_$TS
mkdir -p "\$T" && cd "\$T"
exec 2>>"\$T/_fehler.txt"
{ date -u; hostname; uptime; echo; who; echo; last -n 50 -F; } > zustand_sitzungen.txt
ps -ef --forest > zustand_prozesse.txt
ss -tunap > zustand_verbindungen.txt
docker ps -a --no-trunc > docker_ps.txt
docker images --digests > docker_images.txt
docker inspect \$(docker ps -aq) > docker_inspect.json
docker compose ls > docker_compose_ls.txt
mkdir -p docker_logs
for id in \$(docker ps -aq --no-trunc); do
  n=\$(docker inspect -f '{{.Name}}' "\$id" | tr -d /)
  f=\$(docker inspect -f '{{.LogPath}}' "\$id")
  [ -n "\$f" ] && [ -f "\$f" ] && cat "\$f"* | gzip > "docker_logs/\${n}.json.log.gz"
done
tar czf etc.tgz /etc
tar czf var_log.tgz --exclude=/var/log/journal /var/log
journalctl --no-pager -o short-iso -u ssh | gzip > journal_ssh.txt.gz
journalctl --no-pager -o short-iso --since 2026-06-01 | gzip > journal_ab_juni.txt.gz
tar czf ssh_und_historien.tgz --ignore-failed-read /root/.ssh /root/.bash_history /home/admin/.ssh /home/admin/.bash_history /home/admin/.ansible /root/.ansible
[ -d /home/admin/traefik ] && tar czf traefik.tgz /home/admin/traefik
EOF

read -r -d '' remote_node3 <<'EOF' || true
tar czf configurators.tgz --exclude=node_modules /home/admin/configurators
EOF

read -r -d '' remote_node2 <<'EOF' || true
P=/home/admin/SN24_test
git -C "$P" log -n 50 --format="%H %ad %an <%ae> %s" --date=iso > git_log.txt
git -C "$P" status > git_status.txt
git -C "$P" diff > git_diff.patch
git -C "$P" ls-files --others --exclude-standard > git_untracked.txt
tar czf code_ohne_db.tgz --exclude=persistence_files --exclude=node_modules --exclude=cms/db/data --exclude=rabbit_mq/dbs --exclude=.git --exclude=static/frontend/assets --exclude=.venv "$P"
ls -laR "$P/static/frontend/assets" > liste_static_assets.txt
tar czf git_dir.tgz -C "$P" .git
find "$P" -name ".env*" -not -path "*/node_modules/*" -print0 | tar czf env_dateien.tgz --null -T -
find "$P" -path "*order_attachments*" -type f -print0 | tar czf auftrags_pdfs.tgz --null -T -
mkdir -p db_dumps
for c in business auth payment items; do
  docker exec "sn24_test-${c}_mongo-1" sh -c 'u=${MONGODB_INITDB_ROOT_USERNAME:-${MONGO_INITDB_ROOT_USERNAME:-}}; p=${MONGODB_INITDB_ROOT_PASSWORD:-${MONGO_INITDB_ROOT_PASSWORD:-}}; mongodump --quiet --username "$u" --password "$p" --authenticationDatabase admin --archive --gzip' > "db_dumps/${c}_mongo.archive.gz" || echo "DUMP FEHLGESCHLAGEN: $c" >> _fehler.txt
done
docker exec sn24_test-strapi_db-1 sh -c 'mariadb-dump -uroot -p"${MARIADB_ROOT_PASSWORD:-$MYSQL_ROOT_PASSWORD}" --all-databases --single-transaction' | gzip > db_dumps/strapi_mariadb.sql.gz || echo "DUMP FEHLGESCHLAGEN: strapi_db" >> _fehler.txt
EOF

read -r -d '' remote_finish <<'EOF' || true
cd "$T"
find . -type f ! -name _sha256.txt -print0 | sort -z | xargs -0 sha256sum > _sha256.txt
du -sm "$T" | cut -f1
EOF

[ "$node" = node3 ] && extra=$remote_node3 || extra=$remote_node2

log "== $node ($ip) -> $dest   frei im Image: $(free_mb) MB"
log "Sammeln auf dem Server ..."
size_mb=$(printf '%s\n%s\n%s\n' "$remote_common" "$extra" "$remote_finish" | rsh 'sudo bash -s' | tail -1)
log "Größe auf dem Server: ${size_mb} MB"
[ "$size_mb" -lt "$(( $(free_mb) - 300 ))" ] || { echo "Passt nicht ins Image – Abbruch, Server-Temp bleibt: /root/sicherung_$TS"; exit 1; }

log "Übertragen ..."
mkdir -p "$dest"
rsync -a -e "ssh $SSHOPT" --rsync-path="sudo rsync" "mpiper@$ip:/root/sicherung_$TS/" "$dest/" 2> >(grep -v "unable to resolve" >&2)

log "Prüfsummen lokal prüfen ..."
if (cd "$dest" && shasum -a 256 -c _sha256.txt --quiet); then
  log "Prüfsummen OK – lösche Server-Temp"
  rsh "sudo rm -rf /root/sicherung_$TS"
  pr="OK ($(wc -l < "$dest/_sha256.txt" | tr -d ' ') Dateien)"
else
  pr="PRÜFSUMMEN-FEHLER – Server-Temp bleibt: /root/sicherung_$TS"
fi
echo "$pr" > "$dest/_pruefung.txt"
if [ -s "$dest/_fehler.txt" ]; then log "Hinweise (_fehler.txt):"; grep -v "Removing leading" "$dest/_fehler.txt" | head -20 || true; fi

cat >> "$ROOT/_PROTOKOLL.md" <<EOF

# Sicherung $node ($ip) – $TS UTC
- Zugriff als \`mpiper\`, Ziel \`${node}_${TS}\`, schlanker Umfang (tools/backup_node2_node3.sh)
- Prüfung: $pr; Größe: $(du -sh "$dest" | cut -f1)
EOF
log "Fertig. Frei im Image: $(free_mb) MB"
