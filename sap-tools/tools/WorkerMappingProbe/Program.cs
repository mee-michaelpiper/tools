// Führt den Konstruktor Models.EsApi.Employee(SapApi.Employee) aus einem (alten) Worker-Build aus und zeigt das Kostenstellen-Mapping.
// Für Builds aus der Registry (crmeesenburg, meesenburg/es-dataworker): App-Layer entpacken, Pfad zum app-Ordner übergeben.
//   dotnet run -- <app-Ordner mit Meesenburg.ES.DataWorker.dll> [Kostenstellen …]
using System.Reflection;
using System.Runtime.Loader;

if (args[0] == "il") { IlMapping.Dump(Path.GetFullPath(args[1])); return; }
var dir = Path.GetFullPath(args[0]);
var costCenters = args.Length > 1 ? args[1..] : ["0190", "0211", "0291", "0295", "0490", "0590", "0992", "0999"];
var alc = new AssemblyLoadContext("probe", isCollectible: true);
alc.Resolving += (ctx, name) => File.Exists(Path.Combine(dir, name.Name + ".dll")) ? ctx.LoadFromAssemblyPath(Path.Combine(dir, name.Name + ".dll")) : null;
var asm = alc.LoadFromAssemblyPath(Path.Combine(dir, "Meesenburg.ES.DataWorker.dll"));
var sapType = asm.GetTypes().First(t => t.FullName!.EndsWith("Models.SapApi.Employee"));
var esType = asm.GetTypes().First(t => t.FullName!.EndsWith("Models.EsApi.Employee"));
var ctor = esType.GetConstructor([sapType]) ?? throw new Exception("Konstruktor Employee(SapApi.Employee) fehlt");
foreach (var cc in costCenters)
{
    var sap = Activator.CreateInstance(sapType)!;
    foreach (var p in sapType.GetProperties().Where(p => p.CanWrite && p.PropertyType == typeof(string)))
        p.SetValue(sap, p.Name switch { "EmployeeId" => "4711", "CostCenter" => cc, "StartDate" or "EndDate" => "20200101", _ => "x" });
    try
    {
        var es = ctor.Invoke([sap]);
        string V(string n) => esType.GetProperty(n)?.GetValue(es)?.ToString() ?? "-";
        Console.WriteLine($"KST {cc}: Gsnr {V("Gsnr"),-4} Kostenstelle {V("Kostenstelle"),-4} Ort {V("Ort")}");
    }
    catch (TargetInvocationException ex) { Console.WriteLine($"KST {cc}: Fehler {ex.InnerException?.Message}"); }
}

// Für Builds, die sich hier nicht laden lassen (ReadyToRun für linux-x64): IL des Konstruktors lesen und
// die Vergleiche „ldstr X / op_Equality / brtrue Ziel“ samt dem ersten ldc.i4 am Ziel ausgeben (Switch über Kostenstellen).
static class IlMapping
{
    public static void Dump(string dll)
    {
        using var fs = File.OpenRead(dll);
        using var pe = new System.Reflection.PortableExecutable.PEReader(fs);
        var md = System.Reflection.Metadata.PEReaderExtensions.GetMetadataReader(pe);
        var type = md.TypeDefinitions.Select(md.GetTypeDefinition)
            .First(t => md.GetString(t.Name) == "Employee" && md.GetString(t.Namespace).EndsWith("Models.EsApi"));
        foreach (var mh in type.GetMethods())
        {
            var m = md.GetMethodDefinition(mh);
            if (md.GetString(m.Name) != ".ctor" || m.RelativeVirtualAddress == 0) continue;
            var il = System.Reflection.Metadata.PEReaderExtensions.GetMethodBody(pe, m.RelativeVirtualAddress).GetILBytes()!;
            var ops = Decode(il);
            Console.WriteLine($"-- .ctor ({il.Length} Bytes IL)");
            for (var i = 0; i + 2 < ops.Count; i++)
            {
                if (ops[i].Op != "ldstr" || ops[i + 1].Op != "call") continue;
                var b = ops[i + 2];
                if (!b.Op.StartsWith("brtrue")) continue;
                var target = ops.FindIndex(o => o.Offset == (int)b.Arg!);
                var value = ops.Skip(target).Take(3).FirstOrDefault(o => o.Op.StartsWith("ldc.i4") || o.Op == "ldstr");
                var s = md.GetUserString(System.Reflection.Metadata.Ecma335.MetadataTokens.UserStringHandle((int)ops[i].Arg! & 0xFFFFFF));
                var v = value.Op == "ldstr" ? "\"" + md.GetUserString(System.Reflection.Metadata.Ecma335.MetadataTokens.UserStringHandle((int)value.Arg! & 0xFFFFFF)) + "\"" : value.Arg?.ToString();
                Console.WriteLine($"   IL_{ops[i].Offset:X4}: \"{s}\" => {v}");
            }
        }
    }

    record struct Ins(int Offset, string Op, object? Arg);

    static List<Ins> Decode(byte[] il)
    {
        var one = new Dictionary<short, System.Reflection.Emit.OpCode>();
        var two = new Dictionary<short, System.Reflection.Emit.OpCode>();
        foreach (var f in typeof(System.Reflection.Emit.OpCodes).GetFields())
        {
            var oc = (System.Reflection.Emit.OpCode)f.GetValue(null)!;
            if (oc.Size == 1) one[(short)(oc.Value & 0xFF)] = oc; else two[(short)(oc.Value & 0xFF)] = oc;
        }
        var list = new List<Ins>();
        for (var pos = 0; pos < il.Length;)
        {
            var start = pos;
            var oc = il[pos] == 0xFE ? two[il[pos + 1]] : one[il[pos]];
            pos += oc.Size;
            object? arg = null;
            switch (oc.OperandType)
            {
                case System.Reflection.Emit.OperandType.ShortInlineBrTarget: arg = pos + 1 + (sbyte)il[pos]; pos += 1; break;
                case System.Reflection.Emit.OperandType.InlineBrTarget: arg = pos + 4 + BitConverter.ToInt32(il, pos); pos += 4; break;
                case System.Reflection.Emit.OperandType.ShortInlineI: arg = (int)(sbyte)il[pos]; pos += 1; break;
                case System.Reflection.Emit.OperandType.ShortInlineVar: pos += 1; break;
                case System.Reflection.Emit.OperandType.InlineVar: pos += 2; break;
                case System.Reflection.Emit.OperandType.InlineI8 or System.Reflection.Emit.OperandType.InlineR: pos += 8; break;
                case System.Reflection.Emit.OperandType.ShortInlineR: pos += 4; break;
                case System.Reflection.Emit.OperandType.InlineSwitch: var n = BitConverter.ToInt32(il, pos); pos += 4 + 4 * n; break;
                case System.Reflection.Emit.OperandType.InlineNone: break;
                default: arg = BitConverter.ToInt32(il, pos); pos += 4; break;
            }
            var name = oc.Name!;
            if (name.StartsWith("ldc.i4.") && name.Length > 7 && arg is null) arg = name[7..] == "m1" ? -1 : name[7..] == "s" ? arg : int.Parse(name[7..]);
            list.Add(new Ins(start, name, arg));
        }
        return list;
    }
}
