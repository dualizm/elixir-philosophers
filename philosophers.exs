# Пять безмолвных философов сидят вокруг круглого стола, перед каждым философом стоит тарелка спагетти.
# На столе между каждой парой ближайших философов лежит по одной вилке.
# Каждый философ может либо есть, либо размышлять.
# Приём пищи не ограничен количеством оставшихся спагетти — подразумевается бесконечный запас.
# Тем не менее, философ может есть только тогда, когда держит две вилки — взятую справа и слева
# Каждый философ может взять ближайшую вилку (если она доступна) или положить — если он уже держит её.
# Взятие каждой вилки и возвращение её на стол являются раздельными действиями, которые должны выполняться одно за другим.
# Вопрос задачи заключается в том, чтобы разработать модель поведения (параллельный алгоритм),
# при котором ни один из философов не будет голодать, то есть будет вечно чередовать приём пищи и размышления.

defmodule Philosopher do
  defstruct id: 0, name: ""

  def new(id, name), do: %Philosopher{id: id, name: name}

  def start(%Philosopher{id: id, name: name} = philosopher) do
    IO.puts("Я #{name} сел за стол под номер #{id}")
    spawn(fn -> have_lunch(philosopher) end)
  end

  defp have_lunch(%Philosopher{id: id, name: name} = philosopher) do
    IO.puts("Я #{name} думаю")
    think()
    eat(philosopher)
    have_lunch(philosopher)
  end

  defp eat(%Philosopher{id: id, name: name} = philosopher) do
    send(:lunch, {:get_forks, {self(), id}})

    receive do
      :available ->
        IO.puts("Я #{name} кушаю")
        Process.sleep(:rand.uniform(5000))
        send(:lunch, {:back_forks, {self(), id}})

      :busy ->
        eat(philosopher)
    end
  end

  defp think() do
    Process.sleep(:rand.uniform(5000))
  end
end

defmodule Lunch do
  def start() do
    Process.register(self(), :lunch)

    ["Aristotle", "Plato", "Heidegger", "Hegel", "Kant"]
    |> Enum.with_index(fn name, idx ->
      Philosopher.start(Philosopher.new(idx, name))
    end)

    table = {true, true, true, true, true}

    lunch(table)
  end

  defp lunch(table) do
    receive do
      {:get_forks, {philosopher_pid, id}} ->
        fork_index_first = rem(abs(id - 1 + 5), 5)
        fork_index_second = rem(abs(id + 5), 5)

        if elem(table, fork_index_first) and elem(table, fork_index_second) do
          send(philosopher_pid, :available)
          lunch(put_elem(table, id, false))
        else
          send(philosopher_pid, :busy)
          lunch(table)
        end

      {:back_forks, {_philosopher_pid, id}} ->
        fork_index_first = rem(abs(id - 1 + 5), 5)
        fork_index_second = rem(abs(id + 5), 5)

        new_table =
          table
          |> put_elem(fork_index_first, true)
          |> put_elem(fork_index_second, true)

        lunch(new_table)
    end
  end
end

Lunch.start()
