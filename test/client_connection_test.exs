defmodule ClientConnectionTest do
  use ExUnit.Case, async: true
  import Mock
  alias CameoEx.IrcServer.{IrcMessage,ClientConnection}

  defmacrop mock_tcp(do: test) do
    quote do
      with_mock :gen_tcp, [:unstick], [send: fn(_,_) -> :ok end] do
        unquote(test)
      end
    end
  end

  defmacrop sent_server_msg(cmd,params) do
    quote do
      called :gen_tcp.send(nil,IrcMessage.to_iolist(
        IrcMessage.build_server_msg(unquote(cmd),unquote(params))
      ))
    end
  end

  setup_all do
    Application.ensure_started :cameo_ex
  end

  describe "handle NICK:" do
    setup [:msg_tests, :nick_tests]

    test "unregistered" do
      state = %ClientConnection{}
      newnick = "newnick"
      msg = %IrcMessage{command: "NICK",
                        params: [newnick]}
      new_state = ClientConnection.handle_message(msg,nil,state)
      assert new_state == %{state| nick: "newnick"}
    end

    test "registered", context do
      mock_tcp do
        state = %{context.state| registered: true}
        new_state = ClientConnection.handle_message(
          context.msg,
          nil,
          state)
        assert new_state == %{state| nick: "newnick"}
        assert called :gen_tcp.send(nil,
                IrcMessage.to_iolist(
                  IrcMessage.build_client_msg(
                    state,
                    context.msg.command,
                    context.msg.params
                  )
                )
        )
        end
    end
  end

  describe "handle USER:" do
    setup [:msg_tests, :user_tests]

    test "success", context do
      mock_tcp do
        new_state = ClientConnection.handle_message(context.msg,nil,context.state)
        assert new_state == %{context.state| user: context.newuser,
                                             name: context.realname,
                                             registered: true}
      end
    end

    test "registered", context do
      state = %{context.state| registered: true}
      mock_tcp do
        new_state = ClientConnection.handle_message(context.msg,nil,state)
        assert new_state == state
        assert sent_server_msg("462",
          ["Unauthorized command (already registered)"])
      end
    end

    test "not enough params", context do
      msg = %{context.msg| params: ["too", "short"]}
      mock_tcp do
        new_state = ClientConnection.handle_message(msg, nil, context.state)
        assert new_state == context.state
        assert sent_server_msg("461",[msg.command,"Not enough parameters"])
      end
    end
  end

  describe "handle PASS:" do
    setup [:msg_tests, :pass_tests]

    test "success", context do
      mock_tcp do
        new_state = ClientConnection.handle_message(context.msg, nil, context.state)
        assert new_state == %{context.state| pass: context.pass}
      end
    end
  end

  describe "handle INVALID:" do
    setup :msg_tests

    test "error", context do
      mock_tcp do
        msg = %{context.msg| command: "INVALID"}
        new_state = ClientConnection.handle_message(msg, nil, context.state)
        assert new_state == context.state
        assert sent_server_msg("421",[msg.command,"Unknown command"])
      end
    end
  end

  defp msg_tests(_context) do
    [
      state: %ClientConnection{
        nick: "oldnick",
        user: "user",
        host: "host",
        name: "real name"
      },
      msg: %IrcMessage{}
    ]
  end

  defp nick_tests(context) do
    newnick = "newnick"
    [
      newnick: newnick,
      msg: %{context.msg|
        command: "NICK",
        params: [newnick]
      }
    ]
  end

  defp user_tests(context) do
    newuser = "newuser"
    realname = "Real Name"
    [
      state: %ClientConnection{},
      msg: %IrcMessage{context.msg|
        command: "USER",
        params: [newuser, "*", "*", realname]
      },
      newuser: newuser,
      realname: realname
    ]
  end

  defp pass_tests(context) do
    pass = "pass"
    [
      state: %ClientConnection{},
      msg: %{context.msg|
        command: "PASS",
        params: [pass]
      },
      pass: pass
    ]
  end

end
