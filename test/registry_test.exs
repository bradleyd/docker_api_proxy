defmodule DockerApiProxy.RegistryTest do
  use ExUnit.Case

  setup do
    {:ok, registry} = DockerApiProxy.Registry.start_link(:test_table)
    {:ok, registry: registry, ets: :test_table}
  end

  test "can lookup host in registry",  %{registry: registry, ets: ets} do
    assert DockerApiProxy.Registry.lookup(ets, "192.168.2.100") == :error

    assert DockerApiProxy.Registry.insert(ets, {"192.168.200.100", "1234"}) == {:ok, "inserted"}
    assert DockerApiProxy.Registry.lookup(ets, "192.168.200.100") == {:ok, "1234"}
  end
end
