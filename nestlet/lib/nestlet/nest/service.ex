defmodule Nestlet.Nest.Service do
  defstruct beat_interval: 10_000

  require Logger

  alias Nestlet.Nest.State
  alias Nestlet.Nest.Thermostat
  alias HTTPoison.Response

  @endpoint "https://smartdevicemanagement.googleapis.com/v1"
  @oauth_uri "https://www.googleapis.com/oauth2/v4/token"

  def fetch_and_update_nest_state(nest_state) do
    with {:ok, state} <- get_or_fetch_access_token(nest_state),
         {:ok, uri} <- device_fetch_url(state),
         {:ok, data} <- get_request_json(uri) do
      case data do
        %{"devices" => device_data} ->
          devices = Enum.map(device_data, &Thermostat.build/1)
          State.set_state(device_list: devices, is_rate_limited?: false)

        %{"error" => %{"code" => 429}} ->
          Logger.warning("received a 429 error - rate limited")
          State.set_state(is_rate_limited?: true)

        %{"error" => _error_msg} ->
          State.reset_authorization()
      end
    else
      _ ->
        State.reset_authorization()
    end
  end

  def set_thermostat_target_temp(nest_state, thermostat, new_temp) do
    set_temp_point(nest_state, thermostat, new_temp)
  end

  defp get_or_fetch_access_token(state) do
    case state do
      %{project_id: nil} = state ->
        {:error, state}

      %{access_token: nil} = state ->
        case fetch_access_token(state) do
          %{access_token: nil} = state ->
            {:error, state}

          state ->
            {:ok, state}
        end

      state ->
        {:ok, state}
    end
  end

  defp fetch_access_token(%{refresh_token: nil, auth_code: auth_code} = state)
       when not is_nil(auth_code) do
    state
    |> fetch_tokens_with_auth_code_url()
    |> post_request_json([])
    |> case do
      {:ok, %{"access_token" => access_token, "refresh_token" => refresh_token}} ->
        State.set_state(access_token: access_token, refresh_token: refresh_token)

      {:ok, %{"error" => error}} ->
        Logger.error("error getting access token #{inspect(error)}")
        State.reset_authorization()

      {:error, error} ->
        Logger.error("error retrieving access token #{inspect(error)}")
        state
    end
  end

  defp fetch_access_token(state) do
    state
    |> refresh_access_token_url()
    |> post_request_json([])
    |> case do
      {:ok, %{"access_token" => access_token}} ->
        State.set_state(access_token: access_token)

      {:ok, %{"error" => error}} ->
        Logger.error("error getting access token with refresh #{inspect(error)}")
        State.reset_authorization()

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        state

      reason ->
        Logger.error("error getting access token with refresh2 #{inspect(reason)}")
        State.set_state(refresh_token: nil)
    end
  end

  defp get_request_json(uri) do
    uri
    |> HTTPoison.get([])
    |> return_json_data
  end

  defp post_request_json(uri, body) do
    uri
    |> HTTPoison.post(body)
    |> return_json_data
  end

  defp set_temp_point(nest_state, %Thermostat{display_id: display_id} = thermostat, new_temp) do
    %{project_id: project_id} = get_config()

    case get_or_fetch_access_token(nest_state) do
      {:ok, %{access_token: access_token}} ->
        request_body = Thermostat.set_temp_body(thermostat, new_temp)
        url = post_device_update_url(project_id, display_id, access_token)
        ans = post_request_json(url, request_body)
        Logger.info("the result of the post is #{inspect(ans)}")
        :ok

      _ ->
        :error
    end
  end

  defp return_json_data({:ok, %Response{body: body}}) do
    case Jason.decode(body) do
      {:ok, data} ->
        {:ok, data}

      error ->
        error
    end
  end

  defp return_json_data(error), do: error

  defp post_device_update_url(project_id, device_id, access_token) do
    ~s(#{@endpoint}/enterprises/#{project_id}/devices/#{device_id}:executeCommand?access_token=#{access_token})
  end

  defp device_fetch_url(%State{project_id: project_id, access_token: access_token}) do
    {:ok, ~s(#{@endpoint}/enterprises/#{project_id}/devices?access_token=#{access_token})}
  end

  defp fetch_tokens_with_auth_code_url(%{auth_code: auth_code}) do
    %{oauth_client_id: oauth_client_id, oauth_client_secret: oauth_client_secret} = get_config()

    ~s(#{@oauth_uri}?client_id=#{oauth_client_id}&client_secret=#{oauth_client_secret}&code=#{auth_code}&grant_type=authorization_code&redirect_uri=https://www.google.com)
  end

  defp refresh_access_token_url(%State{
         refresh_token: refresh_token
       }) do
    %{oauth_client_id: oauth_client_id, oauth_client_secret: oauth_client_secret} = get_config()

    ~s(#{@oauth_uri}?client_id=#{oauth_client_id}&client_secret=#{oauth_client_secret}&refresh_token=#{refresh_token}&grant_type=refresh_token)
  end

  defp get_config do
    Application.get_env(:nestlet, Nestlet.Nest.State)
    |> Enum.into(%{})
  end
end
