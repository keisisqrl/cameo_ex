defmodule CameoEx do
  @moduledoc """
  Documentation for CameoEx.
  """

  use Application

  @spec start(term(), term())  :: {:ok, pid}
  def start(_type, _args) do
    CameoEx.Supervisor.start_link
  end
end
