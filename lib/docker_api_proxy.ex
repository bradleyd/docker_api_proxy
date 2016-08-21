require Logger

defmodule DockerApiProxy do
  use Application 

  def start(_,_) do
    start 
  end
  
  def start() do
    opts  = [port: 4000, ip: {127,0,0,0}, compress: true, linger: {true, 10}]

    if port = System.get_env("DOCKER_PROXY_PORT") do
      opts = Keyword.put(opts, :port, String.to_integer(port))
    end

    if ip = System.get_env("DOCKER_PROXY_INTERFACE") do
      {:ok, ip_tuple} = :inet.parse_address(to_char_list(ip))
      opts = Keyword.put(opts, :ip, ip_tuple)
    end

    Logger.info "Starting Cowboy on port #{ip}:#{opts[:port]}"
    Plug.Adapters.Cowboy.http(DockerApiProxy.Router, [], opts)
    DockerApiProxy.Supervisor.start_link
  end
end
