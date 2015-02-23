defmodule DockerApiProxy.Containers.Router do
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
    Logger.info("Request for all containers")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    res = Enum.flat_map(hosts, fn(host) -> 
      case DockerApi.Container.all(host) do
        {:ok, body, code} -> body
        _ -> []
      end
    end)

    {:ok, enc } = JSON.encode(res)
    send_resp(conn, 200, enc)
  end

  """ 
  Create a container

  Example params:
      `%{ "HostName": "", "Image": "redis", "ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
         "PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], "6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}`

  """
  post "/" do
    payload = conn.params[:data]
    Logger.info("Request to create container: #{payload}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    {:ok, body, code } = DockerApi.Container.create(List.first(hosts), payload)
    send_resp(conn, 200, JSON.encode!(body))
  end

  ## TODO need algorithm to choose the correct docker host least first, round robin
  post ":id/start" do
    Logger.info("Request to start container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    payload = conn.params[:data]
    {:ok, body, code} = DockerApi.Container.start(List.first(hosts), id, payload)
    send_resp(conn, code, JSON.encode!(body))
  end

  post ":id/stop" do
    Logger.info("Request to stop container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    {:ok, body, code } = DockerApi.Container.stop(List.first(hosts), id)
    send_resp(conn, code, JSON.encode!(body))
  end

  @doc """
    Fetch a container

    id: container id

    * This searches all docker hosts in the registry

  """
  get ":id" do
    Logger.info("Request for container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    case DockerApi.Container.find(hosts, id) do
      {:ok, body, 200 } when is_map(body) ->
           send_response(conn, 200, body)
      _ -> send_response(conn, 404, %{data: "not found"})
    end
  end

  match _ do
    send_resp(conn, 404, "No route in /containers")
  end

  defp send_response(conn, 200, payload) do
    send_resp(conn, 200, JSON.encode!(payload))
  end

  defp send_response(conn, 404, payload) do
    send_resp(conn, 200, JSON.encode!(payload))
  end

end
