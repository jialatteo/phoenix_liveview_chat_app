defmodule ChatWeb.HomeLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message
  alias Chat.Rooms
  alias Chat.Rooms.Room
  alias Chat.UserRooms

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Chat.Rooms.subscribe()
    end

    room_changeset = Rooms.change_room(%Room{})

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms_of_user(socket.assigns.current_user.id))
     |> assign(:room_form, to_form(room_changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex">
      <div class="w-64 ">
        <h1 class="text-center bg-red-200 text-3xl font-bold">Rooms</h1>
        
        <div class="flex min-h-screen flex-col gap-8">
          <div id="rooms" phx-update="stream">
            <div :for={{dom_id, room} <- @streams.rooms}>
              <.link class="hover:bg-red-50 mr-2" navigate={~p"/chat/#{room.id}"} id={dom_id}>
                {room.name}
              </.link>
            </div>
          </div>
          
          <.form for={@room_form} phx-submit="save_room" phx-change="validate_room">
            <.input field={@room_form[:name]} /> <button type="submit">Create Room</button>
          </.form>
        </div>
      </div>
      
      <div>
        Select a room on the left to view its messages or create a new room.
      </div>
    </div>
    """
  end

  def handle_info({:room_created, room}, socket) do
    if UserRooms.user_room_exist(%{
         "user_id" => socket.assigns.current_user.id,
         "room_id" => room.id
       }) do
      {:noreply, stream_insert(socket, :rooms, room)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset = Rooms.change_room(%Room{}, room_params)

    {:noreply,
     socket
     |> assign(:room_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_room", %{"room" => room_params}, socket) do
    room_params = Map.put(room_params, "user_id", socket.assigns.current_user.id)

    case Rooms.create_room(room_params) do
      {:ok, room} ->
        {:noreply,
         socket
         |> assign(:room_form, to_form(Rooms.change_room(%Room{})))
         |> put_flash(:info, "Room #{room.name} created")}

      {:error, changeset} ->
        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end
end
