defmodule DockerApiProxy.ContainerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts DockerApiProxy.Router.init([])

  @host "192.168.4.4:14443"
  @cid "971f52624eb3"

  setup do
    {:ok, pid} = DockerApiProxy.Supervisor.start_link
    {:ok, pid: pid}
  end

  test "returns all containers", %{pid: pid} do
    body = %{name: "127.0.0.1:14443"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])


    conn = conn(:get, "/containers")

    conn = DockerApiProxy.Router.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "returns a specific container" do
    body = %{name: @host}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])


    conn = conn(:get, "/container/#{@cid}")

    conn = DockerApiProxy.Router.call(conn, [])

    decoded = JSON.decode(conn.resp_body)
    IO.inspect decoded
    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
    assert {:ok, _} = decoded
  end 

  test "creates a container" do
    body = %{name: "192.168.4.4:14443"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])

    body  = %{ "Image": "redis",
               "HostName": "foobar",
               "ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
               "PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], 
                                  "6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}

    conn = conn(:post, "/containers", JSON.encode!(body), headers: [{"content-type", "application/json"}])

    conn = DockerApiProxy.Router.call(conn, [])

    {:ok, results } = JSON.decode(conn.resp_body)
    conn = conn(:post, "/container/#{results["Id"]}/start", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn = DockerApiProxy.Router.call(conn, [])
    response = JSON.decode(conn.resp_body)
    IO.inspect response
  end 

  test "starts a container" do
    body = %{name: "192.168.4.4:14443"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])

    body  = %{ "Image": "redis",
               "HostName": "foobar",
               "ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
               "PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], 
                                  "6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}

    conn = conn(:post, "/container/#{@cid}/start", JSON.encode!(body), headers: [{"content-type", "application/json"}])

    conn = DockerApiProxy.Router.call(conn, [])

    response = JSON.decode(conn.resp_body)
    IO.inspect response
  end 

  test "stops a container" do
    body = %{name: "192.168.4.4:14443"}
    conn1 = conn(:post, "/hosts", JSON.encode!(body), headers: [{"content-type", "application/json"}])
    conn1 = DockerApiProxy.Router.call(conn1, [])

    #body  = %{ "Image": "redis",
               #"HostName": "foobar",
               #"ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
               #"PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], 
                                  #"6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}

    #conn = conn(:post, "/container/#{@cid}/start", JSON.encode!(body), headers: [{"content-type", "application/json"}])

    #conn = DockerApiProxy.Router.call(conn, [])

    #response = JSON.decode(conn.resp_body)
    #IO.inspect response
    conn = conn(:post, "/container/#{@cid}/stop")

    conn = DockerApiProxy.Router.call(conn, [])

    response = JSON.decode(conn.resp_body)
    IO.inspect response
  end 


end
