defmodule FileDump do
  use Application

  def start(_type, _args) do
    FileDump.Supervisor.start_link()
  end
end
