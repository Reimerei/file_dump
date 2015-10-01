file = File.read!("test/files/file1")
{:ok, client} = FileDump.Client.start_link(4444)
FileDump.Client.send_file(client, "path", "name", file)
:timer.sleep(500)
profile = fn() -> FileDump.Client.send_file(client, "path", "name", file); :timer.sleep(500) end

:fprofx.apply(profile, [], [{:procs, :erlang.processes -- [:erlang.whereis(:fprofx_server), ], }])
:fprofx.profile
:fprofx.analyse([{:dest, '/tmp/fprof.analysis'}]) #
filename = "profile.cgrind"
IO.puts("writing #{filename}")
Mix.shell.cmd("deps/fprofx/erlgrindx /tmp/fprof.analysis #{filename}")
