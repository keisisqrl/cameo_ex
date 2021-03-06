defmodule CameoExTest do
  use ExUnit.Case
  doctest CameoEx

  setup do
    [irc_port: Application.get_env(:cameo_ex,:irc_port)]
  end


  describe "Connect then" do
    @tag :live_tcp
    test "QUIT", context do
      {:ok, socket} = :gen_tcp.connect({127,0,0,1}, context.irc_port,
                                       [packet: :line, active: true], 100)
      :gen_tcp.send(socket, "QUIT\r\n")
      assert_receive {:tcp_closed, ^socket}
    end

    @tag :live_tcp
    @tag skip: "Crashes listener - need to fix listener"
    test "disconnect", context do
      {:ok, socket} = :gen_tcp.connect({127,0,0,1}, context.irc_port, [], 100)
      :gen_tcp.close(socket)
      assert Enum.any?(Application.started_applications,
                       fn(x) -> match?({:cameo_ex,_,_},x) end)
    end
  end
end
