using Meesenburg.ES.Jobs.Contracts.Models;
using Meesenburg.ES.Jobs.Contracts.Models.Helpers;
using Meesenburg.ES.Core.Mongo;
using Meesenburg.ES.Jobs.Contracts.Models;
using Meesenburg.ES.Web.Configurations;
using Microsoft.Extensions.Options;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Meesenburg.ES.Web.Brokers.Storage;

public sealed class MongoDbBroker : IMongoDbBroker
{
    private readonly MongoDatabaseHolder holder;
    private readonly IOptionsMonitor<MongoDbSettings> settings;

    public MongoDbBroker(MongoDatabaseHolder holder, IOptionsMonitor<MongoDbSettings> settings)
    {
        this.holder = holder;
        this.settings = settings;
    }

    public async Task<List<PlantConfiguration>> GetPlantConfigurationsAsync(CancellationToken ct = default)
    {
        var db = await holder.GetDatabaseAsync();
        return await db.GetCollection<PlantConfiguration>(settings.CurrentValue.PlantConfigurationCollectionName).Find(new BsonDocument()).ToListAsync(ct);
    }
}