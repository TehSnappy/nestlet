defmodule NestletWeb.AuthTokenFormComponent do
  use NestletWeb, :live_component
  alias Nestlet.Nest.State

  @auth_endpoint "https://nestservices.google.com/partnerconnections"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        id="section-form"
        title="Authenticate with Google"
        for={%{}}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="set_auth_token"
      >
        <.input
          field={{f, :auth_token}}
          type="text"
          label="Authorization Code"
          name="auth_token"
          value=""
        />
        <.label>
          <%= draw_validated_text(assigns) %>
        </.label>

        <:actions>
          <.button class="bg-indigo-500">
            <.link target="_blank" class="bg-indigo-500" href={start_authorization_process() |> raw()}>
              Fetch Auth From Google
            </.link>
          </.button>
          <.button class={["bg-sky-500"] ++ has_validated_text?(assigns)} phx-disable-with="Saving...">
            Save Auth Code
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event(
        "set_auth_token",
        _params,
        %{assigns: %{validated_auth_code: validated_auth_code}} = socket
      ) do
    State.set_state(auth_code: validated_auth_code)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"auth_token" => auth_code}, socket) do
    extracted_code =
      case Regex.scan(~r/http.*?code=(.*)&.*/, auth_code) do
        nil ->
          auth_code

        [] ->
          auth_code

        [results] ->
          Enum.at(results, 1)
      end

    {:noreply, assign(socket, :validated_auth_code, extracted_code)}
  end

  def start_authorization_process() do
    %{project_id: project_id, oauth_client_id: oauth_client_id} = get_config()

    ~s(#{@auth_endpoint}/#{project_id}/auth?redirect_uri=https://www.google.com&access_type=offline&prompt=consent&client_id=#{oauth_client_id}&response_type=code&scope=https://www.googleapis.com/auth/sdm.service)
  end

  def has_validated_text?(assigns) do
    if Map.has_key?(assigns, :validated_auth_code), do: [:disabled], else: []
  end

  defp draw_validated_text(%{validated_auth_code: _validated_text} = assigns) do
    ~H"""
    <div class="text-center text-xs">
      <%= @validated_auth_code %>
    </div>
    """
  end

  defp draw_validated_text(assigns) do
    ~H"""
    <div class="italic text-center text-sm">
      Paste the google referral URL above. The auth token will appear here if successful.
    </div>
    """
  end

  defp get_config do
    Application.get_env(:nestlet, State)
    |> Enum.into(%{})
  end
end
