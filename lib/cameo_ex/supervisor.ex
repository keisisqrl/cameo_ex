defmodule CameoEx.Supervisor do
  @moduledoc """
  Supervisor for CameoEx
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(:ok) :: no_return()
  def init(:ok) do
    children = [
      supervisor(CameoEx.IrcServer.IrcSupervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
