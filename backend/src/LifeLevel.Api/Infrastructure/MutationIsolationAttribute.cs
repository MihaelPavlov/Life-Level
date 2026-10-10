using System.Data;

namespace LifeLevel.Api.Infrastructure;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class MutationIsolationAttribute(IsolationLevel isolationLevel) : Attribute
{
    public IsolationLevel IsolationLevel { get; } = isolationLevel;
}
