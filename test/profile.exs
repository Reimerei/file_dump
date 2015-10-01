file = File.read!("test/files/file1")
{:ok, client} = FileDump.Client.start_link(4444)
FileDump.Client.send_file(client, "path", "name", file)
