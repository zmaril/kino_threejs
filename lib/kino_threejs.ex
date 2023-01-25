defimpl Kino.Render, for: MapLibre do
  def to_livebook(ml) do
    ml |> Kino.MapLibre.static() |> Kino.Render.to_livebook()
  end
end

defimpl Kino.Render, for: Kino.MapLibre do
  def to_livebook(ml) do
    ml |> Kino.MapLibre.static() |> Kino.Render.to_livebook()
  end
end

# defining our own threejs implemenation in here too?
defimpl Kino.Render, for: KinoThreeJS.ThreeJS do
  def to_livebook(ml) do
    ml |> Kino.ThreeJS.static() |> Kino.Render.to_livebook()
  end
end


defimpl Kino.Render, for: Kino.ThreeJS do
  def to_livebook(ml) do
    ml |> Kino.ThreeJS.static() |> Kino.Render.to_livebook()
  end
end
