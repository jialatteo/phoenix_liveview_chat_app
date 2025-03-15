defmodule ChatWeb.RoomCreateLive do
  use ChatWeb, :live_view
  alias Chat.Rooms.Room
  alias Chat.Rooms

  def mount(_params, _session, socket) do
    changeset = Rooms.change_room(%Room{})

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms())
     |> assign(:form, to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div id="rooms" phx-update="stream">
      <.link
        :for={{dom_id, room} <- @streams.rooms}
        class="bg-red-200 hover:bg-red-300 rounded mr-2"
        href={~p"/chat/#{room.id}"}
        id={dom_id}
      >
        {room.name}
      </.link>
    </div>

    <.form for={@form} phx-submit="save" phx-change="validate">
      <.input field={@form[:name]} /> <button type="submit">Create Room</button>
    </.form>
    """
  end

  def handle_event("validate", %{"room" => room_params}, socket) do
    changeset = Rooms.change_room(%Room{}, room_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"room" => room_params}, socket) do
    room_params = Map.put(room_params, "user_id", socket.assigns.current_user.id)

    case Rooms.create_room(room_params) do
      {:ok, room} ->
        IO.puts("okay!")

        {:noreply,
         socket
         |> assign(:form, to_form(Rooms.change_room(%Room{})))
         |> put_flash(:info, "Room #{room.name} created")}

      {:error, changeset} ->
        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end
end
