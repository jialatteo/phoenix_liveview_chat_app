defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message
  alias Chat.Rooms
  alias Chat.Rooms.Room

  def mount(params, _session, socket) do
    if connected?(socket), do: Chat.Messages.subscribe()
    changeset = Messages.change_message(%Message{})
    %{"room_id" => room_id} = params

    {:ok,
     socket
     |> stream(:messages, Messages.get_messages_from_room(room_id))
     |> assign(:room, Rooms.get_room!(room_id))
     |> assign(:form, to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-4xl">
      ROOM: <span class="text-blue-400">{@room.name}</span>
    </h1>

    <div id="messages-div" phx-update="stream">
      <p :for={{dom_id, message} <- @streams.messages} id={dom_id}>
        {message.user.email}: {message.content}
      </p>
    </div>

    <.form for={@form} phx-submit="save" phx-change="validate">
      <.input field={@form[:content]} /> <button type="submit">Send Message</button>
    </.form>
    """
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_event("validate", %{"message" => message_params}, socket) do
    changeset = Messages.change_message(%Message{}, message_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"message" => message_params}, socket) do
    message_params =
      message_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("room_id", socket.assigns.room.id)

    case Messages.create_message(message_params) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(:form, to_form(Messages.change_message(%Message{})))
         |> put_flash(:info, "Message sent!")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
