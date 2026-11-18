# TlsCaCheck – vertraut ein ES-Container einem internen Server? (26.10.2026)

RDP-Aushandlung + `SslStream` mit .NET-Standardprüfung, im Basis-Image der Dienste, einmal ohne und einmal mit `certs/*.crt` (wie `Dockerfile-Prod`).

    mkdir -p certs && cp ~/repos/Meesenburg.ES/src/certs/*.crt certs/
    docker build -q --target ohne-ca -t rdptls:ohne . && docker build -q --target mit-ca -t rdptls:mit .
    docker run --rm rdptls:ohne vmtses2k001.meesenburg.de; docker run --rm rdptls:mit vmtses2k001.meesenburg.de

Erwartung: ohne CA `PartialChain` (wie Mongo am 08.10.2026), mit CA „OK“. Nur RDP (Port 3389); für reine TLS-Dienste (IMAP 993, Mongo) die RDP-Aushandlung weglassen.
