# Custom type defined according to the Ecto.Type behavtior.  Expects
# us to define 4 functions: type, cast, dump, and load
defmodule Rumbl.Permalink do
  # Mispelled on purpose?
  @behaviour Ecto.Type

  # Identifies the underlying data type as :id
  def type, do: :id

  # Cast is called when external data is passed into Ecto. It's invoked when
  # interpolating values in queries or also by the cast function in changesets.
  def cast(binary) when is_binary(binary) do
    # When receiving a binary, i.e. a string, Integer.parse will pull the lead
    # integer.
    case Integer.parse(binary) do
      {int, _} when int > 0 -> {:ok, int}
      _ -> :error
    end
  end

  def cast(integer) when is_integer(integer) do
    {:ok, integer}
  end

  def cast(_) do
    :error
  end

  # We can expect to work with only integers, because cast will be called first
  # and will only let us get to this point if we have an integer.
  def dump(integer) when is_integer(integer) do
    {:ok, integer}
  end

  def load(integer) when is_integer(integer) do
    {:ok, integer}
  end
end
