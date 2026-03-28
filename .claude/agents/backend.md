---
name: backend
description: Use when creating or modifying ASP.NET Core controllers, services, entities, DTOs, migrations, or any C# backend code in the Life-Level API
tools: Read, Edit, Write, Glob, Grep, Bash
---

You are a C# / ASP.NET Core specialist for the Life-Level RPG fitness API. Always read relevant existing files before writing new ones to stay consistent with current patterns.

## Project Location
`backend/src/LifeLevel.Api/`

## Folder Structure
```
LifeLevel.Api/
├── Controllers/              # API endpoints
├── Application/
│   ├── DTOs/                 # Records for request/response (organized by domain)
│   └── Services/             # Business logic (concrete classes, no interfaces)
├── Domain/
│   ├── Entities/             # EF Core entity models
│   └── Enums/                # Domain enumerations
├── Infrastructure/
│   └── Persistence/          # AppDbContext + EF Core config
├── Middleware/               # (empty, available)
├── Migrations/               # EF Core auto-generated migrations
└── Program.cs                # DI registration + middleware pipeline
```

## Namespace Convention
Matches folder path exactly:
- `LifeLevel.Api.Controllers`
- `LifeLevel.Api.Application.DTOs.{Domain}`
- `LifeLevel.Api.Application.Services`
- `LifeLevel.Api.Domain.Entities`
- `LifeLevel.Api.Domain.Enums`
- `LifeLevel.Api.Infrastructure.Persistence`

## Controllers
```csharp
[ApiController]
[Route("api/{resource}")]
public class FooController : ControllerBase
{
    private readonly FooService _fooService;
    public FooController(FooService fooService) => _fooService = fooService;

    [HttpPost]                      // POST api/foo
    public async Task<IActionResult> Create([FromBody] CreateFooRequest req) { ... }

    [HttpGet("{id}")]               // GET api/foo/{id}
    [Authorize]
    public async Task<IActionResult> Get(Guid id) { ... }
}
```

- Always add `[ApiController]` and `[Route("api/{resource}")]`
- Use `[Authorize]` on endpoints that require authentication
- Extract authenticated user ID: `User.FindFirstValue(ClaimTypes.NameIdentifier)`
- Return types: `Ok(data)` 200, `Conflict(msg)` 409, `Unauthorized(msg)` 401, `NotFound(msg)` 404, `NoContent()` 204
- Catch exceptions from services and translate to HTTP responses — do NOT let exceptions bubble to the framework

## Services
```csharp
public class FooService
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt; // inject only what's needed

    public FooService(AppDbContext db) => _db = db;

    public async Task<FooResponse> DoSomethingAsync(CreateFooRequest req)
    {
        // validation → throw InvalidOperationException on business rule violations
        // data access via _db
        // return DTO, never return entities directly
    }
}
```

- No interfaces — register concrete classes directly in DI
- All services use `Scoped` lifetime: `builder.Services.AddScoped<FooService>()`
- Business logic validation throws `InvalidOperationException` — controllers catch it
- Always use `async/await` for all DB operations
- Never return domain entities from services — map to DTOs first

## Entities
```csharp
public class Foo
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public ICollection<Bar> Bars { get; set; } = [];
}
```

- GUID primary keys (`Guid Id = Guid.NewGuid()`)
- Always include `CreatedAt` and `UpdatedAt` with `DateTime.UtcNow`
- Use `null!` for required navigation properties
- Use `= []` for collection initializers
- Configure all relationships in `AppDbContext.OnModelCreating` using Fluent API

## EF Core Configuration (AppDbContext)
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Foo>(e =>
    {
        e.HasKey(f => f.Id);
        e.HasIndex(f => f.Name).IsUnique();
        e.HasOne(f => f.User).WithMany(u => u.Foos)
            .HasForeignKey(f => f.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        e.Property(f => f.Status).HasConversion<string>(); // store enums as strings
    });
}
```

- All constraints defined in `OnModelCreating` — no DataAnnotations on entities
- Store enums as strings: `.HasConversion<string>()`
- Cascade deletes for child entities owned by a user
- Unique indexes declared explicitly

## DTOs — use C# records
```csharp
// Requests
public record CreateFooRequest(string Name, int Value);
public record UpdateFooRequest(string? Name, int? Value);

// Responses
public record FooResponse(Guid Id, string Name, int Value, DateTime CreatedAt);
```

- All DTOs are `record` types (immutable)
- Naming: `{Action}{Entity}Request` and `{Entity}Response`
- DTOs go in `Application/DTOs/{Domain}/`
- No DataAnnotation validators — validate in the service layer
- Use `IReadOnlyList<T>` for collection properties

## Enums
```csharp
// Domain/Enums/FooType.cs
namespace LifeLevel.Api.Domain.Enums;
public enum FooType { TypeA, TypeB, TypeC }
```

- One enum per file in `Domain/Enums/`
- Stored as strings in DB (configured in `OnModelCreating`)
- JSON enum converter registered in `Program.cs` makes them serialize as strings in API responses

## Migrations
- Generate: `dotnet ef migrations add {MigrationName}` from project directory
- Naming convention: EF Core auto-timestamps → `{yyyyMMddHHmmss}_{PascalCaseName}`
- Never hand-edit migration files — re-generate if changes needed
- Always check `AppDbContextModelSnapshot.cs` is updated after migration

## Auth
- JWT token validated on every `[Authorize]` request
- Config in `appsettings.json` under `"Jwt"` key: Key, Issuer, Audience, ExpiresInHours
- `JwtService.Generate(User user)` creates tokens — reuse this service, don't create new token logic
- User ID from token: `User.FindFirstValue(ClaimTypes.NameIdentifier)` → parse as `Guid`

## Adding a New Feature Checklist
1. Add entity to `Domain/Entities/` with GUID PK + timestamps
2. Add any enums to `Domain/Enums/`
3. Register entity in `AppDbContext` + configure in `OnModelCreating`
4. Run `dotnet ef migrations add {Name}` to generate migration
5. Add DTOs to `Application/DTOs/{Domain}/`
6. Create service in `Application/Services/` + register in `Program.cs`
7. Create controller in `Controllers/` with proper routes and auth

## Key Existing Files to Read First
- `Infrastructure/Persistence/AppDbContext.cs` — before adding any entity
- `Program.cs` — before registering any service
- `Domain/Entities/User.cs` and `Character.cs` — to understand existing relationships
- `Controllers/AuthController.cs` — to match controller style
- `Application/Services/AuthService.cs` — to match service style


# ASP.NET Core Clean Architecture README

A practical, maintainable, and scalable **ASP.NET Core** project template using **Clean Architecture**, **Domain-Driven Design principles**, and a focused set of **design patterns** that solve real problems without overengineering.

---

## Goals

This architecture is designed to help you:

- Keep business logic independent from frameworks and infrastructure
- Make the codebase easier to test and evolve
- Reduce coupling between layers
- Support long-term maintainability in medium and large projects
- Apply design patterns only where they add clarity and value

---

# Architecture Overview

This solution follows the **Clean Architecture** approach, where dependencies point inward toward the domain and application core.

## Core rule

**Outer layers depend on inner layers. Inner layers never depend on outer layers.**

### Layers

#### 1. Domain
Contains the core business model and rules.

- Entities
- Value Objects
- Domain Events
- Enums
- Domain Exceptions
- Repository contracts if you choose to keep abstractions close to the domain

This layer should have **no dependency** on ASP.NET Core, EF Core, or other frameworks.

#### 2. Application
Contains use cases and business workflows.

- Commands / Queries
- DTOs
- Interfaces
- Validators
- Mapping
- Behaviors / Pipelines
- Application services
- Authorization rules

This layer orchestrates domain logic but should not know implementation details about persistence, messaging, file systems, etc.

#### 3. Infrastructure
Contains implementations of external concerns.

- Entity Framework Core
- Repositories
- Email sender
- File storage
- Third-party APIs
- Background job providers
- Authentication integrations
- Caching implementations

Infrastructure depends on Application and Domain.

#### 4. Presentation
The entry point of the application.

- ASP.NET Core Web API
- MVC
- Minimal APIs
- gRPC
- SignalR

This layer handles HTTP, auth, serialization, and request/response formatting.

---

# Recommended Solution Structure

```text
src/
  MyApp.Domain/
    Entities/
    ValueObjects/
    Events/
    Exceptions/
    Enums/
    Interfaces/

  MyApp.Application/
    Abstractions/
    Common/
      Behaviors/
      Exceptions/
      Interfaces/
      Mappings/
      Models/
      Results/
    Features/
      Orders/
        Commands/
          CreateOrder/
            CreateOrderCommand.cs
            CreateOrderCommandHandler.cs
            CreateOrderValidator.cs
        Queries/
          GetOrderById/
            GetOrderByIdQuery.cs
            GetOrderByIdQueryHandler.cs
            OrderDto.cs

  MyApp.Infrastructure/
    Persistence/
      Configurations/
      Interceptors/
      Migrations/
      Repositories/
      ApplicationDbContext.cs
    Identity/
    Services/
    Caching/
    Messaging/
    DependencyInjection.cs

  MyApp.WebApi/
    Controllers/
    Endpoints/
    Middleware/
    Filters/
    DependencyInjection.cs
    Program.cs

tests/
  MyApp.Domain.Tests/
  MyApp.Application.Tests/
  MyApp.Infrastructure.Tests/
  MyApp.WebApi.Tests/
Dependency Flow
Presentation -> Application -> Domain
Infrastructure -> Application -> Domain
Domain -> nothing

Domain is the center.
Application depends on Domain.
Infrastructure implements contracts defined by Application or Domain.
Presentation uses Application to execute use cases.

Best Practices by Layer
Domain Layer

The Domain layer should contain only business concepts.

Include
Entities with behavior
Value Objects
Business rules
Domain services when logic does not fit a single entity
Domain events
Avoid
EF Core attributes when possible
Controllers
HTTP concepts
Database logic
Logging frameworks
Email sending
External API calls
Example entity
public class Order
{
    private readonly List<OrderItem> _items = new();

    public Guid Id { get; private set; }
    public Guid CustomerId { get; private set; }
    public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();
    public decimal TotalAmount => _items.Sum(x => x.TotalPrice);
    public OrderStatus Status { get; private set; }

    private Order() { }

    public Order(Guid customerId)
    {
        Id = Guid.NewGuid();
        CustomerId = customerId;
        Status = OrderStatus.Pending;
    }

    public void AddItem(Guid productId, string productName, decimal unitPrice, int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity must be greater than zero.");

        _items.Add(new OrderItem(productId, productName, unitPrice, quantity));
    }

    public void MarkAsPaid()
    {
        if (!_items.Any())
            throw new DomainException("Cannot pay for an empty order.");

        Status = OrderStatus.Paid;
    }
}
Value Object example
public sealed class Email : IEquatable<Email>
{
    public string Value { get; }

    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Email cannot be empty.");

        Value = value.Trim().ToLowerInvariant();
    }

    public bool Equals(Email? other) => other is not null && Value == other.Value;
    public override bool Equals(object? obj) => obj is Email other && Equals(other);
    public override int GetHashCode() => Value.GetHashCode();
    public override string ToString() => Value;
}
Application Layer

The Application layer contains use cases.

A use case should answer:

What does the system do?
What input does it need?
What output does it produce?
What rules should run before and after execution?
Recommended style

Use CQRS with:

Commands for writes
Queries for reads

This does not mean separate databases are required. Start with logical separation only.

Example command
public sealed record CreateOrderCommand(
    Guid CustomerId,
    List<CreateOrderItemRequest> Items) : IRequest<Guid>;
Example handler
public sealed class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, Guid>
{
    private readonly IOrderRepository _orderRepository;
    private readonly IUnitOfWork _unitOfWork;

    public CreateOrderCommandHandler(
        IOrderRepository orderRepository,
        IUnitOfWork unitOfWork)
    {
        _orderRepository = orderRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Guid> Handle(CreateOrderCommand request, CancellationToken cancellationToken)
    {
        var order = new Order(request.CustomerId);

        foreach (var item in request.Items)
        {
            order.AddItem(item.ProductId, item.ProductName, item.UnitPrice, item.Quantity);
        }

        await _orderRepository.AddAsync(order, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return order.Id;
    }
}
Validation

Use FluentValidation or similar validation in the Application layer.

public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator()
    {
        RuleFor(x => x.CustomerId).NotEmpty();
        RuleFor(x => x.Items).NotEmpty();

        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ProductId).NotEmpty();
            item.RuleFor(i => i.ProductName).NotEmpty();
            item.RuleFor(i => i.Quantity).GreaterThan(0);
            item.RuleFor(i => i.UnitPrice).GreaterThan(0);
        });
    }
}
Infrastructure Layer

Infrastructure provides implementations for external systems.

Typical contents
ApplicationDbContext
EF Core configurations
Repository implementations
Cache providers
SMTP or email services
Payment gateway clients
Message bus publishers
Example repository implementation
public sealed class OrderRepository : IOrderRepository
{
    private readonly ApplicationDbContext _dbContext;

    public OrderRepository(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(Order order, CancellationToken cancellationToken)
    {
        await _dbContext.Orders.AddAsync(order, cancellationToken);
    }

    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return await _dbContext.Orders
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }
}
Presentation Layer

This is your ASP.NET Core app.

Keep controllers and endpoints very thin.

Controller responsibilities
Receive request
Validate transport-level concerns
Call application use case
Return HTTP response
Avoid
Business logic in controllers
EF Core directly inside controllers
Complex mapping logic
Huge service classes behind controllers
Example controller
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly ISender _sender;

    public OrdersController(ISender sender)
    {
        _sender = sender;
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateOrderCommand command, CancellationToken cancellationToken)
    {
        var orderId = await _sender.Send(command, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = orderId }, orderId);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _sender.Send(new GetOrderByIdQuery(id), cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }
}
Design Patterns to Use

Use patterns when they solve a real problem, not because they are popular.

1. Repository Pattern
Why use it
Abstract data access for aggregates
Keep application logic independent from EF Core details
Improve testability
Good usage
One repository per aggregate root
Keep methods business-focused
Avoid generic repository abuse
Good example
public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task AddAsync(Order order, CancellationToken cancellationToken);
}
Avoid
public interface IRepository<T>
{
    IQueryable<T> Query();
    void Update(T entity);
    void Delete(T entity);
    void Add(T entity);
}

A generic repository often duplicates ORM behavior and leaks persistence details.

2. Unit of Work Pattern
Why use it
Coordinate multiple repository operations in one transaction
Explicit save boundary
Example
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

With EF Core, your DbContext often already acts as a Unit of Work. Do not create unnecessary wrappers unless they add clarity.

3. CQRS
Why use it
Separate read and write concerns
Easier maintenance for complex applications
Clear use-case structure
Use it when
Business workflows are non-trivial
Read models differ from write models
You want a clean feature-based folder structure
Do not overcomplicate it

You do not need:

Separate databases on day one
Event sourcing
Microservices
Distributed messaging

Start simple.

4. Mediator Pattern

Typically implemented with MediatR.

Why use it
Decouple controllers from use case implementations
Centralize behaviors like validation, logging, transactions
Example
services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(CreateOrderCommand).Assembly));
Good fit
Commands and queries
Notifications
Pipeline behaviors
5. Specification Pattern
Why use it
Encapsulate reusable query logic
Avoid duplicated filtering rules
Keep repositories cleaner
Example
public class PaidOrdersSpecification
{
    public Expression<Func<Order, bool>> Criteria => order => order.Status == OrderStatus.Paid;
}

Useful for complex domain filtering, but do not force it everywhere.

6. Factory Pattern
Why use it
Enforce valid object creation
Simplify construction of complex aggregates
Protect invariants
Example
public static class OrderFactory
{
    public static Order Create(Guid customerId, IEnumerable<CreateOrderItemRequest> items)
    {
        var order = new Order(customerId);

        foreach (var item in items)
        {
            order.AddItem(item.ProductId, item.ProductName, item.UnitPrice, item.Quantity);
        }

        return order;
    }
}

Use factories when constructors become too complex or when creation rules matter.

7. Strategy Pattern
Why use it
Swap algorithms or business rules cleanly
Avoid large switch or if/else blocks
Example use cases
Pricing calculation
Discount logic
Payment method handling
Shipping cost calculation
Example
public interface IDiscountStrategy
{
    decimal Apply(decimal totalAmount);
}

public sealed class PremiumCustomerDiscountStrategy : IDiscountStrategy
{
    public decimal Apply(decimal totalAmount) => totalAmount * 0.9m;
}

public sealed class NoDiscountStrategy : IDiscountStrategy
{
    public decimal Apply(decimal totalAmount) => totalAmount;
}
8. Decorator Pattern
Why use it
Add behavior without changing the original service
Great for logging, caching, retrying, metrics
Example use cases
Cache query results
Log service calls
Add resilience policies
9. Domain Events
Why use it
React to important domain changes
Decouple side effects from aggregates
Keep domain logic focused
Example
public record OrderPaidDomainEvent(Guid OrderId) : IDomainEvent;

Example side effects:

Send confirmation email
Publish integration event
Update reporting model

Use domain events for meaningful business events, not for every property change.

10. Result Pattern
Why use it
Return explicit success/failure without throwing exceptions for expected outcomes
Improve readability
Example
public class Result
{
    public bool IsSuccess { get; }
    public string? Error { get; }

    protected Result(bool isSuccess, string? error)
    {
        IsSuccess = isSuccess;
        Error = error;
    }

    public static Result Success() => new(true, null);
    public static Result Failure(string error) => new(false, error);
}

Use exceptions for exceptional situations.
Use result objects for expected validation or business failures.

Patterns to Avoid or Use Carefully
Generic Repository

Usually unnecessary with EF Core.

Service Locator

Hides dependencies and makes code hard to test.

God Service

A huge service class that handles everything. Split by feature/use case.

Anemic Domain Model

Avoid entities that only have properties and no behavior if your domain is complex.

Overusing Inheritance

Prefer composition unless inheritance models a real “is-a” relationship.

Premature Microservices

Start modular inside a monolith unless scaling or org boundaries require separation.

Recommended Technology Stack

A solid default stack for ASP.NET Core clean architecture:

ASP.NET Core Web API
Entity Framework Core
MediatR
FluentValidation
AutoMapper or manual mapping
Serilog
xUnit
FluentAssertions
Testcontainers for integration tests
Swagger / OpenAPI
ProblemDetails for error responses

Optional:

Redis for caching
Hangfire or Quartz.NET for jobs
MassTransit for messaging
Polly for resilience
Dependency Injection Registration

A clean pattern is to have one DI extension per project.

Application
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly));
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        return services;
    }
}
Infrastructure
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<ApplicationDbContext>());

        return services;
    }
}
Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseExceptionHandler();

app.MapControllers();

app.Run();
Cross-Cutting Concerns

These should be implemented in a centralized, reusable way.

Validation

Use pipeline behaviors or filters.

Logging

Use structured logging with Serilog.

Exception handling

Use global exception middleware or UseExceptionHandler.

Transactions

Handle per-command where appropriate, often through pipeline behaviors or EF Core transaction boundaries.

Caching

Apply to queries, not commands.

Authorization

Keep authorization rules in the application boundary when possible, not scattered across business code.

Pipeline Behaviors Example

Useful with MediatR for cross-cutting concerns.

Validation behavior
public sealed class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (_validators.Any())
        {
            var context = new ValidationContext<TRequest>(request);
            var results = await Task.WhenAll(_validators.Select(v => v.ValidateAsync(context, cancellationToken)));
            var failures = results.SelectMany(x => x.Errors).Where(x => x is not null).ToList();

            if (failures.Count != 0)
                throw new ValidationException(failures);
        }

        return await next();
    }
}
Error Handling Strategy

Use a consistent API error contract.

Recommendation
Validation errors -> 400
Not found -> 404
Unauthorized -> 401
Forbidden -> 403
Business rule violation -> 409 or 422
Unhandled exceptions -> 500

Return ProblemDetails or a consistent custom response.

Example middleware idea
Catch exception
Map to status code
Return structured JSON
Testing Strategy
1. Domain Tests

Fast unit tests for business rules.

Test:

entity methods
value objects
domain services
invariants
2. Application Tests

Test use-case handlers and validators.

Mock:

repositories
external services
3. Infrastructure Tests

Test:

EF Core mappings
repository queries
database behavior

Prefer real database integration tests over EF in-memory provider for critical flows.

4. API/Integration Tests

Test the real HTTP pipeline end-to-end.

Example test categories
creating order returns 201
invalid request returns 400
missing resource returns 404
auth-protected endpoint returns 401/403 correctly
Feature Folder Approach

Prefer feature-based organization in the Application layer.

Good
Features/
  Orders/
    Commands/
      CreateOrder/
      CancelOrder/
    Queries/
      GetOrderById/
      GetOrders/
Less ideal
Commands/
Queries/
Validators/
Handlers/
Dtos/

Feature folders scale better and keep related code together.

Entity Framework Core Recommendations
Do
Use Fluent API configurations
Keep DbContext in Infrastructure
Use migrations in Infrastructure
Map owned/value objects properly
Keep aggregate boundaries explicit
Avoid
Business logic in EF configurations
Direct DbContext usage from controllers
Lazy loading in large systems without careful control
Massive repositories with dozens of unrelated query methods
Naming Conventions
Commands
CreateOrderCommand
CancelOrderCommand
Queries
GetOrderByIdQuery
GetCustomerOrdersQuery
Handlers
CreateOrderCommandHandler
GetOrderByIdQueryHandler
DTOs
OrderDto
OrderItemDto
Interfaces
IOrderRepository
IEmailSender

Keep naming boring and predictable. That is a good thing.

Example Request Flow
Create Order flow
Client sends POST /api/orders
Controller receives request
Controller sends CreateOrderCommand via MediatR
Validation behavior validates request
Command handler creates domain entity
Repository stores entity
Unit of Work saves changes
Controller returns 201 Created

This keeps each layer focused and simple.

Practical Rules for a Clean Codebase
Keep controllers thin
Keep handlers focused on one use case
Keep entities rich with behavior
Prefer explicit interfaces for real boundaries
Use dependency injection properly
Avoid static helpers for business logic
Keep infrastructure replaceable
Do not leak EF Core types into Application
Do not leak HTTP concerns into Domain
Write tests close to business rules
Favor composition over inheritance
Start simple, then add complexity only when needed
Recommended Starter Checklist
Project setup
 Create Domain, Application, Infrastructure, Presentation projects
 Add reference flow correctly
 Configure DI extension methods per layer
 Add MediatR
 Add FluentValidation
 Add EF Core
 Configure global exception handling
 Configure OpenAPI
 Add structured logging
Quality
 Add unit tests
 Add integration tests
 Enforce code style
 Add health checks
 Add configuration validation
 Add CI pipeline
Architecture discipline
 No business logic in controllers
 No infrastructure dependencies in Domain
 No direct database access from Presentation
 Commands and queries separated
 Cross-cutting concerns centralized