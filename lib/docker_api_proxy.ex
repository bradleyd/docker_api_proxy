defmodule DockerApiProxy do
  import Plug.Conn
  use Plug.Router
  plug :match
  plug :dispatch
    
  def init(options) do
    options
  end

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  get "/containers" do
    hosts = ["192.168.4.4:14443", "127.0.0.1:14443"]
    res = Enum.flat_map(hosts, fn(x) -> 
    Application.put_env(:erldocker, :docker_http, x)
    {:ok, result } = :docker_container.containers
    result
    end)

    {:ok, enc } = JSON.encode(res)
    send_resp(conn, 200, enc)
  end

  get "/container/:id" do
    hosts = ["192.168.4.4:14443", "127.0.0.1:14443"]
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
