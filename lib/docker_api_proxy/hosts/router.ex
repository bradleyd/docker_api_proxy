defmodule DockerApiProxy.Hosts.Router do
  require Logger
  import Plug.Conn
  use Plug.Router

  plug Plug.Parsers, parsers: [DockerApiProxy.Plugs.Parsers.JSON]
  plug :match
  plug :dispatch
    
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
    Logger.info("Got registration from #{host}")
    # search ets for host, if not exist create new key
    token = UUID.uuid4()
    resp =
    case DockerApiProxy.Registry.lookup(:registry, host) do
      {:ok, {^host, token}} -> 
          token
      :error -> 
          DockerApiProxy.Registry.insert(:registry, {host, token})
          token
    end
    response = JSON.encode!(%{token: resp})
    send_resp(conn, 201, response)
  end

  get "/least_count" do
    Logger.info("Find host with space")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    results  = round_robin_hosts(hosts)
    response = JSON.encode!(%{host: results.host})
    send_resp(conn, 201, response)
  end

  match _ do
    send_resp(conn, 404, "No route in /hosts")
  end


  defp round_robin_hosts(hosts) when is_list(hosts) do
    Enum.map(hosts, fn(h) ->
      {:ok, body, code} = DockerApi.Container.all(h)
      %{host: h, count: Enum.count(body)}
    end) |>
    Enum.min_by(fn(x) -> x.count end)
  end

end
