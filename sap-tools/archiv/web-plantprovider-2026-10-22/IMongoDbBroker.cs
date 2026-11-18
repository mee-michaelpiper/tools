using Meesenburg.ES.Web.Configurations;

namespace Meesenburg.ES.Web.Brokers.Storage;

public interface IMongoDbBroker
{
    public interface IMongoBroker
    {
        Task<List<PlantConfiguration>> GetPlantConfigurationsAsync(CancellationToken ct = default);
    }
}