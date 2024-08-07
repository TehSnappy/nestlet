defmodule Nestlet.Nest.Thermostat do
  defstruct display_id: nil,
            display_name: nil,
            connectivity: nil,
            eco_status: nil,
            current_mode: nil,
            ambient_temp: nil,
            temperature_set_point: nil,
            status: nil

  def build(json) do
    %{
      "name" => display_id,
      "parentRelations" => [
        %{
          "displayName" => display_name
        }
      ],
      "traits" => %{
        "sdm.devices.traits.ThermostatHvac" => %{
          "status" => status
        },
        "sdm.devices.traits.Connectivity" => %{
          "status" => connectivity
        },
        "sdm.devices.traits.ThermostatEco" => %{
          "mode" => eco_status
        },
        "sdm.devices.traits.ThermostatMode" => %{
          "availableModes" => _available_modes,
          "mode" => current_mode
        },
        "sdm.devices.traits.Temperature" => %{
          "ambientTemperatureCelsius" => ambient_temp_celsius
        },
        "sdm.devices.traits.ThermostatTemperatureSetpoint" => set_point
      }
    } = json

    temperature_set_point =
      case set_point do
        %{"heatCelsius" => temperature_set_point} ->
          temperature_set_point

        %{"coolCelsius" => temperature_set_point} ->
          temperature_set_point

        _ ->
          0
      end

    %__MODULE__{
      display_id: display_id |> String.split("/") |> List.last(),
      display_name: display_name,
      current_mode: current_mode,
      connectivity: connectivity,
      eco_status: eco_status,
      status: status,
      ambient_temp: ambient_temp_celsius |> celsius_to_farenheit(),
      temperature_set_point: temperature_set_point |> celsius_to_farenheit()
    }
  end

  def set_temp_body(%__MODULE__{current_mode: "HEAT"}, new_temp) do
    new_temp = farenheit_to_celsius(new_temp)

    ans = """
    {
      "command" : "sdm.devices.commands.ThermostatTemperatureSetpoint.SetHeat",
      "params" : {
        "heatCelsius" : #{new_temp}
      }
    }
    """

    ans
  end

  def set_temp_body(%__MODULE__{current_mode: "COOL"}, new_temp) do
    new_temp = farenheit_to_celsius(new_temp)

    ans = """
    {
      "command" : "sdm.devices.commands.ThermostatTemperatureSetpoint.SetCool",
      "params" : {
        "coolCelsius" : #{new_temp}
      }
    }
    """

    ans
  end

  defp farenheit_to_celsius(f), do: Kernel.trunc((f - 32) * (5 / 9))

  defp celsius_to_farenheit(c), do: Kernel.trunc((c * (9 / 5) + 32) * 10) / 10
end
