defmodule DockerApiProxyTest do
  use ExUnit.Case
  use Plug.Test

  @opts DockerApiProxy.init([])

  test "returns all containers" do
    conn = conn(:get, "/containers")

    conn = DockerApiProxy.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "returns a specific container" do
    conn = conn(:get, "/container/d869ff64253835")

    conn = DockerApiProxy.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

end
