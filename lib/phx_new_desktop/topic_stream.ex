defmodule PhxNewDesktop.TopicStream do
  @moduledoc false
  defstruct [:topic]

  defimpl Collectable do
    def into(%{topic: topic}) do
      fun = fn
        acc, {:cont, x} ->
          broadcast(topic, x)
          acc

        acc, :done ->
          broadcast(topic, :done)
          acc

        acc, :halt ->
          broadcast(topic, :halt)
          acc
      end

      {:ok, fun}
    end

    defp broadcast(topic, msg) do
      Phoenix.PubSub.broadcast(PhxNewDesktop.PubSub, topic, {:io_stream, msg})
    end
  end
end
