namespace Meesenburg.ES.Web.Configurations;

public class MongoDbSettings
{
    public string? ConnectionString { get; set; }
    public string? DevDatabase { get; set; }
    public string? StageDatabase { get; set; }
    public string? ProdDatabase { get; set; }
    public string? SettingsCollectionName { get; set; }
    public string? PlantConfigurationCollectionName { get; set; }
    
    
}