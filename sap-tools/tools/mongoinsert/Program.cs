// Einmalig: Dokumente aus JSON-Datei einfügen – nur neue (_id darf nicht existieren), vorhandene bleiben unangetastet.
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Driver;

var client = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS"));
var col = client.GetDatabase(args[0]).GetCollection<BsonDocument>(args[1]);
var docs = BsonSerializer.Deserialize<BsonArray>(File.ReadAllText(args[2])).Select(v => v.AsBsonDocument).ToList();
var ids = docs.Select(d => d["_id"]).ToList();
var existing = (await col.Find(Builders<BsonDocument>.Filter.In("_id", ids)).Project(Builders<BsonDocument>.Projection.Include("_id")).ToListAsync()).Select(d => d["_id"]).ToHashSet();
var fresh = docs.Where(d => !existing.Contains(d["_id"])).ToList();
Console.WriteLine($"{docs.Count} in Datei, {existing.Count} schon vorhanden, {fresh.Count} neu");
if (fresh.Count > 0) await col.InsertManyAsync(fresh, new InsertManyOptions { IsOrdered = false });
Console.WriteLine($"eingefügt: {fresh.Count}");
