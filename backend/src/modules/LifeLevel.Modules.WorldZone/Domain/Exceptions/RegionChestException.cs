using LifeLevel.SharedKernel.Abstractions;

namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

public class RegionChestException(string code, string message) : DomainException(
    code,
    message,
    code == "region_not_found" ? DomainErrorKind.NotFound : DomainErrorKind.Conflict);
