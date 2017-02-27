defmodule CameoEx.IrcServer.IrcSupervisor do
  @moduledoc """
  Supervise an IRC Server instance

  Includes listen function, which lives in a Task.
  """
  use Supervisor
  alias CameoEx.IrcServer.ClientConnection
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(:ok) :: {:ok, {:supervisor.sup_flags, [Supervisor.Spec.spec]}} |
                     :ignore
  def init(:ok) do
    listen_port = Application.get_env(:cameo_ex, :irc_port)
    children = [
      worker(Task, [__MODULE__, :listen, [listen_port]], restart: :transient)
    ]

    supervise(children, strategy: :one_for_one)
  end

  @spec listen(integer()) :: no_return()
  def listen(port) do
    {:ok, socket} = :gen_tcp.listen(port, packet: :line, mode: :binary)
    Logger.info("Listening on port #{port} for IRC")
    accept(socket)
  end

  @spec accept(:gen_tcp.socket()) :: no_return()
  defp accept(socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    {:ok, child} = Supervisor.start_child(__MODULE__,
                                worker(ClientConnection, [conn],
                                id: {ClientConnection, :erlang.make_ref()},
                                restart: :temporary))
    :ok = :gen_tcp.controlling_process(conn, child)
    accept(socket)
  end

end
