defmodule DockerApiProxy.Mixfile do
  use Mix.Project

  def project do
    [app: :docker_api_proxy,
     version: "0.0.2",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :cowboy, :plug, :docker_api]]
      #mod: {DockerApiProxy, [:registry]}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:plug, "~> 0.9"},
      {:exrm, "~> 0.15.3"},
      {:cowboy, "~> 1.0.0"},
      {:json,   "~> 0.3.0"},
      {:uuid, "~> 0.1.5" },
      {:docker_api, git: "https://github.com/bradleyd/docker_api.git"}
    ]   
  end
end
