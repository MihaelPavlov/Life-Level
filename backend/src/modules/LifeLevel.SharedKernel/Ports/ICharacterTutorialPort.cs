namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Cross-module port for tutorial step progression.
/// Used by the Activity module to advance the "log an activity" tutorial step (step 4)
/// without the caller needing to know about Character internals.
/// </summary>
public interface ICharacterTutorialPort
{
    /// <summary>
    /// Advances the tutorial step only if the character is currently on <paramref name="expectedStep"/>.
    /// Returns the step after the call (either the new step on success, or the unchanged current step
    /// when the character is not on the expected step — no-op).
    /// Implementations MUST be safe to call regardless of whether a character row exists;
    /// missing character is treated as a no-op.
    /// </summary>
    Task<int> AdvanceIfOnStepAsync(Guid characterId, int expectedStep, CancellationToken ct = default);
}
