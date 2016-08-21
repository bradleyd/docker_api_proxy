defmodule DockerApiProxy.HostWatcher do
  use GenServer
  
  @heartbeat_interval 6000

  @moduledoc """
  Iterates through all the docker hosts and removes ones that have not checked in for over a minute
  """

  def start_link(table) do
    GenServer.start_link(__MODULE__, table, name: __MODULE__) 
  end

  def init(table) do
    :erlang.send(self(), :search)
    {:ok, table} 
  end
  
  def handle_info(:search, state) do
   all = :ets.select(state, [{{:"$1",:"$2"},[],[:"$$"]}])
   IO.inspect all
   Enum.each(all, fn(host) -> 
     [ip, meta] = host
     {_, {_, min, _sec}} = :calendar.time_difference(meta.timestamp, :erlang.localtime)
     GenServer.cast(__MODULE__, {:missing_heartbeat, min, ip})
   end)
   :erlang.send_after(@heartbeat_interval, self(), :search) 
   #:erlang.garbage_collect(self())
   {:noreply, state}
  end

  def handle_info(info, state) do
    IO.puts("Received info message #{inspect(info)}")
    {:noreply, state}
  end

  def handle_cast({:missing_heartbeat, min, ip}, state) do
    missing_heartbeat?(state, min, ip) 
    {:noreply, state} 
  end
 
  def handle_cast(_, state) do
    {:noreply, state} 
  end
 
  # TODO calculate the missing time according to heartbeat interval
  # (heartbeat_interval + padding) > sec ?
  defp missing_heartbeat?(table, min, ip) when min >= 1 do
    IO.puts("Deleting host #{ip}..missing in action for over a minute")
    result = :ets.delete(table, ip)
    {:ok, result}
  end
  defp missing_heartbeat?(table, min, ip) when min < 1 do
    {:noreply, table}
  end

end
