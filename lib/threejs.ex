defmodule KinoThreeJS.ThreeJS do
  defstruct spec: %{}
  def new(opts \\ []) do
    %KinoThreeJS.ThreeJS{spec: ""}
  end
end
