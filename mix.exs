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
        # server settings
        port: 7331,
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
      {:logfilter, github: "reimerei/logfilter",  branch: "master"},
      {:syslog,    github: "reimerei/syslog",     branch: "master"},

      {:mock, "~> 0.1.1"},
      {:exrm, "~> 0.19.9"},
    ]
  end
end
