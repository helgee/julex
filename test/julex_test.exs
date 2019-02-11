defmodule JulexTest do
  use ExUnit.Case
  doctest Julex

  setup_all do
    pid = start_supervised!(Julex.Worker)
    [pid: pid]
  end

  test "basic echo call", context do
    result = Julex.Worker.call(context[:pid], :echo, [:echo])
    assert result == {:ok, [:echo]}
  end

  test "nprocs", context do
    {:ok, nprocs} = Julex.Worker.call(context[:pid], :nprocs, [])
    assert nprocs == Julex.Worker.nprocs()
  end

  test "error", context do
    {result, _} = Julex.Worker.call(context[:pid], :unknown, [:something])
    assert result == :error
  end
end
