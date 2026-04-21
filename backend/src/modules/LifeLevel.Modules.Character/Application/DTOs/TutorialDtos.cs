namespace LifeLevel.Modules.Character.Application.DTOs;

// ─── Requests ──────────────────────────────────────────────────────────────
public record ReplayTopicRequest(string Topic);

// ─── Responses ────────────────────────────────────────────────────────────
// Keep these lightweight. The mobile client pulls a full CharacterProfileResponse
// via GET /api/character/me when it needs one; tutorial endpoints only return
// the two tutorial-specific fields plus any XP awarded on /advance.

public record AdvanceTutorialResponse(
    int TutorialStep,
    int TutorialTopicsSeen,
    int XpAwarded);

public record SkipTutorialResponse(
    int TutorialStep,
    int TutorialTopicsSeen);

public record ReplayAllTutorialResponse(
    int TutorialStep,
    int TutorialTopicsSeen);

public record ReplayTopicResponse(
    int TutorialStep,
    int TutorialTopicsSeen);
