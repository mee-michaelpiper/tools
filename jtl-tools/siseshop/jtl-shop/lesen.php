<?php
// Nur lesend: feste SELECTs auf Einstellungs-/Inhalts-Tabellen. Zugangsdaten aus der Shop-Konfiguration,
// werden nie ausgegeben. Werte mit Schlüssel-/Passwort-Namen werden maskiert. Keine Kunden-/Bestelldaten.
define('PFAD_ROOT', '/var/www/clients/client1/web33/web/');
require '/var/www/clients/client1/web33/web/includes/config.JTL-Shop.ini.php';
$pdo = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4', DB_USER, DB_PASS,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::MYSQL_ATTR_INIT_COMMAND => 'SET SESSION TRANSACTION READ ONLY']);
$pdo->exec('START TRANSACTION READ ONLY');
$secret = '/(pass|secret|key|token|pwd|apikey|api_key|client_id|clientid|merchant|signature|iban|bic|konto|sandbox_|webhook)/i';
$queries = json_decode(stream_get_contents(STDIN), true);
$out = [];
foreach ($queries as $name => $sql) {
    if (!preg_match('/^\s*(SELECT|SHOW|DESCRIBE)\b/i', $sql)) { $out[$name] = 'nur SELECT erlaubt'; continue; }
    try {
        $rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as &$r) {
            foreach ($r as $k => $v) {
                if (is_string($v) && (preg_match($secret, $k) || (isset($r['cName']) && preg_match($secret, (string)$r['cName']) && in_array($k, ['cWert','cValue'], true)))) $r[$k] = $v === '' ? '' : '***';
            }
        }
        $out[$name] = $rows;
    } catch (Throwable $e) { $out[$name] = 'Fehler: ' . $e->getMessage(); }
}
$pdo->exec('ROLLBACK');
echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
