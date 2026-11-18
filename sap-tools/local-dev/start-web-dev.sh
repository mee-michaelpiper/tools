#!/bin/zsh
# Lokales Portal (https://localhost:7009) gegen lokales sapdata und den lokalen Worker; Dev-ES-* Datenbanken
cd /Users/piper/repos/Meesenburg.ES
export Logging__Mongo__Enabled=false ConnectionStrings__keyVault=https://kv-meesenburg-prod.vault.azure.net/ News__MailEnabled=false Cache__Provider=Mongo
exec env services__meesenburg-es-api-sapdata__http__0=http://localhost:5241 services__meesenburg-es-dataworker__http__0=http://localhost:5471 \
  dotnet run --launch-profile https --project src/Meesenburg.ES.Web/Meesenburg.ES.Web.csproj
