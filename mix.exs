defmodule FileDump.Mixfile do
  use Mix.Project

  def project do
    [app: :file_dump,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:logger],
      env: [
        base_path: "./store",
        packet_size: 1024,
        port: 7331,
        remote_host: 'localhost',
        send_rate: 100 # max files per second
      ],
      mod: {FileDump, []},
    ]
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
      {:mock, "~> 0.1.1"},
      # {:fprofx,               [git: "git:fprofx",                       branch: "master"                ]},
    ]
  end
end
