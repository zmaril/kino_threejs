defmodule KinoMapLibre.MapCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/map_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Map"

  @as_int ["zoom", "layer_radius"]
  @as_atom ["layer_type"]
  @as_float ["layer_opacity"]
  @source_fields ["source_id", "source_data", "source_type"]
  @geometries [Geo.Point, Geo.LineString, Geo.Polygon, Geo.GeometryCollection]

  @impl true
  def init(attrs, ctx) do
    root_fields = %{
      "style" => attrs["style"] || "default",
      "center" => attrs["center"],
      "zoom" => attrs["zoom"] || 0
    }

    sources = attrs["sources"] || empty_source()

    layers = attrs["layers"] || empty_layer()

    ctx =
      assign(ctx,
        root_fields: root_fields,
        sources: sources,
        layers: layers,
        ml_alias: nil,
        source_variables: [],
        missing_dep: missing_dep()
      )

    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(pid, binding, env) do
    source_variables =
      for {key, val} <- binding,
          is_geometry(val),
          type = if(is_struct(val), do: "geo", else: "url"),
          do: %{variable: Atom.to_string(key), type: type}

    ml_alias = ml_alias(env)
    send(pid, {:scan_binding_result, source_variables, ml_alias})
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      root_fields: ctx.assigns.root_fields,
      sources: ctx.assigns.sources,
      layers: ctx.assigns.layers,
      source_variables: ctx.assigns.source_variables,
      missing_dep: ctx.assigns.missing_dep
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, source_variables, ml_alias}, ctx) do
    ctx = assign(ctx, ml_alias: ml_alias, source_variables: source_variables)
    broadcast_event(ctx, "set_source_variables", %{"source_variables" => source_variables})
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value, "idx" => nil}, ctx) do
    parsed_value = parse_value(field, value)
    ctx = update(ctx, :root_fields, &Map.put(&1, field, parsed_value))
    broadcast_event(ctx, "update_root", %{"fields" => %{field => parsed_value}})
    {:noreply, ctx}
  end

  def handle_event(
        "update_field",
        %{"field" => "source_type" <> _, "value" => value, "idx" => idx},
        ctx
      ) do
    source = get_in(ctx.assigns.sources, [Access.at(idx)])
    source_data = if value == "variable", do: List.first(ctx.assigns.source_variables).variable
    updated_source = %{source | "source_type" => value, "source_data" => source_data}
    updated_sources = List.replace_at(ctx.assigns.sources, idx, updated_source)
    ctx = %{ctx | assigns: %{ctx.assigns | sources: updated_sources}}

    broadcast_event(ctx, "update_source", %{
      "idx" => idx,
      "fields" => %{"source_type" => value, "source_data" => source_data}
    })

    {:noreply, ctx}
  end

  def handle_event("update_field", %{"field" => field, "value" => value, "idx" => idx}, ctx)
      when field in @source_fields do
    parsed_value = parse_value(field, value)
    updated_sources = put_in(ctx.assigns.sources, [Access.at(idx), field], parsed_value)
    ctx = %{ctx | assigns: %{ctx.assigns | sources: updated_sources}}
    broadcast_event(ctx, "update_source", %{"idx" => idx, "fields" => %{field => parsed_value}})

    {:noreply, ctx}
  end

  def handle_event("update_field", %{"field" => field, "value" => value, "idx" => idx}, ctx) do
    parsed_value = parse_value(field, value)
    updated_layers = put_in(ctx.assigns.layers, [Access.at(idx), field], parsed_value)
    ctx = %{ctx | assigns: %{ctx.assigns | layers: updated_layers}}
    broadcast_event(ctx, "update_layer", %{"idx" => idx, "fields" => %{field => parsed_value}})

    {:noreply, ctx}
  end

  def handle_event("add_source", _, ctx) do
    updated_sources = ctx.assigns.sources ++ empty_source()
    ctx = %{ctx | assigns: %{ctx.assigns | sources: updated_sources}}
    broadcast_event(ctx, "set_sources", %{"sources" => updated_sources})

    {:noreply, ctx}
  end

  def handle_event("add_layer", _, ctx) do
    updated_layers = ctx.assigns.layers ++ empty_layer()
    ctx = update_in(ctx.assigns, fn assigns -> Map.put(assigns, :layers, updated_layers) end)
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
  end

  def handle_event("remove_source", %{"source" => idx}, ctx) do
    updated_sources = List.delete_at(ctx.assigns.sources, idx)
    ctx = update_in(ctx.assigns, fn assigns -> Map.put(assigns, :sources, updated_sources) end)
    broadcast_event(ctx, "set_sources", %{"sources" => updated_sources})

    {:noreply, ctx}
  end

  def handle_event("remove_layer", %{"layer" => idx}, ctx) do
    updated_layers = List.delete_at(ctx.assigns.layers, idx)
    ctx = update_in(ctx.assigns, fn assigns -> Map.put(assigns, :layers, updated_layers) end)
    broadcast_event(ctx, "set_layers", %{"layers" => updated_layers})

    {:noreply, ctx}
  end

  defp parse_value(_field, ""), do: nil
  defp parse_value(field, value) when field in @as_int, do: String.to_integer(value)
  defp parse_value(field, value) when field in @as_float, do: value |> Float.parse() |> elem(0)
  defp parse_value(_field, value), do: value

  defp convert_field(field, nil), do: {String.to_atom(field), nil}

  defp convert_field("center", center) do
    Regex.named_captures(~r/(?<lng>-?\d+\.?\d*),\s*(?<lat>-?\d+\.?\d*)/, center)
    |> case do
      %{"lat" => lat, "lng" => lng} ->
        {{lng, _}, {lat, _}} = {Float.parse(lng), Float.parse(lat)}
        {:center, {lng, lat}}

      _ ->
        {:center, nil}
    end
  end

  defp convert_field("zoom", 0), do: {:zoom, nil}

  defp convert_field("style", "default"), do: {:style, nil}

  defp convert_field(field, value) when field in @as_atom do
    {String.to_atom(field), String.to_atom(value)}
  end

  defp convert_field(field, value), do: {String.to_atom(field), value}

  defp ml_alias(%Macro.Env{aliases: aliases}) do
    case List.keyfind(aliases, MapLibre, 1) do
      {ml_alias, _} -> ml_alias
      nil -> MapLibre
    end
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.root_fields
    |> Map.put("sources", ctx.assigns.sources)
    |> Map.put("layers", ctx.assigns.layers)
    |> Map.put("ml_alias", ctx.assigns.ml_alias)
    |> Map.put("variables", ctx.assigns.source_variables)
  end

  @impl true
  def to_source(attrs) do
    attrs
    |> to_quoted()
    |> Kino.SmartCell.quoted_to_string()
  end

  defp to_quoted(%{"sources" => sources, "layers" => layers} = attrs) do
    vars = attrs["variables"]

    attrs =
      Map.take(attrs, ["style", "center", "zoom", "ml_alias"])
      |> Map.new(fn {k, v} -> convert_field(k, v) end)

    root = %{
      field: nil,
      name: :new,
      module: attrs.ml_alias,
      args: build_arg_root(style: attrs.style, center: attrs.center, zoom: attrs.zoom)
    }

    sources =
      for source <- sources,
          source = Map.new(source, fn {k, v} -> convert_field(k, v) end),
          do: %{
            field: :source,
            name: :add_source,
            module: attrs.ml_alias,
            args:
              build_arg_source(
                source.source_id,
                source.source_data,
                source.source_type,
                get_in(vars, [Access.filter(&(&1.variable == source.source_data)), :type])
              )
          }

    layers =
      for layer <- layers,
          layer = Map.new(layer, fn {k, v} -> convert_field(k, v) end),
          do: %{
            field: :layer,
            name: :add_layer,
            module: attrs.ml_alias,
            args:
              build_arg_layer(
                layer.layer_id,
                layer.layer_source,
                layer.layer_type,
                {layer.layer_color, layer.layer_radius, layer.layer_opacity}
              )
          }

    nodes = sources ++ layers

    root = build_root(root)
    Enum.reduce(nodes, root, &apply_node/2)
  end

  defp build_root(root) do
    quote do
      unquote(root.module).unquote(root.name)(unquote_splicing(root.args))
    end
  end

  defp apply_node(%{args: nil}, acc), do: acc

  defp apply_node(%{field: _field, name: function, module: module, args: args}, acc) do
    quote do
      unquote(acc) |> unquote(module).unquote(function)(unquote_splicing(args))
    end
  end

  defp build_arg_root(opts) do
    opts
    |> Enum.filter(&elem(&1, 1))
    |> case do
      [] -> []
      opts -> [opts]
    end
  end

  defp build_arg_source(nil, _, _, _), do: nil
  defp build_arg_source(_, nil, _, _), do: nil

  defp build_arg_source(id, data, "variable", ["geo"]),
    do: [id, Macro.var(String.to_atom(data), nil)]

  defp build_arg_source(id, data, "variable", _),
    do: [id, [type: :geojson, data: Macro.var(String.to_atom(data), nil)]]

  defp build_arg_source(id, data, "url", _), do: [id, [type: :geojson, data: data]]

  defp build_arg_layer(nil, _, _, _), do: nil
  defp build_arg_layer(_, nil, _, _), do: nil

  defp build_arg_layer(id, source, type, {color, radius, opacity}) do
    [[id: id, source: source, type: type, paint: build_arg_paint(type, {color, radius, opacity})]]
  end

  defp build_arg_paint(:heatmap, {_color, radius, opacity}) do
    [heatmap_radius: radius, heatmap_opacity: opacity]
  end

  defp build_arg_paint(type, {color, _radius, opacity}) do
    ["#{type}_color": color, "#{type}_opacity": opacity]
  end

  defp missing_dep() do
    unless Code.ensure_loaded?(MapLibre) do
      ~s/{:maplibre, "~> 0.1.0"}/
    end
  end

  defp empty_source() do
    [%{"source_id" => nil, "source_data" => nil, "source_type" => "url"}]
  end

  defp empty_layer() do
    [
      %{
        "layer_id" => nil,
        "layer_source" => nil,
        "layer_type" => "fill",
        "layer_color" => "black",
        "layer_opacity" => 1,
        "layer_radius" => 10
      }
    ]
  end

  defp is_geometry(%module{}) when module in @geometries, do: true
  defp is_geometry("http" <> url), do: url |> String.split(".") |> List.last() == "geojson"
  defp is_geometry(_), do: false
end