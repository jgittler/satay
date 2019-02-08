defmodule Approaches do
  @list [
    %{"name" => "jon", "id" => 1, "age" => 20},
    %{"name" => "jane", "id" => 2, "age" => 25},
    %{"name" => "joe", "id" => 3, "age" => 30}
  ]
  @id 100
  @mappings %{"jon" => %{"age" => 10}, "jane" => %{"age" => 20}, "joe" => %{"age" => 40}}
  @relations %{"1" => 10, "2" => 11, "3" => 12}

  defmodule Helpers do
    def transform_item(item, mappings) do
      Map.put(item, "age", get_in(mappings, [item["name"], "age"]))
    end

    def relation_id(item, relations) do
      Map.get(relations, Integer.to_string(item["id"]))
    end
  end

  defmodule Compose do
    def transform_item(mappings) do
      fn item ->
        Map.put(item, "age", get_in(mappings, [item["name"], "age"]))
      end
    end

    def relation_id(relations) do
      fn item ->
        {Map.get(relations, Integer.to_string(item["id"])), item}
      end
    end

    def call(list, id, mappings, relations) do
      Enum.each(
        list,
        compose([
          finalize_item(id),
          relation_id(relations),
          transform_item(mappings)
        ])
      )
    end

    defp finalize_item(id) do
      fn {relation_id, item} ->
        IO.inspect({{:from, id}, {:to, relation_id}, item})
      end
    end

    defp compose([h | t]) when length(t) > 1 do
      compose(curry(h), compose(t))
    end

    defp compose([h | t]) when length(t) == 1 do
      compose(h, List.first(t))
    end

    defp compose(func1, func2) when is_function(func2) do
      fn arg -> compose(curry(func1), curry(func2).(arg)) end
    end

    defp compose(func, arg) do
      func.(arg)
    end

    defp curry(fun) do
      {_, arity} = :erlang.fun_info(fun, :arity)
      curry(fun, arity, [])
    end

    defp curry(fun, 0, arguments) do
      apply(fun, Enum.reverse(arguments))
    end

    defp curry(fun, arity, arguments) do
      fn arg -> curry(fun, arity - 1, [arg | arguments]) end
    end
  end

  defmodule Basic do
    def call(list, id, mappings, relations) do
      Enum.each(list, fn item ->
        finalize_item(
          Helpers.relation_id(item, relations),
          Helpers.transform_item(item, mappings),
          id
        )
      end)
    end

    defp finalize_item(relation_id, item, id) do
      IO.inspect({{:from, id}, {:to, relation_id}, item})
    end
  end

  defmodule Pipe do
    def call(list, id, mappings, relations) do
      Enum.each(list, fn item ->
        item
        |> Helpers.transform_item(mappings)
        |> finalize_item(id, &Helpers.relation_id/2).(relations)
      end)
    end

    defp finalize_item(id, relation_id_func) do
      fn item, relations ->
        IO.inspect({{:from, id}, {:to, relation_id_func.(item, relations)}, item})
      end
    end
  end

  def compare do
    IO.puts("BASIC")
    Basic.call(@list, @id, @mappings, @relations)
    IO.puts("PIPE")
    Pipe.call(@list, @id, @mappings, @relations)
    IO.puts("COMPOSE")
    Compose.call(@list, @id, @mappings, @relations)
  end
end
