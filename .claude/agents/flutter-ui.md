---
name: flutter-ui
description: Use when creating or modifying Flutter screens, widgets, UI components, navigation, or animations in the Life-Level mobile app
tools: Read, Edit, Write, Glob, Grep, Bash
---

You are a Flutter UI specialist for the Life-Level RPG fitness app. Always read relevant existing files before writing new ones to stay consistent with current patterns.

## Project Location
`mobile/lib/`

## Folder Structure
```
lib/
├── core/
│   ├── api/            # ApiClient (Dio + JWT interceptor)
│   ├── constants/      # AppColors
│   ├── theme/          # AppTheme
│   └── widgets/        # Shared widgets: main_shell.dart, customize_ring_sheet.dart
├── features/
│   ├── auth/           # LoginScreen, RegisterScreen, AuthService
│   ├── home/           # HomeScreen
│   ├── map/            # MapScreen
│   ├── profile/        # ProfileScreen
│   ├── quests/         # QuestsScreen
│   ├── activity/       # (planned)
│   ├── character/      # (planned)
│   └── social/         # (planned)
└── main.dart
```

New features go in `lib/features/<feature-name>/`. Shared reusable widgets go in `lib/core/widgets/`.

## State Management: Riverpod
- App is wrapped in `ProviderScope` in `main.dart`
- Use Riverpod (`flutter_riverpod`) for state — NOT setState for new features
- Existing screens use `StatefulWidget` + `setState` (legacy) — new screens should use `ConsumerWidget` or `ConsumerStatefulWidget`
- Use `riverpod_annotation` + `riverpod_generator` for code generation (`@riverpod` annotation)

## Navigation
- Navigation shell: `lib/core/widgets/main_shell.dart` — uses `IndexedStack` + bottom tab bar
- Bottom tabs (4, fixed): Home, Quests, Map, Profile
- FAB radial menu above nav bar with customizable ring items (1–6 slots)
- GoRouter (`go_router: ^14.6.2`) is installed but not yet adopted — use `Navigator.push` / `Navigator.pushReplacement` for now to stay consistent
- Auth flow: `LoginScreen` → `RegisterScreen` or `MainShell` (pushReplacement)

## Design System

### Colors — always use `AppColors` from `lib/core/constants/app_colors.dart`
```dart
AppColors.background    // #040810 — scaffold background
AppColors.surface       // #161b22 — cards, sheets
AppColors.surface2      // #1e2632 — nested surfaces
AppColors.textPrimary   // #e6edf3
AppColors.textSecondary // #8b949e
AppColors.blue          // #4f9eff — actions, active states
AppColors.purple        // #a371f7 — magic, rare items
AppColors.orange        // #f5a623 — rewards, premium
AppColors.red           // #f85149 — boss, danger
AppColors.green         // #3fb950 — success, completion
```

Never hardcode hex color values — always reference `AppColors`.

### Typography — always use `AppTheme` text styles or match these specs
- Headings: Inter, 22–28px, weight 700
- Body: Inter, 14–16px, weight 400–500
- Labels/badges: Inter, 9–10px, weight 600, with letter-spacing

### Spacing (use `SizedBox` or padding multiples of 4)
- Standard gaps: 8, 12, 16, 20, 24px
- Card padding: 16px

### Borders & Radius
- Inputs: `BorderRadius.circular(12)`
- Cards: `BorderRadius.circular(14)` to `16`
- Badges: `BorderRadius.circular(10)`
- Border width: 1–1.5px, color-coded per semantic meaning

### Shadows / Glow Effects
```dart
BoxShadow(color: AppColors.blue.withOpacity(0.25), blurRadius: 16)
BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 20)
```
Use color-matched glows on highlighted or active elements.

### Phone Frame
- Target: 390×844px (iPhone-sized), dark theme only
- No light theme support needed

## Naming Conventions
| Element | Pattern | Example |
|---------|---------|---------|
| Files | snake_case | `quest_card.dart`, `profile_screen.dart` |
| Public classes | PascalCase | `QuestCard`, `ProfileScreen` |
| Private classes | `_` + PascalCase | `_StatBadge`, `_TabHeader` |
| Public constants | UPPER_SNAKE_CASE | `kAllRingItems` |
| Private constants | `_k` + camelCase | `_kFabSize`, `_kRadius` |
| Methods | camelCase | `_handleTap()`, `_buildStatRow()` |

## Animation Patterns
- Use `AnimationController` + `CurvedAnimation` (common: `Curves.easeOutBack`, `Curves.easeInOut`)
- Use `AnimatedBuilder` for widget rebuilds driven by animation
- Use `TweenSequence` for multi-stage animations
- Progress bars: animate from 0 to value on screen entry

## API / Services
- HTTP client: `lib/core/api/api_client.dart` (Dio, base URL `http://localhost:5128/api`)
- JWT token auto-injected via Dio interceptor
- Token stored in `FlutterSecureStorage`
- Feature services live in their feature folder (e.g., `auth/auth_service.dart`)

## What to check before writing any screen
1. Read `lib/core/constants/app_colors.dart` for color tokens
2. Read `lib/core/widgets/main_shell.dart` to understand nav shell
3. Read an existing screen (e.g., `home/home_screen.dart`) to match card/layout patterns
4. Check if a shared widget in `lib/core/widgets/` already covers the need


Below is a solid, production-friendly approach for an AI Flutter app that talks to a Claude agent backend.

1. Recommended architecture

Use this split:

Flutter app

presentation
application
domain
data
core/shared

Backend agent service

API layer
agent orchestration layer
tool layer
memory/context layer
model provider adapter
observability and safety

This gives you:

clean UI code
easy testing
model/provider independence
safer handling of prompts, tools, and secrets
simpler future support for OpenAI, Gemini, local models, or multiple agents
2. Best design pattern for Flutter

For AI apps, the best combination is:

Clean Architecture
Feature-first folder structure
Repository pattern
Use case / service layer
State management with Riverpod or Bloc
Immutable models
Backend-driven agent orchestration

Do not put agent logic directly inside Flutter UI.
Flutter should be a thin intelligent client, not the agent brain.

3. Flutter layer breakdown
A. Presentation layer

Contains:

screens
widgets
controllers/view models/providers
routing
input validation for UI only

Examples:

chat screen
conversation list screen
prompt composer
upload attachment widget
tool activity panel
token usage / status widget

Responsibilities:

render state
capture user input
display streaming responses
show agent steps, errors, loading, retries

Should not contain:

prompt engineering
API formatting
business rules
tool execution logic
B. Application layer

Contains app-specific workflows.

Examples:

SendMessageUseCase
CreateConversationUseCase
SummarizeChatUseCase
UploadFileUseCase
RetryAgentStepUseCase

Responsibilities:

orchestrate domain objects
call repositories
handle app flow rules
transform UI input to domain requests

This is where your app behavior lives.

C. Domain layer

Pure business logic.

Contains:

entities
value objects
repository contracts
use case interfaces
business rules

Example entities:

Conversation
Message
AgentTask
ToolCall
Attachment
TokenUsage

Why this matters:

easiest layer to test
independent from Flutter and backend SDKs
protects architecture from chaos as app grows
D. Data layer

Contains:

repository implementations
remote API clients
local cache
DTOs / mappers
websocket / SSE handling

Responsibilities:

talk to backend
persist local data
map JSON into domain models

This layer knows:

REST
GraphQL
SSE
WebSocket
SQLite / Hive / Isar
auth tokens

This layer should not know UI concerns.

E. Core/shared layer

Contains cross-cutting utilities:

error handling
network info
logging
config
constants
result/either types
interceptors
secure storage helpers
4. Best Flutter folder structure

A feature-first structure works best.

lib/
  app/
    app.dart
    router.dart
    bootstrap.dart

  core/
    config/
    errors/
    networking/
    logging/
    utils/
    widgets/

  features/
    chat/
      presentation/
        pages/
        widgets/
        providers/
        controllers/
      application/
        usecases/
      domain/
        entities/
        repositories/
        services/
      data/
        datasources/
        dtos/
        mappers/
        repositories/

    conversations/
      presentation/
      application/
      domain/
      data/

    files/
      presentation/
      application/
      domain/
      data/

    settings/
      presentation/
      application/
      domain/
      data/

This scales much better than one huge global models/, services/, screens/ setup.

5. State management recommendation

Use Riverpod if you want:

clean dependency injection
testability
reactive state
less boilerplate

Use Bloc if your team already prefers event-state architecture.

For most modern Flutter AI apps, I would choose:

Riverpod + StateNotifier/Notifier + Freezed

Why:

great async state handling
easier DI
good for streaming AI responses
clean test setup
6. Key patterns for AI chat in Flutter
A. Repository pattern

Define contracts in domain:

abstract class ChatRepository {
  Future<Conversation> createConversation();
  Stream<AgentEvent> sendMessage({
    required String conversationId,
    required String text,
    List<Attachment>? attachments,
  });
  Future<List<Message>> getMessages(String conversationId);
}

Implementation in data layer:

ChatRepositoryImpl
uses ChatRemoteDataSource
uses ChatLocalDataSource

This makes backend replacement easy.

B. Use case pattern

Example:

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Stream<AgentEvent> call({
    required String conversationId,
    required String text,
    List<Attachment>? attachments,
  }) {
    return repository.sendMessage(
      conversationId: conversationId,
      text: text,
      attachments: attachments,
    );
  }
}

This keeps UI thin.

C. Mapper pattern

Always separate:

API DTO
domain entity
UI model if needed

Avoid passing raw JSON everywhere.

Example:

MessageDto
MessageMapper
Message

This is critical in AI apps because backend schemas change often.

D. Result pattern

Use a safe result type:

sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}
class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

AI systems fail in many ways:

network
timeout
rate limit
invalid tool response
moderation block
provider overload

A typed result system keeps this manageable.

E. Streaming pattern

AI chat should stream responses.

Use:

SSE if backend is simple
WebSocket if you need richer bi-directional agent updates

Stream event types:

message_started
token_delta
tool_call_started
tool_call_finished
message_completed
error

This is better than waiting for one final long response.

7. What should not live in Flutter

Do not place these in the app:

API secrets
Claude API key
system prompts
tool credentials
orchestration logic
retrieval pipeline
memory ranking logic
moderation rules
tenant-level permissions
vector DB access

These belong in the backend.

8. Recommended backend architecture for a Claude agent

The strongest design is:

Flutter App
   |
API Gateway / BFF
   |
Agent Service
   |-- Prompt Builder
   |-- Claude Adapter
   |-- Tool Orchestrator
   |-- Memory Service
   |-- Retrieval Service
   |-- Safety / Guardrails
   |-- Conversation Store
   |-- Observability
Why BFF is useful

Use a Backend for Frontend between Flutter and the agent system.

It can:

shape mobile-friendly responses
manage auth/session
throttle requests
normalize event streaming
hide internal service complexity
9. Backend service responsibilities
A. API Gateway / BFF

Responsibilities:

authenticate user
validate input
create request IDs
rate limit
route conversation requests
expose streaming endpoints for mobile

Endpoints:

POST /conversations
GET /conversations/:id/messages
POST /conversations/:id/messages
GET /conversations/:id/stream
POST /files/upload
B. Agent Orchestrator

This is the brain.

Responsibilities:

load conversation context
build system prompt
decide tools available
call Claude
process tool calls
loop until final answer
save message history
emit structured events

This service should be stateless where possible, with storage externalized.

C. Model Provider Adapter

Use an adapter interface so Claude is not hard-wired into business logic.

interface LlmProvider {
  generate(input: AgentInput): Promise<AgentResponse>;
  stream(input: AgentInput): AsyncIterable<AgentEvent>;
}

Implementation:

ClaudeProvider
later OpenAIProvider
later GeminiProvider

This is very important for resilience and future pricing flexibility.

D. Tool Execution Layer

Tools should be isolated from the model logic.

Examples:

web search
internal docs search
CRM lookup
calendar
order lookup
calculator
code execution
database query

Pattern:

tool registry
permission check
validated input schema
timeout
audit logging
safe output formatting

Never let the model directly execute arbitrary code or raw DB queries without control.

E. Memory / Context Layer

Split memory into:

1. Short-term memory

Current conversation window.

2. Long-term memory

Important user facts, prior tasks, summaries.

3. Retrieval memory

Knowledge-base chunks from vector search or indexed docs.

Recommended flow:

fetch recent messages
attach rolling summary if conversation is long
add retrieved knowledge if relevant
add user preferences if allowed
build final prompt

Do not send full raw conversation forever.
Use summarization and relevance ranking.

F. Safety / Guardrails layer

Responsibilities:

input validation
prompt injection detection
tool allowlist
PII redaction where required
policy checks
output moderation
hallucination-sensitive handling for critical domains

Especially important if the agent:

accesses company systems
performs transactions
reads private docs
sends emails
generates code
G. Observability layer

You absolutely need:

request tracing
latency per step
tool usage logs
model cost tracking
token tracking
error rates
prompt version tracking
conversation replay for debugging
redaction for sensitive content

Without observability, AI systems become impossible to debug.

10. Best infrastructure stack

A strong practical stack:

Mobile
Flutter
Riverpod
Dio
Freezed
GoRouter
Isar or Hive for local cache
flutter_secure_storage for tokens
Backend
Node.js with NestJS / Fastify
or
Python with FastAPI

For agent-heavy systems, FastAPI is especially nice if your AI team works in Python.

Storage
PostgreSQL for conversations, users, metadata
Redis for caching, queues, rate limiting
S3-compatible storage for files
Vector DB for retrieval:
pgvector
Weaviate
Pinecone
Qdrant
Streaming
SSE first
WebSocket if you need tool-status push, presence, multi-device sync
Queue / background jobs
Redis queue / BullMQ / Celery
Used for:
summarization
embedding generation
file indexing
retry jobs
analytics post-processing
Infra / deployment
Docker
Kubernetes or ECS
CDN for static assets
API gateway
secret manager
centralized logs
metrics dashboard
11. Suggested production infrastructure diagram
[Flutter App]
   |
   | HTTPS / SSE / WebSocket
   v
[API Gateway / BFF]
   |
   +-------------------------------+
   |                               |
   v                               v
[Auth Service]               [Agent Service]
                                   |
                     +-------------+-------------+
                     |             |             |
                     v             v             v
               [Claude Adapter] [Tool Service] [Memory Service]
                     |             |             |
                     v             |             v
               [LLM Provider]      |       [Postgres / Vector DB]
                                   |
                                   v
                         [Internal APIs / Search / CRM]

Supporting services:
- Redis
- S3
- Observability
- Queue workers
- Secret manager
12. Recommended conversation flow
Send message flow
User sends message from Flutter.
Flutter immediately adds optimistic local message.
Request goes to BFF.
BFF authenticates and creates trace ID.
Agent service loads recent conversation + summary + memory.
Prompt builder assembles agent input.
Claude starts streaming.
If tool needed, orchestrator calls tool.
Tool result is normalized and fed back to model.
Final answer streams to Flutter.
Messages and tool events are persisted.
Optional async summarizer updates long-term context.

This is the cleanest pattern for a serious AI product.

13. Data model suggestions
Conversation
id
userId
title
status
createdAt
updatedAt
summary
Message
id
conversationId
role
content
status
tokenUsage
createdAt
ToolCall
id
messageId
toolName
inputJson
outputJson
status
latencyMs
createdAt
Attachment
id
conversationId
fileName
mimeType
storageKey
parsedText
createdAt
AgentRun
id
conversationId
provider
model
promptVersion
startedAt
completedAt
totalTokens
costEstimate
finalStatus

This gives excellent traceability.

14. Prompt design pattern

Keep prompts modular.

Use:

system prompt template
policy block
tool instructions block
memory block
user context block
conversation history block

Do not hardcode one giant prompt string inside code.

Recommended structure:

System Identity
Behavior Rules
Safety Rules
Available Tools
Tool Usage Constraints
User Preferences
Relevant Memory
Conversation Summary
Recent Messages
Current User Message

Version these prompts.
A prompt registry or config file is much better than buried strings.

15. Multi-agent or single-agent?

Start with single orchestrated agent.

Only add multi-agent if you truly need:

planner agent
researcher agent
coder agent
reviewer agent

Most apps become overcomplicated too early.
For first production version:

one Claude agent
tools
memory
retrieval
clear orchestration loop

That is enough for most products.

16. Recommended Flutter networking pattern

Use:

Dio for REST
separate ApiClient
separate streaming client
auth interceptor
retry strategy for transient failures

Example structure:

data/
  datasources/
    chat_remote_data_source.dart
    chat_local_data_source.dart
  clients/
    api_client.dart
    stream_client.dart
  repositories/
    chat_repository_impl.dart

This keeps networking isolated.

17. Example Flutter state flow

For chat screen, state may contain:

class ChatState {
  final List<MessageUiModel> messages;
  final bool isSending;
  final bool isStreaming;
  final String? error;
  final ToolActivityUiModel? activeTool;
  final bool canRetry;
}

Controller responsibilities:

send message
subscribe to stream
append token chunks
handle tool status
recover on disconnect
persist local draft

This is cleaner than mixing everything in widgets.

18. Security rules

For a Claude agent app, these are mandatory:

keep model API keys only on server
signed upload URLs for files
JWT or session auth
row-level ownership for conversations
tool-level authorization
redact secrets from logs
rate limiting per user and per org
audit tool calls
encrypt sensitive storage where required

Never trust the model to enforce security.

19. Performance recommendations
cache conversation list locally
paginate old messages
stream tokens, do not poll
summarize long chats
debounce typing-related events
preload recent conversations
compress file payloads
use background indexing for uploads
separate hot path from heavy retrieval path

AI apps feel slow unless you optimize perceived latency.

20. Good engineering rules for this project
Do
keep agent orchestration in backend
use typed models
use streaming
log every agent run
version prompts
isolate tools
support retries and partial failures
write tests for use cases and repositories
Avoid
putting business logic in widgets
calling Claude directly from mobile
mixing DTOs with domain entities
giant service classes
unstructured tool outputs
no-op error handling
storing unlimited raw chat history in prompt context
21. Recommended tech choice summary

If I were building this today, I would use:

Frontend

Flutter
Riverpod
Freezed
Dio
GoRouter
Isar
flutter_secure_storage

Backend

FastAPI
PostgreSQL
Redis
pgvector
S3
SSE
Celery or RQ for jobs

Agent

Claude provider adapter
tool registry
prompt templates
retrieval service
summarization pipeline
observability dashboard

This is clean, scalable, and realistic.

22. Simple architecture rule

A very useful rule:

Flutter handles experience. Backend handles intelligence.

That one rule prevents most bad AI app architectures.

23. Minimal MVP version

If you want a simpler first version:

Flutter
chat UI
conversation list
streaming response
local cache
auth
Backend
/chat endpoint
Claude adapter
Postgres for chats
Redis cache
one or two safe tools
basic observability

Then later add:

retrieval
file uploads
summaries
memory
advanced tools
multi-agent workflows
24. Final recommendation

For an AI Claude agent app in Flutter, the best overall pattern is:

Clean Architecture in Flutter
feature-first modular structure
Riverpod for state
Repository + Use Case pattern
backend-centered agent orchestration
provider adapter for Claude
tool isolation
memory and retrieval as separate services
Postgres + Redis + vector search
SSE streaming
strong observability and guardrails

This gives you a system that is:

maintainable
testable
scalable
secure
ready for production