defmodule CameoEx.IrcServer.IrcMessage do
  @sep " "
  @pre ":"
  @lf "\r\n"

  defstruct prefix: elem(:inet.gethostname(),1), command: nil, params: nil

  @type t :: %__MODULE__{
    prefix: nil | binary,
    command: nil | binary,
    params: nil | [binary]
  }

  def get_prefix(<<":", _::binary()>> = msg) do
    msg |> String.split(" ", parts: 2) |> List.to_tuple
  end

  def nick_match, do: ~r/[[:alpha:][:punct:]][[:alnum:][:punct:]]/

end
