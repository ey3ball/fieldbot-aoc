defmodule Aoc.Scheduler do
  use Quantum, otp_app: :aoc

  def aocbot_today() do
    GenServer.cast(Process.whereis(:aocbot), :today)
  end

  def aocbot_heartbeat() do
    GenServer.cast(Process.whereis(:aocbot), :heartbeat)
  end
end
