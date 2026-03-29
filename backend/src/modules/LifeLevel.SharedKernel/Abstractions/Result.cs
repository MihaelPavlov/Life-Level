namespace LifeLevel.SharedKernel.Abstractions;

public readonly struct Result<T>
{
    public T? Value { get; }
    public string? Error { get; }
    public bool IsSuccess => Error is null;

    private Result(T? value, string? error)
    {
        Value = value;
        Error = error;
    }

    public static Result<T> Ok(T value) => new(value, null);
    public static Result<T> Fail(string error) => new(default, error);
}
