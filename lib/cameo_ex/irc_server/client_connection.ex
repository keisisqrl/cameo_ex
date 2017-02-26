defmodule CameoEx.IrcServer.ClientConnection do
  @moduledoc """
  Handles a connection from an IRC client including modeling state.
  """
  use GenServer
  alias CameoEx.IrcServer.IrcMessage
  require IEx

  defstruct socket: nil,
            registered: false,
            nick: "",
            pass: "",
            user: "",
            name: "",
            host: ""

  @type t :: %__MODULE__{
    socket: :inet.socket,
    registered: boolean,
    nick: binary(),
    pass: binary(),
    user: binary(),
    name: binary(),
    host: binary()
  }

  @spec start_link(:gen_tcp.socket()) :: {:ok, pid()}
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @spec init(:gen_tcp.socket()) :: {:ok, %__MODULE__{}}
  def init(socket) do
    {:ok, {peer, _}} = :inet.peername(socket)
    {:ok, %__MODULE__{socket: socket, host: :inet.ntoa(peer)}}
  end

  # Begin callbacks

  @spec handle_info({:tcp_closed, term()}, __MODULE__.t) ::
          {:stop, :normal, __MODULE__.t}
  # Handle closure
  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}

  @spec handle_info({:tcp, :inet.socket, binary()}, __MODULE__.t) ::
          {:noreply, __MODULE__.t}
  # Handle IRC message with prefix
  def handle_info({:tcp, socket, <<":", _::binary>> = msg}, state) do
    {prefix, rem} = IrcMessage.get_prefix(msg)
    handle_info({:tcp, socket, rem}, state, prefix)
  end

  @spec handle_info({:tcp, :inet.socket, binary()}, __MODULE__.t,
                    binary() | nil) ::
          {:noreply, __MODULE__.t}

  # Begin IRC message handlers, post stripping prefix
  def handle_info({:tcp, socket, <<"NICK ", rest::binary>> = _msg},
                  state, _prefix \\ nil) do
    [nick | _] = String.split(rest)
    if state.registered do
      reply = IrcMessage.build_client_msg(state,"NICK",[nick])
      :gen_tcp.send(socket, IrcMessage.to_iolist(reply))
    end
    {:noreply, %__MODULE__{state | nick: nick}}
  end

end
