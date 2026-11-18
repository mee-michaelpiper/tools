FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY rdptls.csproj Program.cs ./
RUN dotnet publish -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS ohne-ca
USER $APP_UID
WORKDIR /app
COPY --from=build /out .
ENTRYPOINT ["dotnet", "rdptls.dll"]

# wie in den Dockerfile-Prod
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS mit-ca
USER root
COPY certs/*.crt /usr/local/share/ca-certificates/meesenburg/
RUN update-ca-certificates
USER $APP_UID
WORKDIR /app
COPY --from=build /out .
ENTRYPOINT ["dotnet", "rdptls.dll"]
