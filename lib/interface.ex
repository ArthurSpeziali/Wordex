defmodule Wordex.Interface do
    @dialyzer {:nowarn_function, interface: 2, keep_case: 2}
    import Unicode, only: [uppercase?: 1, numeric?: 1]


    @moduledoc """
    Module used to complement "Wordex.ask_change/2". It was designed to be a TUI, which helps the user choose which word to replace, use the suggested ones, 
    or continue with the same one.

    The only public function of the module is "interface/2", which accepts a list of maps, where each map is the word typed by the user, and its value is an atom 
    ":correct" if it is correct, or a list with the suggested words, and also needs the path of the file used (Illustrative).
    It returns a list with the corrected words.
    """


    @spec clear() :: :ok
    defp clear() do
        IO.ANSI.clear()
        |> IO.puts()
    end

    @spec menu([String.t()]) :: String.t()
    defp menu([item1, item2, item3, item4, item5]) do
        """
                 (c)- CONTINUE      (r)- REPLACE

         (1)- #{String.capitalize(item1)}          
         (2)- #{String.capitalize(item2)}
         (3)- #{String.capitalize(item3)}          
         (4)- #{String.capitalize(item4)}
         (5)- #{String.capitalize(item5)}
        """
    end

    @spec response_user(prestring :: String.t()) :: String.t()
    defp response_user(prestring) do

        response = IO.gets(" #{prestring}> ")
                   |> String.trim()
                   |> String.downcase()

        number = 
            if numeric?(response) do
                String.to_integer(response)
            else
                0
            end

        
        cond do
            (number in 1..5//1) || (response == "c") -> response

            # Use unicode code to use the already used line (press enter), clear the line and write over it.
            response == "r" ->
                IO.write("\e[1A\e[K")
                {
                    :replace,

                    IO.gets(" {?}> ")
                    |> String.trim()
                }

            true ->
                IO.write("\e[1A\e[K")
                response_user("[!]")

        end

    end


    @doc """
    Function that prints messages on the screen to help the user (TUI). And returns a list with the corrected words.
    """
    @spec interface(suggestions :: Wordex.dict(), file_name :: Path.t()) :: [String.t()]
    def interface(suggestions, file_name) do

        for map <- suggestions, Map.values(map) != [:correct] do
            clear()

            IO.puts(" Working on \"#{file_name}\".")
            IO.puts(" +------#{String.duplicate("-", String.length(file_name))}------+")

            # Print 13 empty lines
            Enum.each(
                1..13//1,
                fn _number -> IO.puts("") end
            )


            key_word = Map.keys(map)
                       |> List.first()

            IO.puts(" Misplace word: \"#{String.replace(key_word, "\n", "")}\"\n")
            
            correct_words = Map.get(map, key_word)
            menu(correct_words)
            |> IO.puts()

            IO.puts("\n\n\n")

            response_user("") |>
            case do
                "c" -> 
                    Map.keys(map)
                    |> List.first()

                # Skip a line in the new string if the old one has "\n".
                {:replace, text} ->
                    if String.contains?(key_word, "\n") do
                        text <> "\n"
                    else
                        text
                    end |> keep_case(key_word)

                number ->
                    integer = String.to_integer(number)
                    text = Enum.at(correct_words, integer - 1)

                    if String.contains?(key_word, "\n") do
                        text <> "\n"
                    else
                        text
                    end |> keep_mark(key_word)
                    |> keep_case(key_word)
            end
        end
    end


    @doc """
    Function that if the first character of the old string is uppercase, leaves the new string capitalized.
    """
    @spec keep_case(mod :: String.t(), original :: String.t()) :: String.t()
    def keep_case(_mod, ""), do: ""

    def keep_case(mod, original) do

        String.first(original)
        |> uppercase?()
        |> if do
            String.capitalize(mod)
        else
            mod
        end

    end


    @doc """
    Function that if the last character of the old string was a mark (explanation point, full stop...), places the mark in the new string.
    """
    @spec keep_mark(mod :: String.t(), original :: String.t()) :: String.t()
    def keep_mark(mod, original) do
        char = String.last(original)
        marks = ["!", "?", ".", ","]

        # If it already has the unicode code "\n", it adds the mark first, then adds the "\n"
        if char == "\n" do
            char = String.at(original, -2)

            if char in marks do
                String.slice(mod, 0..-2//1) <> char <> "\n"
            else
                mod
            end

        else
            if char in marks do
                mod <> char
            else
                mod
            end
        end

    end

end
