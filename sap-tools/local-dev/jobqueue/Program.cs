// Nur Dev: Job in Dev-ES-Worker einreihen bzw. Stand von Job und Dev-ES-Search anzeigen.
using Meesenburg.ES.Jobs.Contracts.Models;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));
var client = new MongoClient(Environment.GetEnvironmentVariable("MONGO_CS"));
var jobs = client.GetDatabase("Dev-ES-Worker").GetCollection<EsJob>("Jobs");
switch (args[0])
{
    case "queue":
        var job = new EsJob { Id = Guid.NewGuid(), JobType = JobType.SearchIndex, RequestedBy = "lokaler Test", IdempotencyKey = Guid.NewGuid().ToString("N"),
            FilterJson = args.Length > 1 ? args[1] : null };
        await jobs.InsertOneAsync(job);
        Console.WriteLine(job.Id);
        break;
    case "status":
        var j = await jobs.Find(x => x.Id == Guid.Parse(args[1])).FirstOrDefaultAsync();
        Console.WriteLine($"{j?.Status} processed={j?.ProcessedCount} error={j?.LastError} start={j?.StartedAtUtc:T} end={j?.FinishedAtUtc:T}");
        foreach (var m in await client.GetDatabase("Dev-ES-Search").GetCollection<BsonDocument>("SearchMeta").Find(_ => true).ToListAsync())
            Console.WriteLine(m.ToJson());
        break;
}
