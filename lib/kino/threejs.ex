defmodule Kino.ThreeJS do
  @moduledoc """
  Kino for three.js
  """

  use Kino.JS, assets_path: "lib/assets/threejs"
  use Kino.JS.Live

  defstruct spec: %{}, events: %{}

  def new(%KinoThreeJS.ThreeJS{} = ml) do
    ml = %{spec: ml.spec, events: %{}}
    Kino.JS.Live.new(__MODULE__, ml)
  end

  def new(%__MODULE__{} = ml) do
    Kino.JS.Live.new(__MODULE__, ml)
  end

  @doc false
  def static(%__MODULE__{} = ml) do
    data = %{spec: ml.spec, events: ml.events}
    Kino.JS.new(__MODULE__, data, export_info_string: "threejs")
  end

  def static(%KinoThreeJS.ThreeJS{} = ml) do
    data = %{spec: ml.spec, events: %{}}
    Kino.JS.new(__MODULE__, data, export_info_string: "threejs")
  end
end
