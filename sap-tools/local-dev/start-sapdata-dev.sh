#!/bin/zsh
# Lokales sapdata (liest SAP MEP); DYLD_* direkt setzen – über nohup/env entfernt macOS (SIP) sie
cd /Users/piper/repos/Meesenburg.ES
export ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=http://localhost:5241
export DYLD_LIBRARY_PATH=/usr/local/lib DYLD_FALLBACK_LIBRARY_PATH=/usr/local/lib
export Logging__Mongo__Enabled=false ConnectionStrings__keyVault=https://kv-meesenburg-prod.vault.azure.net/
exec dotnet run --no-launch-profile --project src/Meesenburg.ES.API.SAPData/Meesenburg.ES.API.SAPData.csproj
