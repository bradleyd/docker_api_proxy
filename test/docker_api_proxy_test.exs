defmodule DockerApiProxy.ServerTest do
  use ExUnit.Case
  use Plug.Test

  @opts DockerApiProxy.Server.init([])

  setup do
    {:ok, pid} = DockerApiProxy.Supervisor.start_link
    {:ok, pid: pid}
  end

  test "returns all containers", %{pid: pid} do
    body = %{name: "127.0.0.1:14443"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Server.call(conn1, [])


    conn = conn(:get, "/containers")

    conn = DockerApiProxy.Server.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "returns a specific container" do
    conn = conn(:get, "/container/d869ff64253835")

    conn = DockerApiProxy.Server.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "returns all the docker hosts registered" do
    body = %{name: "192.168.1.100"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Server.call(conn1, [])


    conn = conn(:get, "/hosts")

    conn = DockerApiProxy.Server.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, ["192.168.1.100"]} = decoded

  end
  
  test "new docker host register's and gets a token back" do
    body = %{name: "192.168.1.100"}
    conn = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn = DockerApiProxy.Server.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 201
    assert {:ok, %{"token" => _token }} = decoded
  end

  test "already registered docker host tries to register again" do
    body = %{name: "192.168.1.100"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Server.call(conn1, [])

    body = %{name: "192.168.1.100"}
    conn2 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn2 = DockerApiProxy.Server.call(conn2, [])


    decoded1 = JSON.decode(conn1.resp_body)
    decoded2 = JSON.decode(conn2.resp_body)
    {:ok, %{"token" => token1 }} = decoded1
    {:ok, %{"token" => token2 }} = decoded2

    assert token1 == token2
  end

end
