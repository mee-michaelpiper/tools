// Gezielte Einzeländerung in Mongo – Prod NUR nach ausdrücklicher Freigabe des Nutzers.
// Verbindung aus MONGO_CS. Gibt vorher/nachher aus.
//   dotnet run -- update <db> <collection> '<filter-json>' '<update-json>'   (UpdateOne, z. B. { "$set": { … } })
//   dotnet run -- insert <db> <collection> '<document-json>'
//   dotnet run -- delete <db> <collection> '<filter-json>'   (DeleteOne, nur bei genau 1 Treffer; gibt das Dokument vorher aus)
using MongoDB.Bson;
using MongoDB.Driver;

var client = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS"));
var col = client.GetDatabase(args[1]).GetCollection<BsonDocument>(args[2]);
switch (args[0])
{
    case "update":
        var filter = new BsonDocumentFilterDefinition<BsonDocument>(BsonDocument.Parse(args[3]));
        var before = await col.Find(filter).ToListAsync();
        if (before.Count != 1) { Console.WriteLine($"Abbruch: Filter trifft {before.Count} Dokumente (erwartet 1)"); return 1; }
        Console.WriteLine("vorher:  " + before[0].ToJson());
        var r = await col.UpdateOneAsync(filter, new BsonDocumentUpdateDefinition<BsonDocument>(BsonDocument.Parse(args[4])));
        Console.WriteLine($"matched={r.MatchedCount} modified={r.ModifiedCount}");
        Console.WriteLine("nachher: " + (await col.Find(filter).FirstOrDefaultAsync())?.ToJson());
        break;
    case "insert":
        var doc = BsonDocument.Parse(args[3]);
        await col.InsertOneAsync(doc);
        Console.WriteLine("eingefügt: " + doc.ToJson());
        break;
    case "delete":
        var delFilter = new BsonDocumentFilterDefinition<BsonDocument>(BsonDocument.Parse(args[3]));
        var hits = await col.Find(delFilter).ToListAsync();
        if (hits.Count != 1) { Console.WriteLine($"Abbruch: Filter trifft {hits.Count} Dokumente (erwartet 1)"); return 1; }
        Console.WriteLine("lösche: " + hits[0].ToJson());
        Console.WriteLine($"deleted={(await col.DeleteOneAsync(delFilter)).DeletedCount}");
        break;
    default:
        Console.WriteLine("update|insert|delete"); return 1;
}
return 0;
