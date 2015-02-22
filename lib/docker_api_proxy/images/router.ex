defmodule DockerApiProxy.Images.Router do
  require Logger
  import Plug.Conn
  use Plug.Router

  plug Plug.Parsers, parsers: [DockerApiProxy.Plugs.Parsers.JSON]
  plug :match
  plug :dispatch
    
  def init(options) do
    options
  end

  @doc """
  Example: %{t: "foo", q: 1}, "docker_image.tar.gz"
  This wont work until api is fixed to take in binary of file.
  """
  post "build" do
    IO.inspect conn.params
    payload = conn.params[:data]
    opts = conn.params[:data]
    Logger.info("Request to build image: #{payload}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    {:ok, body, code } = DockerApi.Image.build(List.first(hosts), opts, payload["filename"]["path"])
    send_resp(conn, 200, JSON.encode!(body))
  end

  get "/" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(host) -> 
      case DockerApi.Image.all(host) do
        {:ok, body, code} -> body
        _ -> []
      end
    end)

    {:ok, enc } = JSON.encode(res)
    send_resp(conn, 200, enc)
  end

  get ":id" do
    Logger.info("Request for image: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(x) -> 
      case DockerApi.Image.find(x, id) do
        {:ok, body, 404 } ->  [body]
        {:ok, body, code } -> body
        _ -> []
      end
    end)

    send_resp(conn, 200, JSON.encode!(res))
  end

  get ":id/history" do
    Logger.info("Request for image: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(x) -> 
      case DockerApi.Image.history(x, id) do
        {:ok, body, 404 } ->  [body]
        {:ok, body, code } -> body
        _ -> []
      end
    end)

    send_resp(conn, 200, JSON.encode!(res))
  end

  delete ":id/delete" do
    query_params = conn.params[:data]
    Logger.info("Request to delete image: #{id} with #{query_params}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(x) -> 
      case DockerApi.Image.history(x, id) do
        {:ok, body, 404 } ->  [body]
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
