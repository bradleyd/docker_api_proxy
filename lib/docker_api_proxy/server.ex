defmodule DockerApiProxy.Server do
  import Plug.Conn
  use Plug.Router

  plug Plug.Parsers, parsers: [DockerApiProxy.Plugs.Parsers.JSON]
  plug :match
  plug :dispatch
    
  def init(options) do
    options
  end

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  get "/hosts" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    enc = JSON.encode!(hosts)
    send_resp(conn, 200, enc)
  end

  ## TODO need to pattern match on insert as well
  post "/hosts" do
    host = conn.params[:data]["name"]
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

  get "/containers" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(host) -> 
      {:ok, body, code} = DockerApi.Container.all(host)
      body
    end)

    {:ok, enc } = JSON.encode(res)
    send_resp(conn, 200, enc)
  end

  """ 
  Example params
      %{ "HostName": "", "Image": "redis", "ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
         "PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], "6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}
  """
  post "/containers" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    IO.inspect conn.params[:data]
    payload = conn.params[:data]
    {:ok, body, code } = DockerApi.Container.create(List.first(hosts), payload)
    send_resp(conn, 200, JSON.encode!(body))
  end

  ## TODO need algorithm to choose the correct docker host least first, round robin
  post "/container/:id/start" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    payload = conn.params[:data]
    {:ok, body, code} = DockerApi.Container.start(List.first(hosts), id, payload)
    send_resp(conn, code, JSON.encode!(body))
  end

  post "/container/:id/stop" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    {:ok, body, code } = DockerApi.Container.stop(List.first(hosts), id)
    send_resp(conn, code, JSON.encode!(body))
  end

  get "/container/:id" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(x) -> 
      case DockerApi.Container.get(x, id) do
        {:ok, body, code } -> body
        _ -> []
      end
    end)
    send_resp(conn, 200, JSON.encode!(res))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
