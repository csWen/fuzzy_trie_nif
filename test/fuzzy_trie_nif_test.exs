defmodule FuzzyTrieNifTest do
  use ExUnit.Case

  test "should support multiple data type" do
    trie =
      FuzzyTrie.new(1, true)
      |> FuzzyTrie.insert("something", "0")
      |> FuzzyTrie.insert("something", 1)
      |> FuzzyTrie.insert("something else", [2, "3"])
      |> FuzzyTrie.insert("somewhere", {4, :where})

    assert FuzzyTrie.prefix_fuzzy_search(trie, "s0me") ==
             ["0", 1, [2, "3"], {4, :where}]

    assert FuzzyTrie.prefix_fuzzy_search(trie, "s0mething else") ==
             [[2, "3"]]
  end

  test "special character" do
    trie =
      FuzzyTrie.new(1, true)
      |> FuzzyTrie.insert("ladrón que", 0)
      |> FuzzyTrie.insert("ladron que", 1)
      |> FuzzyTrie.insert("américa narco ", 2)
      |> FuzzyTrie.insert("临兵斗者皆阵列前行", 3)

    assert FuzzyTrie.prefix_fuzzy_search(trie, "ladron") == [0, 1]
    assert FuzzyTrie.prefix_fuzzy_search(trie, "ledró") == [0]
    assert FuzzyTrie.prefix_fuzzy_search(trie, "amero") == []
    assert FuzzyTrie.prefix_fuzzy_search(trie, "灵镖斗者") == []
    assert FuzzyTrie.prefix_fuzzy_search(trie, "临兵斗者") == [3]
    assert FuzzyTrie.prefix_fuzzy_search(trie, "临兵斗者皆阵列在前") == [3]
  end

  test "get error when inserting unsupported type" do
    trie = FuzzyTrie.new(1, true)
    assert FuzzyTrie.insert(trie, "something", self()) == {:error, :unsupported_type}
  end

  test "damerau config should work" do
    trie =
      FuzzyTrie.new(1, true)
      |> FuzzyTrie.insert("something", 0)
      |> FuzzyTrie.insert("somewhere", 1)

    assert FuzzyTrie.fuzzy_search(trie, "soemthing") == [0]
    assert FuzzyTrie.prefix_fuzzy_search(trie, "soem") == [0, 1]

    trie =
      FuzzyTrie.new(1, false)
      |> FuzzyTrie.insert("something", 0)
      |> FuzzyTrie.insert("somewhere", 1)

    assert FuzzyTrie.fuzzy_search(trie, "soemthing") == []
    assert FuzzyTrie.prefix_fuzzy_search(trie, "soemth") == []
    assert FuzzyTrie.prefix_fuzzy_search(trie, "soem") == [0, 1]
  end

  test "concurrent read should work" do
    trie = FuzzyTrie.new(1, false)

    random_string = fn ->
      for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
    end

    Enum.each(1..200, fn i ->
      _ = FuzzyTrie.insert(trie, "something " <> random_string.(), i)
    end)

    1..200
    |> Enum.map(fn _ ->
      Task.async(FuzzyTrie, :prefix_fuzzy_search, [trie, "s0me"])
    end)
    |> Task.await_many()
    |> Enum.map(fn res ->
      assert is_list(res)
      assert length(res) == 200
    end)
  end
end
