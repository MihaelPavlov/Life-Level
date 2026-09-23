namespace LifeLevel.Modules.Items.Application.UseCases;

public class ShopException(string code, string message) : InvalidOperationException(message)
{
    public string Code { get; } = code;
}
