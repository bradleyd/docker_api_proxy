defmodule DockerApiProxy.Router do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch
  
  def init(options) do
    options
  end

  forward "/containers", to: DockerApiProxy.Server

end
