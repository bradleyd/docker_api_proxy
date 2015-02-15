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
    res = Enum.flat_map(hosts, fn(x) -> 
    Application.put_env(:erldocker, :docker_http, x)
    {:ok, result } = :docker_container.containers
    result
    end)

    {:ok, enc } = JSON.encode(res)
    send_resp(conn, 200, enc)
  end

  get "/container/:id" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(x) -> 
      Application.put_env(:erldocker, :docker_http, x)
      case :docker_container.container(id) do
        {:ok, result } -> result
        _ -> []
      end
    end)

    {:ok, enc } = JSON.encode(res)
    send_resp(conn, 200, enc)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
