#!/bin/zsh
# Aufruf: ./run.sh "SELECT …" ["SELECT …"]  – nur lesend gegen die JTL-Wawi.
# Baut bei Bedarf den SSH-Tunnel über node1 auf (Port 14330 → c10330:50000, Befehl aus Meesenburg.SiseShop.POC/ZUSAMMENFASSUNG.md)
# und liest die Verbindung aus den AppHost-User-Secrets (Parameters:jtl-sql), ohne sie auszugeben.
lsof -iTCP:14330 -sTCP:LISTEN >/dev/null 2>&1 || ssh -f -N -o ExitOnForwardFailure=yes \
  -L 50443:c10330.servers.ecomdata.de:50443 -L 58080:c10330.servers.ecomdata.de:58080 -L 14330:c10330.servers.ecomdata.de:50000 \
  -i ~/.ssh/hetzner_shop mpiper@136.243.107.86 || exit 1
dotnet user-secrets list --project ~/repos/Meesenburg.SiseShop.POC/src/Meesenburg.SiseShop.AppHost \
  | sed -n 's/^Parameters:jtl-sql = //p' \
  | dotnet run --no-build --project "${0:A:h}" -- "$@"
