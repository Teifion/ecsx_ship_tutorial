defmodule Ship.Manager do
  @moduledoc """
  ECSx manager.
  """
  use ECSx.Manager

  def setup do
    # Seed persistent components only for the first server start
    # (This will not be run on subsequent app restarts)
    :ok
  end

  def startup do
    # Load ephemeral components during first server start and again
    # on every subsequent app restart
    :ok
  end

  # Declare all valid Component types
  def components do
    [
      Ship.Components.DestroyedAt,
      Ship.Components.AttackCooldown,
      Ship.Components.AttackTarget,
      Ship.Components.SeekingTarget,
      Ship.Components.AttackSpeed,
      Ship.Components.YVelocity,
      Ship.Components.XVelocity,
      Ship.Components.YPosition,
      Ship.Components.XPosition,
      Ship.Components.AttackRange,
      Ship.Components.AttackDamage,
      Ship.Components.ArmorRating,
      Ship.Components.HullPoints
    ]
  end

  # Declare all Systems to run
  def systems do
    [
      Ship.Systems.Destruction,
      Ship.Systems.CooldownExpiration,
      Ship.Systems.Attacking,
      Ship.Systems.Targeting,
      Ship.Systems.Driver
    ]
  end
end
