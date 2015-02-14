require Logger

defmodule DockerApiProxy do
  use Application 

  def start(_type, _args) do
    opts  = [port: 4000, compress: true, linger: {true, 10}]

    #if port = System.get_env("PORT") do
      #opts = Keyword.put(opts, :port, String.to_integer(port))
    #end

    #config(opts[:port])
    #File.mkdir_p!("tmp")

    Logger.info "Starting Cowboy on port #{opts[:port]}"
    Plug.Adapters.Cowboy.http(DockerApiProxy.Server, [], opts)
    DockerApiProxy.Supervisor.start_link
  end
end
