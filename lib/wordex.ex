defmodule Wordex do
    @type stream() :: struct()
    @type dict() :: [map()]
    @black_words [""]

    @moduledoc """
    Main module of the Wordex program, where it is a human interface module.

    The main function of the module is "start/2":
        @spec start(file_path :: Path.t(), stream_dict :: stream()) :: dict()
        def start(file_path, stream_dict)

    It accepts the path to the file and a dictionary created by "online_fetch" or "offline_fetch()"
    Where it returns a list of maps, showing which words are correct, and which ones need suggestions.
    """


    @spec start(file_path :: Path.t(), stream_dict :: stream()) :: dict()
    def start(file_path, stream_dict) do
        if !File.exists?(file_path) do
            raise(Wordex.Errors, "File path does not exist. (#{file_path})")
        end

        # Opens the file, turns it into a list and removes the characters from the blacklist (@black_words).
        content = File.read!(file_path)
                  |> String.split(" ")
                  |> Enum.reject(&(&1 in @black_words))


        # It starts a process of the "term_compare()" function for each word.
        # At the end it waits for all of them to be completed and saves them in a list, in the correct order.
        tasks = Enum.map(content, fn word ->
            Task.async(Wordex, :term_compare, [reform_string(word), stream_dict])
        end)
        response = Task.await_many(tasks, :infinity)

        # Turns the two lists into a list of maps, the word is the key, and the suggestion (or whether it is correct) is the value.
        Enum.zip(content, response)
        |> Enum.map(fn {key, value} ->
            %{key => value}
        end)
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
    Then calls the "make_result()" function to find out if the word is correct, or to better reorganize the suggestions.
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
        ) |> Enum.take(6)
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


    @doc """
    Function that formats or replaces a string, to be valid when comparing
    """
    @spec reform_string(string :: String.t()) :: String.t()
    def reform_string(string) do
        String.downcase(string)
        |> String.replace("\n", "")
        |> String.replace("!", "")
        |> String.replace("?", "")
    end

end
