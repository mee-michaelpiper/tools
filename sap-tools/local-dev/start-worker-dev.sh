#!/bin/zsh
# Lokaler Worker im Dev-Profil (Dev-ES-Worker, Jobs nur aus Mongo, Prod-wirksame Jobtypen gesperrt)
cd /Users/piper/repos/Meesenburg.ES
export ASPNETCORE_ENVIRONMENT=Development DOTNET_ENVIRONMENT=Development ASPNETCORE_URLS=http://localhost:5471
export Logging__Mongo__Enabled=false ConnectionStrings__keyVault=https://kv-meesenburg-prod.vault.azure.net/
export ES_PROFILE=Dev MongoSettings__ProdDatabase=Dev-ES-Worker Jobs__Transport=Mongo Worker__RunJobsLocally=false
export Jobs__DisabledTypes__0=InvoiceMail Jobs__DisabledTypes__1=InvoiceDispatch Jobs__DisabledTypes__2=Accounting
exec env services__meesenburg-es-api-sapdata__http__0=http://localhost:5241 dotnet run --no-launch-profile --project src/Meesenburg.ES.DataWorker/Meesenburg.ES.DataWorker.csproj
