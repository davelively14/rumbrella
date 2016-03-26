defmodule InfoSys.Supervisor do
  use Supervisor

  def start_link() do
    # Similar to GenServer.start_link. Passes this module's name as the :name
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    children = [
      worker(InfoSys, [], restart: :temporary)
    ]

    # The :simple_one_for_one strategy doesn't start any children. It waits for
    # us to explicitly ask it to start a child proces and then handles any
    # crashes as a :one_for_one supervisor would.
    supervise children, strategy: :simple_one_for_one
  end
end
