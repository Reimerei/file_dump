[![Build Status](https://travis-ci.org/Reimerei/file_dump.svg?branch=master)](https://travis-ci.org/Reimerei/file_dump)

FileDump
========

Send files to a central server via UDP and write them to the file system. When a UDP packet is lost the corresponding file will be discarded.

The client is rate-limited to make sure it does not drown the network.

Server
--------

When the application is started it will open a UDP port (default: 7331) and wait for traffic from the clients. All files will be written relative to a configured base directory.

Config:
```elixir
config :file_dump, base_path: "/opt/store"  # base directory, where all files will be stored
config :file_dump, port: 7331               # listen port
```

Client
-------

The client can be started with `FileDump.Client.start_link()`.

You can then send files with:
```elixir
send_file(path, file_name, content)
```

Config:
```elixir
config :file_dump, remote_host: 'remote_log',  # hostname of the server
config :file_dump, port: 7331                  # port of the server
config :file_dump, send_rate: 100              # maximum files send per second
```
