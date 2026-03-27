using LifeLevel.Api.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Character> Characters => Set<Character>();
    public DbSet<Activity> Activities => Set<Activity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(u => u.Id);
            e.HasIndex(u => u.Email).IsUnique();
            e.HasIndex(u => u.Username).IsUnique();
        });

        modelBuilder.Entity<Character>(e =>
        {
            e.HasKey(c => c.Id);
            e.HasOne(c => c.User)
             .WithOne(u => u.Character)
             .HasForeignKey<Character>(c => c.UserId);
        });

        modelBuilder.Entity<Activity>(e =>
        {
            e.HasKey(a => a.Id);
            e.HasOne(a => a.Character)
             .WithMany(c => c.Activities)
             .HasForeignKey(a => a.CharacterId);
        });
    }
}
