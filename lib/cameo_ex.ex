defmodule CameoEx do
  @moduledoc """
  Documentation for CameoEx.
  """

  @doc """
  Hello world.

  ## Examples

      iex> CameoEx.hello
      :world

  """
  use Application

  @spec start(term(),term())  :: {:ok, pid}
  def start(_type, _args) do
    CameoEx.Supervisor.start_link
  end
end
