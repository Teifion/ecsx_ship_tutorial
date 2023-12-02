defmodule Ship.GeometryTest do
  use ExUnit.Case
  alias Ship.Geometry

  defp deg(v), do: round(Geometry.rad2deg(v))

  defp round(0, p), do: 0
  defp round(v, p), do: Float.round(v, p)

  test "shortest angle" do
    values = [
      # Already the equal
      {0, 0, :equal},
      {40, 40, :equal},
      # {0, 360, :equal},

      # Standard angles, both right of 0 degrees
      {20, 30, :right},
      {20, 10, :left},

      # Both left of 0 degrees
      {340, 350, :right},
      {340, 330, :left},

      # # Straddling 0 degrees
      {340, 20, :right},
      {20, 340, :left},
    ]

    for {a1, a2, expected} <- values do
      result = Geometry.shortest_angle(Geometry.deg2rad(a1), Geometry.deg2rad(a2))
      assert result == expected, message: "Error with #{a1} -> #{a2}, expected #{expected} but got #{result}"
    end
  end

  test "angle_distance" do
    values = [
      # Already equal
      {0, 0, 0},
      {40, 40, 0},

      # Standard angles, both right of 0 degrees
      {20, 30, 10},
      {20, 10, 10},

      # Both left of 0 degrees
      {340, 350, 10},
      {340, 330, 10},

      # # Straddling 0 degrees
      {340, 20, 40},
      # {20, 340, 40},
    ]

    for {a1, a2, expected} <- values do
      result = Geometry.angle_distance(Geometry.deg2rad(a1), Geometry.deg2rad(a2))
      |> round(4)

      expected = expected
      |> Geometry.deg2rad
      |> round(4)

      assert result == expected, message: "Error with #{a1} -> #{a2}, expected #{Geometry.deg2rad(expected)} but got #{result}"
    end
  end

  test "degrees and radians" do
    values = [
      {0, 0},
      {180, :math.pi},
      {360, :math.pi * 2},
      {45, :math.pi / 4},
      {90, :math.pi / 2},
    ]

    for {deg, rad} <- values do
      assert Geometry.deg2rad(deg) == rad
      assert Geometry.rad2deg(rad) == deg
    end
  end

  test "calculate_angle" do
    # 2D stuff
    values = [
      {{0, 0}, {4, -4}, Geometry.deg2rad(45)},
      {{0, 0}, {4, 4}, Geometry.deg2rad(135)},
      {{0, 0}, {-4, 4}, Geometry.deg2rad(225)},
      {{0, 0}, {-4, -4}, Geometry.deg2rad(315)},


      {{0, 0}, {0, 0}, 0},
      {{0, 0}, {0, -4}, 0},
      {{0, 0}, {4, 0}, Geometry.deg2rad(90)},
      {{0, 0}, {0, 4}, Geometry.deg2rad(180)},
      {{0, 0}, {-4, 0}, Geometry.deg2rad(270)},

      {{10, 0}, {103, 0}, Geometry.deg2rad(90)},
      {{10, -1}, {103, 0}, 1.58154},# Approx 91 degrees

    ]

    for {p1, p2, expected} <- values do
      result = Geometry.calculate_angle(p1, p2)
      assert round(result,2) == round(expected, 2), message: "Error with #{inspect p1} -> #{inspect p2}, expected #{inspect deg expected} but got #{inspect deg result}"
    end

    # 3D stuff
    values = [
      {{0, 0, 0}, {4, -4, 0}, {Geometry.deg2rad(45), 0}},
      {{0, 0, 0}, {4, 4, 0}, {Geometry.deg2rad(135), 0}},
      {{0, 0, 0}, {-4, 4, 0}, {Geometry.deg2rad(225), 0}},
      {{0, 0, 0}, {-4, -4, 0}, {Geometry.deg2rad(315), 0}},

      {{0, 0, 0}, {4, -4, 4}, {Geometry.deg2rad(45), 0.6154797086703873}},
      {{0, 0, 0}, {4, 4, 4}, {Geometry.deg2rad(135), 0.6154797086703873}},
      {{0, 0, 0}, {-4, 4, 4}, {Geometry.deg2rad(225), 0.6154797086703873}},
      {{0, 0, 0}, {-4, -4, 4}, {Geometry.deg2rad(315), 0.6154797086703873}}
    ]

    for {p1, p2, expected = {e1, e2}} <- values do
      result = {r1, r2} = Geometry.calculate_angle(p1, p2)
      assert result == expected, message: "Error with #{inspect p1} -> #{inspect p2}, expected #{inspect {deg(e1), deg(e2)}} but got #{inspect {deg(r1), deg(r2)}}"
    end
  end
end
