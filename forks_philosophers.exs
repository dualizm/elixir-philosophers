# Пять безмолвных философов сидят вокруг круглого стола, перед каждым философом стоит тарелка спагетти.
# На столе между каждой парой ближайших философов лежит по одной вилке.
# Каждый философ может либо есть, либо размышлять.
# Приём пищи не ограничен количеством оставшихся спагетти — подразумевается бесконечный запас.
# Тем не менее, философ может есть только тогда, когда держит две вилки — взятую справа и слева
# Каждый философ может взять ближайшую вилку (если она доступна) или положить — если он уже держит её.
# Взятие каждой вилки и возвращение её на стол являются раздельными действиями, которые должны выполняться одно за другим.
# Вопрос задачи заключается в том, чтобы разработать модель поведения (параллельный алгоритм),
# при котором ни один из философов не будет голодать, то есть будет вечно чередовать приём пищи и размышления.

defmodule Fork do
  def start(), do: spawn(&available/0)

  defp available() do
    receive do
      {:pick_up, pid} ->
        send(pid, true)
        gone()

      _ ->
        available()
    end
  end

  defp gone() do
    receive do
      :put_down ->
        available()

      _ ->
        gone()
    end
  end

  def pick_up(fork) do
    send(fork, {:pick_up, self()})

    receive do
      true -> true
    after
      1000 -> false
    end
  end

  def put_down(fork) do
    send(fork, :put_down)
  end
end

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
    if Fork.pick_up(left_fork) and Fork.pick_up(right_fork) do
      eat(name)
      Fork.put_down(left_fork)
      Fork.put_down(right_fork)
    else
      IO.puts("Мне #{name} не удалось взять вилки")
      Fork.put_down(left_fork)
      Fork.put_down(right_fork)
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
    forks = for _ <- 1..n, do: Fork.start()

    Enum.with_index(philosophers, fn name, i ->
      left_fork = Enum.at(forks, rem(i - 1, n))
      right_fork = Enum.at(forks, rem(i, n))
      Philosopher.start(Philosopher.new(name, left_fork, right_fork))
    end)

    wait_for_competition(n)
  end

  defp wait_for_competition(0), do: IO.puts("Все философы закончили обед")

  defp wait_for_competition(n) do
    receive do
      :done -> wait_for_competition(n - 1)
    end
  end

  def lunch_done() do
    send(@name, :done)
  end
end

Lunch.start(["Aristotle", "Plato", "Heidegger", "Hegel", "Kant"])
