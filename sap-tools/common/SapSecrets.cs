// SAP-Zugang für die lokalen Tools aus dem Key Vault (seit 22.10.2026 nicht mehr in der SAPData-appsettings.json).
// Holt die Secrets per `az keyvault secret show` (angemeldetes az CLI), hält sie nur im Speicher und gibt sie nie aus.
// Einbinden per <Compile Include="…/common/SapSecrets.cs" /> im csproj.
using System.Diagnostics;
using System.Text.Json;

static class SapSecrets
{
    const string Vault = "kv-meesenburg-prod";

    static readonly Lazy<string> license = new(() => Get("ErpConnect-LicenseKey"));
    static readonly Lazy<(string User, string Password, string Client)> rfc = new(() =>
    {
        using var json = JsonDocument.Parse(Get("SapRfcCredentials"));
        var r = json.RootElement;
        return (r.GetProperty("User").GetString()!, r.GetProperty("Password").GetString()!,
                r.TryGetProperty("Client", out var c) ? c.GetString()! : "100");
    });

    public static string License => license.Value;
    public static (string User, string Password, string Client) Rfc => rfc.Value;

    static string Get(string name)
    {
        var psi = new ProcessStartInfo("az", ["keyvault", "secret", "show", "--vault-name", Vault, "--name", name, "--query", "value", "-o", "tsv"])
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };
        using var p = Process.Start(psi)!;
        var value = p.StandardOutput.ReadToEnd().Trim();
        var error = p.StandardError.ReadToEnd();
        p.WaitForExit();
        if (p.ExitCode != 0 || value.Length == 0)
            throw new InvalidOperationException($"Key-Vault-Secret „{name}“ nicht lesbar (az login?): {error.Split('\n').FirstOrDefault()}");
        return value;
    }
}
