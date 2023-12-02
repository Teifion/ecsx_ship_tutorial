defmodule ShipWeb.GameLive do
  require ShipWeb.GameLive
  use ShipWeb, :live_view

  alias Ship.Components.HullPoints
  alias Ship.Components.XPosition
  alias Ship.Components.YPosition
  alias Ship.Components.PlayerSpawned
  alias Ship.Components.ImageFile
  alias Ship.Components.IsProjectile

  def mount(params, _session, socket) when is_connected?(socket) do
    socket = cond do
      socket.assigns.current_player ->
        player_id = socket.assigns.current_player.id

        ECSx.ClientEvents.add(player_id, :spawn_ship)
        send(self(), :first_load)

        socket
        |> assign(player_entity: player_id)
        |> assign(keys: MapSet.new())
        |> assign_loading_state()

      params["id"] ->
        # player_id = String.to_integer(params["id"])
        player_id = params["id"]

        ECSx.ClientEvents.add(player_id, :spawn_ship)
        send(self(), :first_load)

        socket
        |> assign(player_entity: player_id)
        |> assign(keys: MapSet.new())
        |> assign_loading_state()

      true ->
        # player_id = :rand.uniform(8_999_999_999_999) + 1_000_000_000_000
        player_id = ExULID.ULID.generate()

        redirect(socket, to: ~p"/game/#{player_id}")
    end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign_loading_state
    }
  end

  def handle_info(:load_player_info, socket) do
    # This will run every 50ms to keep the client assigns updated
    x = XPosition.get_one(socket.assigns.player_entity)
    y = YPosition.get_one(socket.assigns.player_entity)
    hp = HullPoints.get_one(socket.assigns.player_entity)

    {:noreply, assign(socket, x_coord: x, y_coord: y, current_hp: hp)}
  end

  def handle_info(:first_load, socket) do
    :ok = wait_for_spawn(socket.assigns.player_entity)

    socket =
      socket
      |> assign_player_ship()
      |> assign_other_ships()
      |> assign_projectiles()
      |> assign_offsets()
      |> assign(loading: false)

    :timer.send_interval(50, :refresh)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign_player_ship()
      |> assign_other_ships()
      |> assign_projectiles()
      |> assign_offsets()

    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    if MapSet.member?(socket.assigns.keys, key) do
      # Already holding this key - do nothing
      {:noreply, socket}
    else
      # We only want to add a client event if the key is defined by the `keydown/1` helper below
      maybe_add_client_event(socket.assigns.player_entity, key, &keydown/1)
      {:noreply, assign(socket, keys: MapSet.put(socket.assigns.keys, key))}
    end
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    # We don't have to worry about duplicate keyup events
    # But once again, we will only add client events for keys that actually do something
    maybe_add_client_event(socket.assigns.player_entity, key, &keyup/1)
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  defp maybe_add_client_event(player_entity, key, fun) do
    case fun.(key) do
      :noop -> :ok
      event -> ECSx.ClientEvents.add(player_entity, event)
    end
  end

  defp keydown(key) when key in ~w(w W ArrowUp), do: {:move, :north}
  defp keydown(key) when key in ~w(a A ArrowLeft), do: {:move, :west}
  # These twe are tweaked for my Colemak keyboard
  defp keydown(key) when key in ~w(r R ArrowDown), do: {:move, :south}
  defp keydown(key) when key in ~w(s S ArrowRight), do: {:move, :east}
  defp keydown(_key), do: :noop

  defp keyup(key) when key in ~w(w W ArrowUp), do: {:stop_move, :north}
  defp keyup(key) when key in ~w(a A ArrowLeft), do: {:stop_move, :west}
  # These twe are tweaked for my Colemak keyboard
  defp keyup(key) when key in ~w(r R ArrowDown), do: {:stop_move, :south}
  defp keyup(key) when key in ~w(s S ArrowRight), do: {:stop_move, :east}
  defp keyup(_key), do: :noop

  defp assign_loading_state(socket) do
    assign(socket,
      x_coord: nil,
      y_coord: nil,
      current_hp: nil,
      player_ship_image_file: nil,
      other_ships: [],
      x_offset: 0,
      y_offset: 0,
      loading: true,
      projectiles: [],
      game_world_size: 100,
      screen_height: 30,
      screen_width: 50
    )
  end

  defp wait_for_spawn(player_entity) do
    if PlayerSpawned.exists?(player_entity) do
      :ok
    else
      Process.sleep(10)
      wait_for_spawn(player_entity)
    end
  end

  # Our previous :load_player_info handler becomes a shared helper for the new handlers
  defp assign_player_ship(socket) do
    x = XPosition.get_one(socket.assigns.player_entity)
    y = YPosition.get_one(socket.assigns.player_entity)
    hp = HullPoints.get_one(socket.assigns.player_entity)
    image = ImageFile.get_one(socket.assigns.player_entity)

    assign(socket, x_coord: x, y_coord: y, current_hp: hp, player_ship_image_file: image)
  end

  defp assign_other_ships(socket) do
    other_ships =
      Enum.reject(all_ships(), fn {entity, _, _, _} -> entity == socket.assigns.player_entity end)

    assign(socket, other_ships: other_ships)
  end

  defp all_ships do
    for {ship, _hp} <- HullPoints.get_all() do
      x = XPosition.get_one(ship)
      y = YPosition.get_one(ship)
      image = ImageFile.get_one(ship)
      {ship, x, y, image}
    end
  end

    defp assign_projectiles(socket) do
    projectiles =
      for projectile <- IsProjectile.get_all() do
        x = XPosition.get_one(projectile)
        y = YPosition.get_one(projectile)
        image = ImageFile.get_one(projectile)
        {projectile, x, y, image}
      end

    assign(socket, projectiles: projectiles)
  end

  defp assign_offsets(socket) do
    # Note: the socket must already have updated player coordinates before assigning offsets!
    %{screen_width: screen_width, screen_height: screen_height} = socket.assigns
    %{x_coord: x, y_coord: y, game_world_size: game_world_size} = socket.assigns

    x_offset = calculate_offset(x, screen_width, game_world_size)
    y_offset = calculate_offset(y, screen_height, game_world_size)

    assign(socket, x_offset: x_offset, y_offset: y_offset)
  end

  defp calculate_offset(coord, screen_size, game_world_size) do
    case coord - div(screen_size, 2) do
      offset when offset < 0 -> 0
      offset when offset > game_world_size - screen_size -> game_world_size - screen_size
      offset -> offset
    end
  end
end
