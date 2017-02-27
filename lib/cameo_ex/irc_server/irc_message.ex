defmodule CameoEx.IrcServer.IrcMessage do
  @moduledoc """
  Utility module for dealing with IRC messages
  """
  alias CameoEx.IrcServer.ClientConnection

  @sep " "
  @pre ":"
  @lf "\r\n"

  defstruct ~w(prefix command params)a

  @type t :: %__MODULE__{
    prefix: binary | charlist | nil,
    command: binary,
    params: [binary]
  }

  @spec parse_message(binary()) :: __MODULE__.t
  def parse_message(<<":", _::binary()>> = msg) do
    [prefix, rem] = get_prefix(msg)
    %__MODULE__{prefix: prefix} |> struct(Map.from_struct(parse_message(rem)))
  end

  def parse_message(msg) do
    [cmd, rem] = msg |> String.split(" ", parts: 2)
    %__MODULE__{command: cmd} |> struct(parse_params(rem))
  end

  @spec parse_params(binary()) :: %{params: [binary()]}
  def parse_params(msg) do
    if String.contains?(msg, " :") do
      [middle, trailing] = String.split(msg, " :", parts: 2)
      mid_params = String.split(middle)
      params = [mid_params, trailing] |> List.flatten
      %{params: params}
    else
      params = String.split(msg)
      %{params: params}
    end
  end

  @doc """
  Get prefix from IRC message with prefix
  """
  @spec get_prefix(binary()) :: list
  def get_prefix(<<":", _::binary()>> = msg) do
    msg |> String.split(" ", parts: 2)
  end

  @spec build_client_msg(ClientConnection.t,
                         binary(), [binary()]) :: __MODULE__.t
  def build_client_msg(%{registered: true} = client, command, params) do
    %__MODULE__{prefix: client_prefix(client), command: command,
                      params: params}
  end

  # Kind of a misnomer - actually formats nick!user@host user format
  @spec client_prefix(ClientConnection.t) :: binary()
  def client_prefix(client) do
    "#{client.nick}!#{client.user}@#{client.host}"
  end

  @spec build_server_msg(binary(), [binary()]) :: __MODULE__.t
  def build_server_msg(command, params) do
    %__MODULE__{prefix: elem(:inet.gethostname(), 1),
                command: command,
                params: params}
  end

  def nick_match, do: ~r/[[:alpha:][:punct:]][[:alnum:][:punct:]]/

  @spec to_iolist(__MODULE__.t) :: iolist()
  def to_iolist(msg) when is_map(msg) do
    [":", msg.prefix, " ", msg.command, " ", to_iolist(msg.params), @lf]
  end

  @spec to_iolist([binary()]) :: iolist()
  def to_iolist([param | []]), do: [":", param]
  def to_iolist([param | rem]), do: [[param, " "] | to_iolist(rem)]

end
