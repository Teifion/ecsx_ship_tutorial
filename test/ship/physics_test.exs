defmodule Ship.PhysicsTest do
  use ExUnit.Case
  alias Ship.Physics
  import Ship.Geometry, only: [deg2rad: 1]

  # defp deg(v), do: round(rad2deg(v))

  defp round({a, b}, p), do: {round(a, p), round(b, p)}
  defp round({a, b, c}, p), do: {round(a, p), round(b, p), round(c, p)}
  defp round(0, p), do: 0
  defp round(v, p), do: Float.round(v, p)

  test "apply thrust" do
    values = [
      # Moving in 2D space (so fyz is level)
      {{0,    0},  {0, -1, 0}},
      {{90,   0},  {1, 0, 0}},
      {{180,  0},  {0, 1, 0}},
      {{270,  0},  {-1, 0, 0}},

      # Moving purely in fyz space, we are pointing directly upwards
      {{0,    270},  {0, 0, -1}},
      {{90,   270},  {0, 0, -1}},
      {{180,  270},  {0, 0, -1}},
      {{270,  270},  {0, 0, -1}},

      # Moving purely in fyz space, we are pointing directly downwards
      {{0,    90},  {0, 0, 1}},
      {{90,   90},  {0, 0, 1}},
      {{180,  90},  {0, 0, 1}},
      {{270,  90},  {0, 0, 1}},
    ]

    for {facing, expected} <- values do
      result = deg2rad(facing)
      |> Physics.apply_thrust(1)
      |> round(4)

      assert result == expected, message: "Error with #{inspect facing}, expected #{inspect expected} but got #{inspect result}"
    end
  end
end
