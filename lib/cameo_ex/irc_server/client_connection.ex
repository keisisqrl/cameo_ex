defmodule CameoEx.IrcServer.ClientConnection do
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

  @spec handle_info(msg :: {:tcp_closed, any()} | {:tcp,
                                                             :inet.socket,
                                                             binary()},
                    __MODULE__.t) ::
                    {:noreply, __MODULE__.t} | {:stop, :normal, :state}
  # Handle closure
  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}

  # Handle IRC message
  def handle_info({:tcp, socket, << ":", _::binary >> = msg}, state) do
    {prefix,rem} = IrcMessage.get_prefix(msg)
    handle_info({:tcp, socket, rem}, state, prefix)
  end

  def handle_info({:tcp, socket, << "NICK ", rest::binary >> = msg},
                  state, prefix \\ nil) do
    case String.split(rest) do
      [nick|_] ->
        {:noreply, %__MODULE__{state| nick: nick}}
      _ ->
        {:noreply, state}
    end
  end


end
