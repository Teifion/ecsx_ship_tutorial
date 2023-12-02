defmodule GameEcs.Physics do
  @moduledoc """

  """

  @doc """

  """
  @spec apply_thrust({float, float}, float) :: {float, float, float}
  def apply_thrust(_, 0), do: {0, 0, 0}
  def apply_thrust(%{fxy: fxy, fyz: fyz}, thrust), do: apply_thrust({fxy, fyz}, thrust)
  def apply_thrust({fxy, fyz}, thrust) do
    # We calculate the 2D planes and multiply by vertical. If we are pointing
    # up then it doesn't matter if we're in theory pointing to the side too
    vx = :math.sin(fxy) * :math.cos(fyz)
    vy = :math.cos(fxy) * :math.cos(fyz)

    # Now we calculate the vz
    vz = :math.sin(fyz)

    # We flip the Y coordinate as for us incrementing Y takes us up
    {vx * thrust, -vy * thrust, vz * thrust}
  end
end
