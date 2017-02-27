defmodule CameoEx.IrcServer.IrcMessage do
  @moduledoc """
  Utility module for dealing with IRC messages
  """
  alias CameoEx.IrcServer.ClientConnection

  @sep " "
  @pre ":"
  @lf "\r\n"

  defstruct ~w(prefix command params)a

  defp hostname, do: Application.get_env(:cameo_ex, :hostname)

  @type t :: %__MODULE__{
    prefix: binary | nil,
    command: binary,
    params: [binary] | []
  }

  @doc """
  Parses `message` into an IrcMessage struct.

  ## Examples

      iex> parse_message(":foo NICK bar")
      %IrcMessage{prefix: "foo", command: "NICK", params: ["bar"]}
      iex> parse_message("USER zelda * * :Princess Zelda")
      %IrcMessage{prefix: nil, command: "USER", params: ["zelda", "*", "*",
                                                         "Princess Zelda"]}
      iex> parse_message("QUIT")
      %IrcMessage{prefix: nil, command: "QUIT", params: []}
  """
  @spec parse_message(binary()) :: __MODULE__.t
  def parse_message(<<":", _::binary()>> = msg) do
    [prefix, rem] = get_prefix(msg)
    %{parse_message(rem)| prefix: prefix}
  end

  def parse_message(msg) do
    case msg |> String.split(" ", parts: 2) do
      [cmd| []] -> %__MODULE__{command: cmd, params: []}
      [cmd, rem] -> %__MODULE__{command: cmd, params: parse_params(rem)}
    end
  end

  @doc """
  Parse params from params part of IRC message `msg`.

      iex> parse_params("one")
      ["one"]
      iex> parse_params("one two")
      ["one", "two"]
      iex> parse_params("one :two three")
      ["one", "two three"]
  """
  @spec parse_params(binary()) :: [binary()]
  def parse_params(msg) do
    if String.contains?(msg, " :") do
      [middle, trailing] = String.split(msg, " :", parts: 2)
      mid_params = String.split(middle)
      [mid_params, trailing] |> List.flatten
    else
      String.split(msg)
    end
  end

  @doc """
  Get prefix from IRC message with prefix

      iex> get_prefix(":foo BAR")
      ["foo", "BAR"]
  """
  @spec get_prefix(binary()) :: list
  def get_prefix(<<":", msg::binary()>> = _) do
    msg |> String.split(" ", parts: 2)
  end

  @doc """
  Build a message as though from a client.

      iex> client = %CameoEx.IrcServer.ClientConnection{registered: true,
      ...> nick: "nick", user: "user", host: "hostname"}
      iex> build_client_msg(client, "TEST", ["one", "two"])
      %IrcMessage{prefix: "nick!user@hostname", command: "TEST", params: ["one", "two"]}
      iex> badclient = %{client| registered: false}
      iex> build_client_msg(badclient, "TEST", ["one", "two"])
      ** (ArgumentError) client must be registered
  """
  @spec build_client_msg(ClientConnection.t,
                         binary(), [binary()]) :: __MODULE__.t
  def build_client_msg(%{registered: true} = client, command, params) do
    %__MODULE__{prefix: client_prefix(client), command: command,
                      params: params}
  end

  def build_client_msg(%{registered: false} = _, _, _) do
    raise ArgumentError, "client must be registered"
  end

  # Kind of a misnomer - actually formats nick!user@host user format
  @spec client_prefix(ClientConnection.t) :: binary()
  def client_prefix(client) do
    "#{client.nick}!#{client.user}@#{client.host}"
  end

  @spec build_server_msg(binary(), [binary()]) :: __MODULE__.t
  def build_server_msg(command, params) do
    %__MODULE__{prefix: hostname(),
                command: command,
                params: params}
  end

  @spec to_iolist(__MODULE__.t) :: iolist()
  def to_iolist(msg) when is_map(msg) do
    [":", msg.prefix, " ", msg.command, " ", to_iolist(msg.params), @lf]
  end

  @spec to_iolist([binary()]) :: iolist()
  def to_iolist([param | []]), do: [":", param]
  def to_iolist([param | rem]), do: [[param, " "] | to_iolist(rem)]

end
