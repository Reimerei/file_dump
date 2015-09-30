defmodule FileDump.Utils do
  def chunk_file(<< chunk :: binary-size(1024), rest :: binary >>) do
     [chunk | chunk_file(rest)]
  end

  def chunk_file(<<>>) do
    []
  end

  def chunk_file(<< chunk :: binary >>) do
     [chunk]
  end
end
