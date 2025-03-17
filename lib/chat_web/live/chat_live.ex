defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message
  alias Chat.Rooms
  alias Chat.Rooms.Room
  alias Chat.UserRooms

  on_mount {ChatWeb.UserAuth, :ensure_is_member}

  def mount(params, _session, socket) do
    %{"room_id" => room_id} = params

    if connected?(socket) do
      Chat.Messages.subscribe(room_id)
      Chat.Rooms.subscribe()
    end

    message_changeset = Messages.change_message(%Message{})

    room_changeset = Rooms.change_room(%Room{})

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms_of_user(socket.assigns.current_user.id))
     |> stream(:messages, Messages.get_messages_from_room(room_id))
     |> assign(:current_room, Rooms.get_room!(room_id))
     |> assign(:message_form, to_form(message_changeset))
     |> assign(:room_form, to_form(room_changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex">
      <div class="w-64 bg-[#f2f3f5] min-h-screen flex flex-col justify-between">
        <div id="rooms" class="text-lg divide-y-2 text-[#69737F]" phx-update="stream">
          <div class="flex justify-between items-center p-1 px-2 text-2xl">
            <h1>Rooms</h1>
            
            <div class="relative group">
              <button class="text-5xl pb-1 text-[#8d8f92] hover:text-[#a9abafcb] group">
                +
                <div class="absolute left-1/2 transform
                       -translate-x-1/2  w-max px-2 py-1
                       text-sm text-white bg-gray-700 rounded
                       shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none">
                  Add new group
                </div>
              </button>
            </div>
          </div>
          
          <div class="flex flex-col gap-1 p-2">
            <div :for={{dom_id, room} <- @streams.rooms} class="w-full">
              <.link
                class={[
                  "hover:bg-[#e5e8ec] w-full block p-2 rounded hover:text-black",
                  room.id == @current_room.id &&
                    "pointer-events-none bg-[#D4D7DC] text-black"
                ]}
                navigate={~p"/chat/#{room.id}"}
                id={dom_id}
              >
                # {room.name}
              </.link>
            </div>
          </div>
        </div>
        
        <.form for={@room_form} phx-submit="save_room" phx-change="validate_room">
          <.input field={@room_form[:name]} /> <button type="submit">Create Room</button>
        </.form>
      </div>
      
      <div>
        <h1 class="text-4xl">
          ROOM: <span class="text-blue-400">{@current_room.name}</span>
        </h1>
        
        <div id="messages-div" phx-update="stream">
          <p :for={{dom_id, message} <- @streams.messages} id={dom_id}>
            {message.user.email}: {message.content}
          </p>
        </div>
        
        <.form for={@message_form} phx-submit="save_message" phx-change="validate_message">
          <.input field={@message_form[:content]} /> <button type="submit">Send Message</button>
        </.form>
      </div>
    </div>
    """
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
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

  def handle_event("validate_message", %{"message" => message_params}, socket) do
    changeset = Messages.change_message(%Message{}, message_params)

    {:noreply,
     socket
     |> assign(:message_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_message", %{"message" => message_params}, socket) do
    message_params =
      message_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("room_id", socket.assigns.current_room.id)

    case Messages.create_message(message_params) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(:message_form, to_form(Messages.change_message(%Message{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, message_form: to_form(changeset))}
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
