defmodule Julex do
  use Application

  @moduledoc """
  Documentation for Julex.
  """

  def start(_type, _args) do
    Julex.Supervisor.start_link(name: Julex.Supervisor)
  end
end
