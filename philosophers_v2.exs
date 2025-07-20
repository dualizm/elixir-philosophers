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
  defstruct name: "", left_fork: nil, right_fork: nil

  def new(name, left_fork, right_fork) do
    %Philosopher{name: name, left_fork: left_fork, right_fork: right_fork}
  end

  def start(%Philosopher{name: name} = philosopher) do
    IO.puts("Я #{name} сел за стол")
    spawn(fn -> have_lunch(philosopher) end)
  end

  defp have_lunch(%Philosopher{name: name} = philosopher) do
    IO.puts("Я #{name} думаю")
    think()
    get_forks(philosopher)
    IO.puts("Я #{name} закончил обед")
    send(:lunch, :done)
  end

  defp get_forks(
         %Philosopher{name: name, left_fork: left_fork, right_fork: right_fork} = philosopher
       ) do
    if Lunch.get_fork(left_fork) and Lunch.get_fork(right_fork) do
      IO.puts("Мне #{name} удалось взять вилки")
      eat(name)
      Lunch.back_fork(left_fork)
      Lunch.back_fork(right_fork)
    else
      IO.puts("Мне #{name} не удалось взять вилки")
      Lunch.back_fork(left_fork)
      Lunch.back_fork(right_fork)
      get_forks(philosopher)
    end
  end

  defp eat(name) do
    IO.puts("Я #{name} кушаю")
    Process.sleep(:rand.uniform(5000))
  end

  defp think() do
    Process.sleep(:rand.uniform(5000))
  end
end

defmodule Lunch do
  @philosophers_count 5

  def start() do
    Process.register(self(), :lunch)

    ["Aristotle", "Plato", "Heidegger", "Hegel", "Kant"]
    |> Enum.with_index(fn name, idx ->
      Philosopher.start(
        Philosopher.new(
          name,
          rem(abs(idx - 1 + @philosophers_count), @philosophers_count),
          rem(abs(idx + @philosophers_count), @philosophers_count)
        )
      )
    end)

    table = List.duplicate(true, @philosophers_count) |> List.to_tuple()

    lunch(table, @philosophers_count)
  end

  defp lunch(_, 0), do: IO.puts("Все философы закончили обед")

  defp lunch(table, n) do
    receive do
      {:get_fork, {pid, fork}} ->
        if elem(table, fork) do
          send(pid, true)
          lunch(put_elem(table, fork, false), n)
        else
          send(pid, false)
          lunch(table, n)
        end

      {:back_fork, fork} ->
        lunch(put_elem(table, fork, true), n)

      :done ->
        lunch(table, n - 1)
    end
  end

  def get_fork(fork) do
    send(:lunch, {:get_fork, {self(), fork}})

    receive do
      answer -> answer
    after
      3000 -> false
    end
  end

  def back_fork(fork) do
    send(:lunch, {:back_fork, fork})
  end
end

Lunch.start()
