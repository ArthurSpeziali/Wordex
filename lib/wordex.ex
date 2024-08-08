defmodule Wordex do
    @type stream() :: struct()
    @type dict() :: [map()]

    @moduledoc """
    Main module of the Wordex program, where it is a human interface module.

    The main function of the module is "start/2":
        @spec start(file_path :: Path.t(), stream_dict :: stream()) :: dict()
        def start(file_path, stream_dict)

    It accepts the path to the file and a dictionary created by "online_fetch" or "offline_fetch()"
    Where it returns a list of maps, showing which words are correct, and which ones need suggestions.

    After getting the list of maps containing the suggestions, choose between "force_change/2" (Automatic) or "ask_change/2" (TUI)
    to replace the wrong words with the correct ones in the chosen file.
    """


    @doc """
    Function that receives a path to a file, and a dict (Stream Data). To create the dict, look at the functions "online_fetch/2" or 
    "offline_fetch/1". In addition, it has an optional argument "space?", which by default is "true", but if you want to include unnecessary 
    spaces in your files, set it to "false".

    It returns a list of maps, where each map is a word from the file that is the key, and its value is an Atom ":correct" if it is correct, 
    or if it is wrong, a list of 5 suggestions strings (in order of most similar).

    Wordex.start("Hello.txt", dict, false)

    #=> [
          %{"This" => :correct},
          %{"" => :correct},
          %{"" => :correct},
          %{"" => :correct},
          %{"is" => :correct},
          %{"a" => :correct},
          %{
            "beautifl" => ["beautiful", "beat", "beauty", "brutal",
             "testify", "meantime"]
          },
          %{
            "setence!\\n" => ["sentence", "essence", "science",
             "absence", "stance", "settle"]
          }
        ]
    """
    @spec start(stream_dict :: stream(), file_path :: Path.t(), space? :: boolean()) :: dict()
    def start(stream_dict, file_path, space? \\ true) do
        if !File.exists?(file_path) do
            raise(Wordex.Errors, "File path does not exist. (#{file_path})")
        end

        # Opens the file, turns it into a list and removes the characters from the blacklist (@black_words).
        content = File.read!(file_path)
                  |> separe_line()

        content = if space? do
            Enum.reject(content, &(&1 == ""))
        else
            content
        end

        # It starts a process of the "term_compare()" function for each word.
        # At the end it waits for all of them to be completed and saves them in a list, in the correct order.
        tasks = Enum.map(content, fn word ->
            Task.async(Wordex, :term_compare, [reform_string(word), stream_dict])
        end)
        # "Process.sleep(50)" prevents errors from occurring, as a task starts exactly when one finishes.
        Process.sleep(50)
        response = Task.await_many(tasks, :infinity)

        # Turns the two lists into a list of maps, the word is the key, and the suggestion (or whether it is correct) is the value.
        Enum.zip(content, response)
        |> Enum.map(fn {key, value} ->
            %{key => value}
        end)
    end


    @spec separe_line(string :: String.t()) :: [String.t()]
    defp separe_line(string) do
        # Function that splits the string first by spaces, then splits it further if the string contains "\n". In the end it compacts the list 
        # so that there are no sub-lists inside.
        list = String.split(string, " ")

        Enum.map(list, fn str ->

            if String.contains?(str, "\n") do
                index = Enum.find_index(
                    String.to_charlist(str),
                    &(&1 == ?\n)
                )

                String.split_at(str, index + 1)
                |> Tuple.to_list()
            else
                str
            end

        end)
        |> List.flatten()

    end


    @doc """
    Function that returns a Stream Data of the contents of a file (line by line), if it does not exist, it gives an error.
    """
    @spec offline_fetch(path :: Path.t()) :: stream()
    def offline_fetch(path) do
        if !File.exists?(path) do
            raise(Wordex.Errors, "File path does not exist. (#{path})")
        end

        File.stream!(path)
        |> Stream.map(fn item ->
            String.replace(item, "\n", "")
        end)
    end

    @doc """
    Function that returns a list of strings (In a Stream Data) from an http request, each item with one word.
    The first argument is the language (:en, :pt) in a Atom. The second is size (:light, :complex) also in a Atom.
    """
    @spec online_fetch(language :: atom(), size :: atom()) :: stream()
    def online_fetch(language \\ :en, size \\ :light) do
        urls = Application.get_all_env(:wordex)

        # Matches the language and dictionary size, and returns the value in "config.exs" from the url to the raw github.
        case {language, size} do
            {:pt, :light} -> urls[:pt_light]
            {:pt, :complex} -> urls[:pt_complex]
            {:en, :light} -> urls[:en_light]
            {:en, :complex} -> urls[:en_complex]
            {_, _} -> raise(Wordex.Errors, "Invalid dictionary's languague or size")

        # Makes an http request to get the file.
        end |>
        HTTPoison.get!()
        |> Map.get(:body)
        |> String.split("\n")
        |> Stream.map(&(&1))
    end


    @doc """
    Function that uses a data stream from a dictionary to compare the five most similar words to "input_string".
    Then calls the "make_result/2" function to find out if the word is correct, or to better reorganize the suggestions.
    """
    @spec term_compare(input_string :: String.t(), stream_dict :: stream()) :: [String.t()]
    def term_compare(input_string, stream_dict) do
        # It uses Steam data from a list, each item with one word, and uses the Simetric library, using the "Levensthein.compare/2" function 
        # to give a score from 0 to infinity (0 being the closest) of how similar a string is to another. Then makes the result calling "make_result()" function.
        Stream.map(
            stream_dict,
            fn word ->
                %{word => Simetric.Levenshtein.compare(input_string, word)}
            end
        ) |> Enum.sort_by(
            &(Map.values(&1)),
            :asc
        ) |> Enum.take(5)
        |> make_result(input_string)
    end

    @spec make_result(word_set :: dict(), input_string :: String.t()) :: [String.t()]
    defp make_result(word_set, input_string) do
        # Checks if the suggested word is the same spelling, then returns the atom, otherwise, uses "String.jaro_distance/2" for greater precision.
        any? = Enum.any?(word_set, fn item -> 
            Map.values(item) == [0]
        end)

        if any? do
            :correct
        else
            Enum.map(word_set, fn item -> 
                word = Map.keys(item)
                       |> List.first()

                %{word => String.jaro_distance(input_string, word)}
            end) 
            |> Enum.sort_by(&Map.values/1, :desc)
            |> Enum.map(fn item -> 
                Map.keys(item)
                |> List.first()
            end)
        end
    end


    @spec reform_string(string :: String.t()) :: String.t()
    defp reform_string(string) do
        String.downcase(string)
        |> String.replace("\n", "")
        |> String.replace("!", "")
        |> String.replace("?", "")
        |> String.replace(".", "")
        |> String.replace(",", "")
    end


    @spec ask_change(suggestions :: dict(), file_path :: Path.t()) :: no_return()
    def ask_change(suggestions, file_path) do
        if !File.exists?(Path.dirname(file_path)) do
            raise(Wordex.Errors, "Folder path does not exist. (#{file_path})")
        end

        corrections = Wordex.Interface.interface(suggestions, Path.basename(file_path))
        correct_words(suggestions, corrections)
        |> write_words(file_path)
    end


    @spec correct_words(suggestions :: dict(), corrections :: [String.t()]) :: [String.t()]
    defp correct_words(suggestions, corrections) do
        # It creates a new list, if the word in "suggestions" is correct, it uses it, now if it has the list of suggestions, 
        # it uses the one in "corrections"

        if corrections != [] do
            index = Enum.find_index(suggestions, fn map ->
                Map.values(map) != [:correct]
            end)

            List.replace_at(
                suggestions,
                index,
                %{hd(corrections) => :correct}
            ) |> correct_words(tl(corrections))

        else
            Enum.map(suggestions, fn map -> 
                Map.keys(map)
                |> List.first()
            end)

        end

    end


    @spec write_words(word_list :: [String.t()], file_path :: Path.t()) :: no_return()
    defp write_words(word_list, file_path) do
        content = Enum.join(word_list, " ")
                  |> String.replace("\n ", "\n")
        File.write(file_path, content, [:write])
    end


    @spec force_change(suggestions :: dict(), file_path :: Path.t()) :: no_return()
    def force_change(suggestions, file_path) do
        if !File.exists?(Path.dirname(file_path)) do
            raise(Wordex.Errors, "Folder path does not exist. (#{file_path})")
        end

        Enum.map(suggestions, fn map ->
            key = Map.keys(map)
                  |> List.first()
            value = Map.values(map)
                  |> List.first()

            if value != :correct do
                # If the old string has "\n", also add "\n" to the new one, and then format it, keeping in mind whether it is capitalized 
                # or not, and whether it has a mark.
                correct = List.first(value)
                if String.last(key) == "\n" do
                    correct <> "\n"
                else
                    correct
                end
                |> Wordex.Interface.keep_mark(key)
                |> Wordex.Interface.keep_case(key)
            else
                key
            end

        end) |> write_words(file_path)
    end

end
