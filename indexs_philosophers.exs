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
    think(name)
    get_forks(philosopher)
    IO.puts("Я #{name} закончил обед")
    Lunch.lunch_done()
  end

  defp get_forks(
         %Philosopher{name: name, left_fork: left_fork, right_fork: right_fork} = philosopher
       ) do
    if Lunch.get_fork(left_fork) and Lunch.get_fork(right_fork) do
      eat(name)
      Lunch.back_fork(left_fork)
      Lunch.back_fork(right_fork)
    else
      IO.puts("Мне #{name} не удалось взять вилки")
      Lunch.back_fork(left_fork)
      Lunch.back_fork(right_fork)
      think(name)
      get_forks(philosopher)
    end
  end

  defp eat(name) do
    IO.puts("Я #{name} кушаю")
    Process.sleep(:rand.uniform(5000))
  end

  defp think(name) do
    IO.puts("Я #{name} думаю")
    Process.sleep(:rand.uniform(5000))
  end
end

defmodule Lunch do
  @name :lunch

  def start(philosophers) do
    Process.register(self(), @name)
    n = length(philosophers)

    forks =
      Enum.reduce(0..(n - 1), %{}, fn idx, m ->
        Map.put(m, idx, true)
      end)

    philosophers
    |> Enum.with_index(fn name, idx ->
      Philosopher.start(Philosopher.new(name, rem(abs(idx - 1 + n), n), rem(abs(idx + n), n)))
    end)

    loop({forks, n})
  end

  defp loop({_, 0}), do: IO.puts("Все философы закончили обед")

  defp loop(state) do
    new_state =
      receive do
        message -> process_message(state, message)
      end

    loop(new_state)
  end

  defp process_message({forks, n} = state, {:get_fork, {pid, fork_id}}) do
    case Map.fetch(forks, fork_id) do
      {:ok, true} ->
        send(pid, true)
        {%{forks | fork_id => false}, n}

      {:ok, false} ->
        send(pid, false)
        state
    end
  end

  defp process_message({forks, n}, {:back_fork, fork_id}) do
    {%{forks | fork_id => true}, n}
  end

  defp process_message({forks, n}, :done) do
    {forks, n - 1}
  end

  def get_fork(fork_id) do
    send(@name, {:get_fork, {self(), fork_id}})

    receive do
      answer -> answer
    after
      3000 -> false
    end
  end

  def back_fork(fork_id) do
    send(@name, {:back_fork, fork_id})
  end

  def lunch_done() do
    send(@name, :done)
  end
end

Lunch.start(["Aristotle", "Plato", "Heidegger", "Hegel", "Kant"])
