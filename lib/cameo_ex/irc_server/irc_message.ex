defmodule CameoEx.IrcServer.IrcMessage do
  @moduledoc """
  Utility module for dealing with IRC messages
  """
  alias CameoEx.IrcServer.ClientConnection

  @sep " "
  @pre ":"
  @lf "\r\n"

  defstruct prefix: elem(:inet.gethostname(),1), command: nil, params: nil

  @type t :: %__MODULE__{
    prefix: binary | charlist,
    command: binary,
    params: [binary]
  }

  @doc """
  Get prefix from IRC message with prefix
  """
  @spec get_prefix(binary()) :: {binary(), binary()}
  def get_prefix(<<":", _::binary()>> = msg) do
    msg |> String.split(" ", parts: 2) |> List.to_tuple
  end

  # Dialyzer doesn't like ClientConnection.t in this typespec, not sure why.
  @spec build_client_msg(ClientConnection.t,
                         binary(), [binary()]) :: __MODULE__.t
  def build_client_msg(%{registered: true} = client, command, params) do
    %__MODULE__{prefix: client_prefix(client), command: command,
                      params: params}
  end

  # Or this one. Tough, dialyzer.
  @spec client_prefix(ClientConnection.t) :: binary()
  defp client_prefix(client) do
    ":#{client.nick}!#{client.prefix}@#{client.host}"
  end

  def nick_match, do: ~r/[[:alpha:][:punct:]][[:alnum:][:punct:]]/

  @spec to_iolist(__MODULE__.t) :: iolist()
  def to_iolist(msg) when is_map(msg) do
    [":", msg.prefix, " ", msg.command, " ", to_iolist(msg.params)]
  end

  @spec to_iolist([binary()]) :: iolist()
  def to_iolist([param | []]), do: [":", param]
  def to_iolist([param | rem]), do: [[param, " "] | to_iolist(rem)]

end
