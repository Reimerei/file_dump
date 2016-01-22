defmodule FileDump.Mixfile do
  use Mix.Project

  def project do
    [app: :file_dump,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      applications: [:logger],
      env: [
        port: 7331,
        # server settings
        base_path: "./store",
        #client settings
        remote_host: 'localhost',
        send_rate: 100 # max files per second
      ],
      mod: {FileDump, []},
    ]
  end

  defp deps do
    [
      {:mock, "~> 0.1.1"},
      {:exrm, "~> 0.19.9"},
    ]
  end
end
