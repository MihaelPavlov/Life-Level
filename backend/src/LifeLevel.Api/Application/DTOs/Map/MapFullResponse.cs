namespace LifeLevel.Api.Application.DTOs.Map;

public class MapFullResponse
{
    public List<MapNodeDto> Nodes { get; set; } = [];
    public List<MapEdgeDto> Edges { get; set; } = [];
    public UserMapProgressDto UserProgress { get; set; } = null!;
    public int CharacterLevel { get; set; }
}
