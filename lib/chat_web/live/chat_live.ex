defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message

  def mount(_params, _session, socket) do
    changeset = Messages.change_message(%Message{})

    {:ok,
     socket
     |> stream(:messages, Messages.list_messages())
     |> assign(:form, to_form(changeset))}
  end

  def render(assigns) do
    IO.inspect(assigns.streams.messages, label: "messages")

    ~H"""
    <div id="messages-div" phx-update="stream">
      <p :for={{_dom_id, message} <- @streams.messages}>
        {message.content}
      </p>
    </div>

    <.form for={@form} phx-submit="save">
      <.input field={@form[:content]} /> <button type="submit">Send Message</button>
    </.form>
    """
  end

  def handle_event("save", %{"message" => message_params}, socket) do
    case Messages.create_message(message_params) do
      {:ok, message} ->
        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> put_flash(:info, "Message sent!")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
