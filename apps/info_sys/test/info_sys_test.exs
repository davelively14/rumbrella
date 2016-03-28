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
    # Will automatically timeout when called.
    def fetch("timeout", _ref, owner, _limit) do
      # Will allow tests to monitor the process by returning the backend pid
      send(owner, {:backend, self()})

      # Simulates that our request takes too long
      :timer.sleep(:infinity)
    end
    def fetch("boom", _ref, _owner, _limit) do
      raise "boom!"
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

  test "compute/2 with timeout returns no results and kills workers" do
    results = InfoSys.compute("timeout", backends: [TestBackend], timeout: 10)
    assert results == []
    assert_receive {:backend, backend_pid}
    ref = Process.monitor(backend_pid)
    assert_receive {:DOWN, ^ref, :process, _pid, _reason}

    # Confirm that inbox was cleaned out with these two statements.
    refute_received {:DOWN, _, _, _, _}
    refute_received :timedout
  end

  # This tag prevents the crashing run time error log message from appearing.
  @tag :capture_log
  test "compute/2 discards backend errors" do
    assert InfoSys.compute("boom", backends: [TestBackend]) == []
    refute_received {:DOWN, _, _, _, _}
    refute_received :timedout
  end
end
