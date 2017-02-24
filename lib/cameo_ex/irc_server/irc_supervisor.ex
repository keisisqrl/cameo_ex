defmodule CameoEx.IrcServer.IrcSupervisor do
  use Supervisor
  alias CameoEx.IrcServer.ClientConnection

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(:ok) :: {:ok, {:supervisor.sup_flags, [Supervisor.Spec.spec]}} |
                     :ignore
  def init(:ok) do
    listen_port = Application.get_env(:cameo_ex,:irc_port)
    children = [
      worker(Task, [__MODULE__,:listen,[listen_port]], restart: :temporary)
    ]

    supervise(children, strategy: :one_for_one)
  end

  @spec listen(integer()) :: no_return()
  def listen(port) do
    {:ok, socket} = :gen_tcp.listen(port, packet: :line, mode: :binary)
    accept(socket)
  end

  defp accept(socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    {:ok, child} = Supervisor.start_child(__MODULE__,
                                          worker(ClientConnection,[conn]))
    :ok = :gen_tcp.controlling_process(conn,child)
    accept(socket)
  end

end
