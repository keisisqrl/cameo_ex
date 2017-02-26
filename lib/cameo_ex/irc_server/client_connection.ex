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

  @type state :: __MODULE__.t

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

  # Handle empty line
  def handle_info({:tcp,_,"\n"}, state), do: {:noreply, state}

  def handle_info({:tcp,_,"\r\n"}, state), do: {:noreply, state}

  # Handle IRC message
  def handle_info({:tcp, socket, msg}, state) do
    message = IrcMessage.parse_message(String.trim(msg))
    {:noreply, handle_message(message, socket, state)}
  end

  @spec handle_message(IrcMessage.t,:gen_tcp.socket,__MODULE__.t) ::
          __MODULE__.t
  def handle_message(%IrcMessage{command: "NICK"} = msg, socket, state) do
  [nick|_] = msg.params
  if state.registered do
    reply = IrcMessage.build_client_msg(state,"NICK",[nick])
    :gen_tcp.send(socket, IrcMessage.to_iolist(reply))
  end
  %__MODULE__{state | nick: nick}
  end

  def handle_message(%IrcMessage{command: "USER"} = msg, socket, state) do
    cond do
      state.registered ->
        reply = IrcMessage.build_server_msg("462",
                  ["Unauthorized command (already registered)"])
        :gen_tcp.send(socket,IrcMessage.to_iolist(reply))
        state
      length(msg.params) < 4 ->
        reply = IrcMessage.build_server_msg("461",
                  ["USER", "Not enough parameters"])
        :gen_tcp.send(socket,IrcMessage.to_iolist(reply))
        state
      true ->
        [user, _, _, name|_] = msg.params
        %__MODULE__{state| user: user, name: name, registered: true}
      end
  end

end
