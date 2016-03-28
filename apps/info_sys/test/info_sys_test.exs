defmodule InfoSysTest do
  use ExUnit.Case
  alias InfoSys.Result

  # Stub module will act like our Wolfram backend, returning a response in the
  # format that we expect. NOTE: A stub replaces real world libraries with
  # simpler, predictable behavior. 
  defmodule TestBackend do
    def start_link(query, ref, owner, limit) do
      Task.start_link(__MODULE__, :fetch, [query, ref, owner, limit])
    end
    def fetch("result", ref, owner, _limit) do
      send(owner, {:results, ref, [%Result{backend: "test", text: "result"}]})
    end
    def fetch("none", ref, owner, _limit) do
      send(owner, {:results, ref, []})
    end
  end

  # Tests compute/2 functionality given the fake TestBackend module.
  test "compute/2 with backend results" do
    assert [%Result{backend: "test", text: "result"}] =
           InfoSys.compute("result", backends: [TestBackend])
  end

  test "compute/2 with no backend results" do
    assert [] = InfoSys.compute("none", backends: [TestBackend])
  end
end
