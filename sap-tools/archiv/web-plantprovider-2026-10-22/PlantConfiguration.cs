namespace Meesenburg.ES.Web.Configurations;

public class PlantConfiguration
{
    // Die ID aus Mongo (z.B. 1000)
    public int PlantId { get; set; }
    
    // Das Flag für die Steuerung
    public bool IsSelected { get; set; }
    
    // Hier können später weitere Felder rein (z.B. SapClient, CompanyCode, etc.)
}