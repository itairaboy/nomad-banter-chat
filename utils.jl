module DataCleaner

export read_whatsapp, collapse_chat

"""
read_whatsapp(path)

Reads a WhatsApp chat file and returns an array of strings.

# Arguments

- `path`: A string representing the file path to the WhatsApp chat file.

# Returns

- An array of strings, where each element represents a line in the WhatsApp chat file.

# Examples

```jldoctest
julia> chat = read_whatsapp("whatsapp.txt")
83-element Vector{String}:
 "25/12/2019, 23:59 - Alice: Merry Christmas, everyone!"
 "26/12/2019, 00:01 - Bob: Merry Christmas, Alice! How's everyone doing?"
 "26/12/2019, 00:02 - Charlie: Merry Christmas! Just finished dinner with the family. How about you guys?"
 ...
```
"""
function read_whatsapp(path)
    f = open(path, "r")
    chat = readlines(f)
    close(f)
    return chat
end

"""
collapse_chat(x, i, j)

Collapse consecutive chats in a WhatsApp chat file.

# Arguments
- `x`: Array{String}: The WhatsApp chat file. In the form of an array of strings.
- `i`: Int: The index of the first chat line to be collapsed.
- `j`: Int: The index of the second chat line to be collapsed.

# Returns
- `x[i]`: String: The collapsed chat line.

Description:
This function collapses consecutive chat lines in a WhatsApp chat file
by concatenating the messages of the two lines into a single line. It is used
to simplify the chat file for easier processing. The function checks if the
second line starts with a date string in the format '##/##/####, '
(where '#' is a digit), and if it does not, it concatenates the messages of
the two lines into a single line and deletes the second line from the array.
If the second line does start with a date string, it returns the first line as
is. The function recursively calls itself until all consecutive chat lines
have been collapsed.
"""
function collapse_chat(x, i, j)
    reg = r"^(0?[1-9]|[12][0-9]|3[01])[\/](0?[1-9]|1[012])[\/]\d{4}[,][ ]" # Matches '##/##/####, '
    if occursin(reg, x[j])
        return x[i]
    else
        x[i] = string(x[i], " ", x[j])
        deleteat!(x, j)
        return collapse_chat(x, i, i + 1)
    end
end

end

module StringTools

export issymbol, count_char, count_symbols, sum_symbols, count_media

"""
issymbol(c::AbstractChar) -> Bool

Tests whether a character belongs to the Unicode category Other Symbol, i.e. 😀
character whose category code begins with 'So'.
# Examples
```jldoctest
julia> issymbol('a')
false
julia> issymbol('α')
false
julia> issymbol('❤')
true
```
"""
issymbol(c::AbstractChar) = Base.Unicode.category_code(c) == 22 # Other Symbol

"""
count_char(c::Vector{Char})

Counts the occurrence of each character in the given string `s`.

# Arguments

- `c::Vector{Char}`: The vector of chars to count the characters in.

# Returns

- `res::Dict{Char, Int}`: A dictionary where the keys are the characters in `s` and the values are the number of times that character appears in `s`.

# Example

```julia
julia> count_char("hello")
Dict{Char, Int64} with 4 entries:
  'e' => 1
  'l' => 2
  'h' => 1
  'o' => 1
"""
function count_char(c::Vector{Char})
    res = Dict{Char, Int}()
    for char in c
        res[char] = get(res, char, 0) + 1
    end
    return res
end

"""
count_symbols(s::AbstractString) -> Vector{Tuple{Char,Int}}

Given a string `s`, returns a sorted vector of tuples where each tuple represents a Unicode symbol and its count in the input string.

# Arguments
- `s::AbstractString`: A string to analyze

# Returns
A sorted vector of tuples where each tuple contains the Unicode symbol and its count in the input string.

# Example
```julia
julia> count_symbols("Hello, world! 🌍👋🏽")
2-element Vector{Tuple{Char, Int}}:
 ('🌍', 1)
 ('👋', 1)
 """
function count_symbols(s)
    symbols = Vector{Char}()
    for c in s
        if issymbol(c)
            append!(symbols, c)
        end
    end
    symbols_n = count_char(symbols)
    symbols_n = sort(collect(symbols_n), by=x->x[2])
    return symbols_n
end

function sum_symbols(d)
    total_symbols = 0
    for (emoji, n) in d
        total_symbols += n
    end
    return total_symbols
end

count_media(s) = length(collect(eachmatch(r"<Media omitted>", s)))

end

module PlotHelpers

using PlotlyJS
using WordCloud

export layout, config, wordcloud2

function layout()
    ly = PlotlyJS.Layout(
        font=attr(family="Dosis", color="white", size=36),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        margin=attr(pad=10),
        xaxis=attr(showgrid=false, zeroline=false)
    )
    return ly
end

function config()
    cf = PlotlyJS.PlotConfig(
        toImageButtonOptions=attr(
            filename="new_plot",
            height=400 / 1.618, # Golden ratio
            width=400,
            scale=1
        ).fields
    )
    return cf
end

# Wrapper around WOrdCloud.wordcloud
function wordcloud2(words, stopwords, mask, colors)
    stopwords = WordCloud.stopwords_en ∪ stopwords
    processed_text = processtext(string(words), stopwords=stopwords)

    wc = wordcloud(
        processed_text,
        mask = loadmask(mask),
        angles = 0:90,
        colors = colors,
        density = 0.5,
        fonts="Dosis",
        minfontsize=1,
        state=initwords!
        )

    placewords!(wc, style=:gathering, level=5, centeredword=true)
    generate!(wc) 

    return wc
end

end