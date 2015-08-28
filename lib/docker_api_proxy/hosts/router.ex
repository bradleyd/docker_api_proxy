defmodule DockerApiProxy.Hosts.Router do
  require Logger
  import Plug.Conn
  use Plug.Router

  plug Plug.Parsers, parsers: [DockerApiProxy.Plugs.Parsers.JSON]
  plug :match
  plug :dispatch
    
  defmodule Host do
    defstruct [:token, :heartbeat, :timestamp]
  end

  def init(options) do
    options
  end

  get "/" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    enc = JSON.encode!(hosts)
    send_resp(conn, 200, enc)
  end

  ## TODO need to pattern match on insert as well
  post "/" do
    host = conn.params[:data]["name"]
    heartbeat = conn.params[:data]["heartbeat_interval"]

    Logger.info("Got registration from #{host}")
    # search ets for host, if not exist create new key
    token = UUID.uuid4()
    resp =
    case DockerApiProxy.Registry.lookup(:registry, host) do
      {:ok, {^host, struct}} -> 
          timestamp = :calendar.local_time
          DockerApiProxy.Registry.insert(:registry, {host, %Host{token: token, heartbeat: heartbeat, timestamp: timestamp}})
          %{token: token, heartbeat: heartbeat, last_registered: timestamp}
      :error -> 
          timestamp = :calendar.local_time
          DockerApiProxy.Registry.insert(:registry, {host, %Host{token: token, heartbeat: heartbeat, timestamp: timestamp}})
          %{token: token, heartbeat: heartbeat, last_registered: timestamp}
    end
    response = JSON.encode!(resp)
    send_resp(conn, 201, response)
  end

  get "/next_available" do
    Logger.info("Find next host with space")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    results  = find_host_with_least_containers(hosts)
    response = JSON.encode!(results)
    send_resp(conn, 201, response)
  end

  get "/sorted_least_count" do
    Logger.info("Find all hosts with space sorted")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    results  = hosts_sorted_by_least_container_count(hosts)
    response = JSON.encode!(results)
    send_resp(conn, 201, response)
  end

  match _ do
    send_resp(conn, 404, "No route in /hosts")
  end


  defp hosts_sorted_by_least_container_count(hosts) when is_list(hosts) do
    Enum.map(hosts, fn(h) ->
      {:ok, body, code} = DockerApi.Container.all(h, %{all: 0})
      %{host: h, count: Enum.count(body)}
    end)
    |> Enum.sort_by(fn(x) -> x.count end)
    |> Enum.map(fn (x) -> x.host end)
  end

  defp find_host_with_least_containers(hosts) when is_list(hosts) do
    Enum.map(hosts, fn(h) ->
      {:ok, body, code} = DockerApi.Container.all(h, %{all: 0})
      %{host: h, count: Enum.count(body)}
    end) |>
    Enum.min_by(fn(x) -> x.count end)
  end
end
