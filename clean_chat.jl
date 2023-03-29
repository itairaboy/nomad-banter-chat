#
# Takes the raw whatsap .txt file and transforms it into a useful .csv
# Right now only works for Android exports
#

# Load necessary packages
using DataFrames, Dates, CSV

include("utils.jl")
using .DataCleaner

# Open and read in WhatsApp chat file
chat = read_whatsapp("data/whatsapp.txt")

# Remove empty lines from chat
filter!(x -> length(x) > 0, chat)

# Loop through each line of the chat and collapse consecutive chats
for i in eachindex(chat)
    if i == length(chat)
        break
    end
    collapse_chat(chat, i, i + 1)
end

# Create an empty DataFrame with the desired columns
chat_df = DataFrame(
    date = Date[],
    time = Time[],
    name = String[],
    message = String[]
)

# Loop through each line in the chat to populate the DataFrame
for line in chat
    # Extract name and message text from line
    rest = split(line[21:end], ":")
    if length(rest) == 1 # Skip info messages
        continue
    end
    
    # Extract date, time, name, and message from line
    date = Date(line[1:10], "d/m/y")
    time = Time(line[13:17], "HH:MM")
    name = rest[1]
    message = strip(rest[2])

    # Add row to DataFrame with extracted information
    push!(chat_df, [date, time, name, message])
end

CSV.write("data/cleaned_chat.csv", chat_df)