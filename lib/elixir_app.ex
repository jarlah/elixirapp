defmodule ElixirApp do
  @moduledoc """
  Documentation for ElixirApp.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ElixirApp.hello()
      :world

  """
  def hello do
    with {:ok, [file | _tail]} <- File.ls,
         {:ok, content} <- File.read(file),
      do: IO.puts content
  end
end
