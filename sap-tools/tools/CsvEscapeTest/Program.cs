// Test (16.11.2026): Maskieren in der Übergabe-CSV (Worker, CsvHelpers) – Steuerzeichen und „;“ dürfen keine Zeile/Spalte erzeugen.
using ESDataWorker.Helpers;
var fail = 0;
void Check(string input, string expected)
{
    var got = CsvHelpers.EscapeField(input);
    var ok = got == expected && !got.Contains('\n') && !got.Contains('\r') && !got.Contains(';');
    Console.WriteLine($"{(ok ? "OK    " : "FEHLER")} {input.Replace("\n", "⏎")} → {got}");
    if (!ok) fail++;
}
Check("RE-4711\n", @"RE-4711\n");
Check("A\r\nB", @"A\r\nB");
Check("Tab\there", @"Tab\there");
Check("Steuer\u0001x", @"Steuer\x01x");
Check("Zeile" + (char)0x2028 + "Trenner", @"Zeile\x2028Trenner");
Check("a;b", "a,b");
Check("\"Zitat\"", "\"Zitat\"");
Check("Müller & Söhne", "Müller & Söhne");
Check("", "");
var line = CsvHelpers.ToCsvLine(["K", "11.11.2026", "57", "298", "11.11.2026", "11", "EUR", "910010999", "R123\n456", "", "", "", "", "", "", ""]);
var cols = line.Split(';').Length;
Console.WriteLine($"{(cols == 16 && !line.Contains('\n') ? "OK    " : "FEHLER")} Kopfzeile bleibt eine Zeile mit 16 Spalten: {line}");
if (cols != 16) fail++;
Console.WriteLine(fail == 0 ? "alle OK" : $"{fail} Fehler");
return fail;
