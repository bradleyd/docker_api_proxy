defmodule DockerApiProxy.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup do
    {:ok, pid} = DockerApiProxy.Supervisor.start_link
    {:ok, pid: pid}
  end

  test "hello" do
    conn = conn(:get, "hello")

    conn = DockerApiProxy.Router.call(conn, [])

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
  end
  
end
