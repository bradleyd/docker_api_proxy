defmodule DockerApiProxy.Plugs.Parsers.JSON do
  @moduledoc false
  alias Plug.Conn
 
  def parse(%Conn{} = conn, "application", "json", _headers, opts) do
    case Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        {:ok, %{data: JSON.decode!(body)}, conn}
      {:more, _data, conn} ->
        {:error, :too_large, conn}
    end
  end
 
  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
