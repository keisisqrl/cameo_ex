defmodule CameoEx.IrcServer.ConnectionSupervisor do
  @moduledoc """
  Supervises connections.

  Split out from IrcSupervisor for better separation of concerns, simpler
  start_child call in that module's accept loop.
  """
  use Supervisor
  alias CameoEx.IrcServer.ClientConnection

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(:ok) :: {:ok, {:supervisor.sup_flags, [Supervisor.Spec.spec]}} |
                     :ignore
  def init(:ok) do
    children = [
      worker(ClientConnection, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

end
