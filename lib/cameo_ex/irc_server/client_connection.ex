defmodule CameoEx.IrcServer.ClientConnection do
  @moduledoc """
  Handles a connection from an IRC client including modeling state.
  """
  use GenServer
  alias CameoEx.IrcServer.IrcMessage
  require IEx

  defstruct [:socket,
             :status,
             :nick,
             :pass,
             :user,
             :name]

  @type t :: %__MODULE__{
    socket: :inet.socket,
    status: atom(),
    nick: nil|binary(),
    pass: nil|binary(),
    user: nil|binary(),
    name: nil|binary()
  }

  @spec start_link(:gen_tcp.socket()) :: {:ok, pid()}
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @spec init(:gen_tcp.socket()) :: {:ok, %__MODULE__{}}
  def init(socket) do
    {:ok, %__MODULE__{socket: socket, status: :connected}}
  end

  # Begin callbacks

  @spec handle_info({:tcp_closed, term()}, __MODULE__.t) ::
          {:stop, :normal, __MODULE__.t}
  # Handle closure
  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}

  @spec handle_info({:tcp, :inet.socket, binary()}, __MODULE__.t) ::
          {:noreply, __MODULE__.t}
  # Handle IRC message
  def handle_info({:tcp, socket, <<":", _::binary>> = msg}, state) do
    {prefix, rem} = IrcMessage.get_prefix(msg)
    handle_info({:tcp, socket, rem}, state, prefix)
  end

  @spec handle_info({:tcp, :inet.socket, binary()}, __MODULE__.t,
                    binary() | nil) ::
          {:noreply, __MODULE__.t}
  def handle_info({:tcp, socket, <<"NICK ", rest::binary>> = _msg},
                  state, _prefix \\ nil) do
    case String.split(rest) do
      [nick | _] ->

        {:noreply, %__MODULE__{state | nick: nick}}
      _ ->
        {:noreply, state}
    end
  end

end
