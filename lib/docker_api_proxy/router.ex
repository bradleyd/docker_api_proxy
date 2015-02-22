defmodule DockerApiProxy.Router do
  use Plug.Router
  import Plug.Conn

  plug Plug.Logger
  plug :match
  plug :dispatch
  
  def init(options) do
    options
  end

  forward "/images", to: DockerApiProxy.Images.Router
  forward "/containers", to: DockerApiProxy.Containers.Router
  forward "/hosts", to: DockerApiProxy.Hosts.Router

  get "/hello" do
    send_resp(conn, 200, "\nworld")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

end
