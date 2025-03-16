defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message
  alias Chat.Rooms

  def mount(params, _session, socket) do
    %{"room_id" => room_id} = params
    if connected?(socket), do: Chat.Messages.subscribe(room_id)
    changeset = Messages.change_message(%Message{})

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms())
     |> stream(:messages, Messages.get_messages_from_room(room_id))
     |> assign(:room, Rooms.get_room!(room_id))
     |> assign(:message_form, to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex">
      <div>
        <div class="w-64 min-h-screen">
          <h1 class="text-center bg-red-200 text-3xl font-bold">Rooms</h1>
          
          <div id="rooms" phx-update="stream">
            <div :for={{dom_id, room} <- @streams.rooms}>
              <.link
                class={[
                  "hover:bg-blue-600 mr-2",
                  room.id == @room.id && "bg-red-200"
                ]}
                navigate={~p"/chat/#{room.id}"}
                id={dom_id}
              >
                {room.name}
              </.link>
            </div>
          </div>
        </div>
      </div>
      
      <div>
        <h1 class="text-4xl">
          ROOM: <span class="text-blue-400">{@room.name}</span>
        </h1>
        
        <div id="messages-div" phx-update="stream">
          <p :for={{dom_id, message} <- @streams.messages} id={dom_id}>
            {message.user.email}: {message.content}
          </p>
        </div>
        
        <.form for={@message_form} phx-submit="save" phx-change="validate">
          <.input field={@message_form[:content]} /> <button type="submit">Send Message</button>
        </.form>
      </div>
    </div>
    """
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_event("validate", %{"message" => message_params}, socket) do
    changeset = Messages.change_message(%Message{}, message_params)

    {:noreply,
     socket
     |> assign(:message_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"message" => message_params}, socket) do
    message_params =
      message_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("room_id", socket.assigns.room.id)

    case Messages.create_message(message_params) do
      {:ok, message} ->
        {:noreply,
         socket
         |> assign(:message_form, to_form(Messages.change_message(%Message{})))
         |> stream_insert(:messages, message)}

      {:error, changeset} ->
        {:noreply, assign(socket, message_form: to_form(changeset))}
    end
  end
end
