defmodule DockerApiProxy.ImageTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts DockerApiProxy.Router.init([])

  @host "192.168.4.4:14443"
  @cid "971f52624eb3"

  setup do
    {:ok, pid} = DockerApiProxy.Supervisor.start_link
    {:ok, pid: pid}
  end

  test "returns all images", %{pid: pid} do
    body = %{name: @host}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])


    conn = conn(:get, "/images")

    conn = DockerApiProxy.Router.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "returns a specific image" do
    body = %{name: @host}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])


    conn = conn(:get, "/image/#{@cid}")

    conn = DockerApiProxy.Router.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    IO.inspect decoded
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "creates a image" do
    body = %{name: @host}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])

    body  = %{ "fromImage": "127.0.0.1:5000/redis:latest" }
    conn = conn(:post, "/images", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn = DockerApiProxy.Router.call(conn, [])
    {:ok, results } = JSON.decode(conn.resp_body)
    IO.inspect results
  end 


end
