defmodule KinoThreeJS.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(KinoMapLibre.MapCell)
    Kino.SmartCell.register(KinoThreeJS.SceneCell)

    children = []
    opts = [strategy: :one_for_one, name: KinoThreeJS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
