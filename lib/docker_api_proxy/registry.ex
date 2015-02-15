defmodule DockerApiProxy.Registry do
  use GenServer
  
  def start_link(table, opts \\ []) do
   GenServer.start_link(__MODULE__, {table}, opts) 
  end
  
  def init({table}) do
    ets  = :ets.new(table, [:bag, :public, :named_table, read_concurrency: true])
    {:ok, %{names: ets}}
  end

  def insert(table, payload) do
    case :ets.insert(table, payload) do
      true -> {:ok, "inserted"}
      _ -> {:error}
    end 
  end
  
  def lookup(table, key) do
    case :ets.lookup(table, key) do
      [{^key, token}] -> {:ok, {key, token}}
      [] -> :error
    end 
  end
  
end

