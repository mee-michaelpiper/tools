
using Meesenburg.ES.Core.Extensions;
using Meesenburg.ES.Core.Models;
using Meesenburg.ES.Core.Provider;
using Meesenburg.ES.Web.Brokers.Storage;
using Meesenburg.ES.Web.Configurations;

namespace Meesenburg.ES.Web.Provider;

public sealed class PlantProvider : IPlantProvider
{
    private readonly IMongoDbBroker.IMongoBroker _mongoBroker;
    
    // Wir cachen das komplette Konfigurations-Objekt pro Plant
    private Dictionary<Plant, PlantConfiguration> _plantCache = new();

    public PlantProvider(IMongoDbBroker.IMongoBroker mongoBroker)
    {
        _mongoBroker = mongoBroker ?? throw new ArgumentNullException(nameof(mongoBroker));
    }

    // Gibt alle Plants zurück, die in der DB als 'Active' markiert sind
    public IReadOnlyCollection<Plant> SelectedPlants => 
        _plantCache
            .Where(x => x.Value.IsSelected)
            .Select(x => x.Key)
            .ToList();

    public bool IsSelected(Plant plant)
    {
        if (plant == Plant.Undefined) return false;
        
        return _plantCache.TryGetValue(plant, out var config) && config.IsSelected;
    }

    public async Task RefreshAsync(CancellationToken cancellationToken = default)
    {
        // Holt alle Einträge vom Broker
        var configs = await _mongoBroker.GetPlantConfigurationsAsync(cancellationToken);

        // Mappt die IDs auf das Enum und baut das Dictionary auf
        _plantCache = configs
            .Select(c => new { Config = c, Plant = PlantExtensions.FromId(c.PlantId) })
            .Where(x => x.Plant != Plant.Undefined)
            .ToDictionary(x => x.Plant, x => x.Config);
    }

}