using LifeLevel.SharedKernel.Abstractions;

namespace LifeLevel.Modules.Items.Application.UseCases;

public class ShopException(string code, string message) :
    DomainException(code, message, DomainErrorKind.Conflict);
