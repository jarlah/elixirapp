defmodule ElixirAppTest do
  use ExUnit.Case
  doctest ElixirApp

  test "ok" do
    assert ElixirApp.ok() == :ok
  end
end
