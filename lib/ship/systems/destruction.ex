defmodule Ship.Systems.Destruction do
  @moduledoc """
  Documentation for Destruction system.
  """
  @behaviour ECSx.System

  alias Ship.Components.ArmorRating
  alias Ship.Components.AttackCooldown
  alias Ship.Components.AttackDamage
  alias Ship.Components.AttackRange
  alias Ship.Components.AttackSpeed
  alias Ship.Components.AttackTarget
  alias Ship.Components.DestroyedAt
  alias Ship.Components.HullPoints
  alias Ship.Components.SeekingTarget
  alias Ship.Components.XPosition
  alias Ship.Components.XVelocity
  alias Ship.Components.YPosition
  alias Ship.Components.YVelocity

  @impl ECSx.System
  def run do
    ships = HullPoints.get_all()

    Enum.each(ships, fn {entity, hp} ->
      if hp <= 0, do: destroy(entity)
    end)
  end

  defp destroy(ship) do
    ArmorRating.remove(ship)
    AttackCooldown.remove(ship)
    AttackDamage.remove(ship)
    AttackRange.remove(ship)
    AttackSpeed.remove(ship)
    AttackTarget.remove(ship)
    HullPoints.remove(ship)
    SeekingTarget.remove(ship)
    XPosition.remove(ship)
    XVelocity.remove(ship)
    YPosition.remove(ship)
    YVelocity.remove(ship)

    # when a ship is destroyed, other ships should stop targeting it
    untarget(ship)

    DestroyedAt.add(ship, DateTime.utc_now())
  end

  defp untarget(target) do
    for ship <- AttackTarget.search(target) do
      AttackTarget.remove(ship)
      SeekingTarget.add(ship)
    end
  end
end
