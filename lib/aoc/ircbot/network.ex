defmodule Aoc.IrcBot.Network do
  def start_link(client, config) do
    GenServer.start_link(__MODULE__, {client, config}, [])
  end

  def init({client, config}) do
    ExIRC.Client.add_handler(client, self())
    ExIRC.Client.connect!(client, config.host, config.port)

    {:ok, %{:client => client, :config => config}}
  end

  def handle_info(
      {:connected, server, port},
      %{:client => client, :config => config} = state) do
    IO.puts(IO.ANSI.green()
      <> "Connected to #{server}:#{port}" <> IO.ANSI.reset()
    )
    ExIRC.Client.logon(client, config.pass, config.nick, config.user, config.name)

    {:noreply, state}
  end

  def handle_info({:login_failed, _}, config) do
    IO.puts(IO.ANSI.red()
      <> "Loggin failed" <> IO.ANSI.red()
    )
    {:noreply, config}
  end

  def handle_info(:logged_in, %{:client => _client} = state) do
    IO.puts(IO.ANSI.green()
      <> "Logged in to server" <> IO.ANSI.reset()
    )

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    #IO.puts(IO.ANSI.green()
    #  <> "Unhandled: #{_msg}" <> IO.ANSI.reset()
    #)
    {:noreply, state}
  end
end
