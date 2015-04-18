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

    all = fn(host, _id) -> DockerApi.Container.all(host) end
    results = search_hosts(hosts, all, nil, [])
    send_response(conn, 200, results)
  end

  """ 
  Create a container

  Example params:
      `%{ "HostName": "", "Image": "redis", "ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
         "PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], "6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}`

  """
  post "/" do
    payload = conn.params[:data]
    Logger.info("Request to create container")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    # find the next host to build on
    results = round_robin_hosts(hosts)
    case DockerApi.Container.create(results.host, payload) do
      {:ok, body, code } ->
           send_response(conn, code, body)
      _ -> send_response(conn, 500, %{data: "something went wrong"})
    end
  end

  
  post ":id/start" do
    Logger.info("Request to start container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    payload = conn.params[:data]
    host = which_host(hosts, id, nil)
    case DockerApi.Container.start(host, id, payload) do
      {:ok, body, code } ->
        send_response(conn, code, body)
      _ -> 
        send_response(conn, 503, %{})
    end
  end

  post ":id/stop" do
    Logger.info("Request to stop container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    result = Enum.map(hosts, fn (host) ->
      case DockerApi.Container.find(hosts, id) do
        {:ok, body, 200 } when is_map(body) ->
          {:ok, body, code } = DockerApi.Container.stop(host, id)
          body
        _ -> %{data: "not found"}
      end
    end)
    send_response(conn, 200, result)
  end

  delete ":id" do
    Logger.info("Request to delete container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    result = Enum.map(hosts, fn (host) ->
      case DockerApi.Container.find(hosts, id) do
        {:ok, body, 200 } when is_map(body) ->
          {:ok, body, code } = DockerApi.Container.delete(host, id)
          body
        _ -> %{data: "not found"}
      end
    end)
    send_response(conn, 200, result)
  end

  @doc """
    Fetch a container

    id: container id

    * This searches all docker hosts in the registry

  """
  get ":id" do
    Logger.info("Request for container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    find = fn(host, id) -> DockerApi.Container.find(host, id) end
    results = search_hosts(hosts, find, id, [])
    case is_map(results) do
      true -> send_response(conn, 200, results)
      _ -> send_response(conn, 404, %{data: "not found"})
    end
  end

  @doc """
    Get Top for a container

    id: container id

  """
  get ":id/top" do
    Logger.info("Request top for container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    top = fn(host, id) -> DockerApi.Container.top(host, id) end
    results = search_hosts(hosts, top, id, [])
    send_response(conn, 200, results)
  end

  @doc """
    Get Logs for a container

    id: container id

  """
  get ":id/logs" do
    Logger.info("Request logs for container: #{id}")
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    logs = fn(host, iid) -> DockerApi.Container.logs(host, iid) end
    results = search_hosts(hosts, logs, id, [])
    send_response(conn, 200, results)
  end

  get "test/:id" do
    {:ok, hosts} = DockerApiProxy.Registry.keys(:registry)
    logs = fn(host, iid) -> DockerApi.Container.logs(host, iid) end
    results = search_hosts(hosts, logs, id, [])
    send_response(conn, 200, results)
  end

  match _ do
    send_resp(conn, 404, "No route in /containers")
  end

  defp search_hosts([], func, id, acc), do: acc
  defp search_hosts([h|t], func, id, acc) do
    case func.(h, id) do
        {:ok, body} when is_list(body) ->
          search_hosts([], func, id, body)
        {:ok, body, code} when is_map(body) ->
          search_hosts([], func, id, Map.merge(body, %{"DockerHost" => h}))
        {:ok, body, code} when is_list(body) ->
          search_hosts([], func, id, Enum.map(body, fn(container) -> Map.merge(container, %{"DockerHost" => h}) end))
        _ -> search_hosts(t, func, id, acc)
    end
  end
  
  defp send_response(conn, 200, payload) do
    send_resp(conn, 200, JSON.encode!(payload))
  end
  defp send_response(conn, 201, payload) do
    send_resp(conn, 201, JSON.encode!(payload))
  end
  defp send_response(conn, 204, payload) do
    send_resp(conn, 204, JSON.encode!(payload))
  end
  defp send_response(conn, 304, payload) do
    send_resp(conn, 304, JSON.encode!(payload))
  end
  defp send_response(conn, 404, payload) do
    send_resp(conn, 404, JSON.encode!(payload))
  end
  defp send_response(conn, 503, payload) do
    send_resp(conn, 503, JSON.encode!(payload))
  end
  defp send_response(conn, 304, payload) do
    send_resp(conn, 200, JSON.encode!(payload))
  end
  defp send_response(conn, _code, _payload) do
    send_resp(conn, 500, "something went terribly wrong")
  end


  defp which_host([], id, acc), do: acc
  defp which_host([h|t], id, acc) do
    case DockerApi.Container.find(h, id) do
      {:ok, body, 200 } when is_map(body) -> which_host([], id, h)
        _ -> which_host(t, id, acc) 
    end
  end

  defp round_robin_hosts(hosts) when is_list(hosts) do
    Enum.map(hosts, fn(h) ->                  
      {:ok, body, code} = DockerApi.Container.all(h)
      %{host: h, count: Enum.count(body)}
    end) |> 
    Enum.min_by(fn(x) -> x.count end)
  end
  
end
