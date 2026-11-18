// Nur lesend: gibt eine Mongo-Collection als JSON aus.
// Verbindung aus Umgebungsvariable MONGO_CS (z. B. per az keyvault secret show ... MongoDBConnectionString).
//   MONGO_CS=$(az keyvault secret show --vault-name kv-meesenburg-prod -n MongoDBConnectionString --query value -o tsv) \
//     dotnet run -- Prod-ES-Worker Customer-SalesOffices ['{ "Feld": "Wert" }']   (optional: Filter als JSON)
using MongoDB.Bson;
using MongoDB.Driver;

var client = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS"));
var docs = await client.GetDatabase(args[0]).GetCollection<BsonDocument>(args[1]).Find(args.Length > 2 ? new BsonDocumentFilterDefinition<BsonDocument>(BsonDocument.Parse(args[2])) : FilterDefinition<BsonDocument>.Empty).ToListAsync();
foreach (var d in docs) Console.WriteLine(d.ToJson());
