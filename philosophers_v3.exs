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
  def start(), do: spawn(fn -> available() end)

  defp available() do
    receive do
      {:pick_up, pid} ->
        send(pid, :ok)
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
      :ok -> :ok
    after
      1000 -> :busy
    end
  end

  def put_down(fork) do
    send(fork, :put_down)
  end
end

defmodule Philosopher do
  defstruct id: 0, name: "", left_fork: nil, right_fork: nil

  def new(id, name, left_fork, right_fork) do
    %Philosopher{id: id, name: name, left_fork: left_fork, right_fork: right_fork}
  end

  def start(%Philosopher{id: id, name: name} = philosopher) do
    IO.puts("Я #{name} сел за стол под номер #{id}")
    spawn(fn -> have_lunch(philosopher) end)
  end

  defp have_lunch(%Philosopher{id: id, name: name} = philosopher) do
    IO.puts("Я #{name} думаю")
    think()
    get_forks(philosopher)
    IO.puts("Я #{name} закончил обед")
    send(:lunch, :done)
  end

  defp get_forks(
         %Philosopher{name: name, left_fork: left_fork, right_fork: right_fork} = philosopher
       ) do
    case {Fork.pick_up(left_fork), Fork.pick_up(right_fork)} do
      {:ok, :ok} ->
        IO.puts("Мне #{name} удалось взять вилки")
        eat(name)
        Fork.put_down(left_fork)
        Fork.put_down(right_fork)

      _ ->
        IO.puts("Мне #{name} не удалось взять вилки")
        Fork.put_down(left_fork)
        Fork.put_down(right_fork)
        think()
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
    forks = for _ <- 1..@philosophers_count, do: Fork.start()

    philosophers =
      ["Aristotle", "Plato", "Heidegger", "Hegel", "Kant"]
      |> Stream.zip(
        for i <- 1..@philosophers_count,
            do:
              {Enum.at(forks, rem(i - 1, @philosophers_count)),
               Enum.at(forks, rem(i, @philosophers_count))}
      )
      |> Enum.with_index(fn {name, {left_fork, right_fork}}, idx ->
        Philosopher.start(Philosopher.new(idx, name, left_fork, right_fork))
      end)

    wait_for_competition(@philosophers_count)
  end

  defp wait_for_competition(0), do: IO.puts("Все философы закончили обед")

  defp wait_for_competition(n) do
    receive do
      :done -> wait_for_competition(n - 1)
    end
  end
end

Lunch.start()
