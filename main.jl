# Load necessary packages
using CSV
using DataFrames
using DataFramesMeta
using Dates
using PlotlyJS
using WordCloud

# Custom modules
include("utils.jl")
using .StringTools, .PlotHelpers

# Read the .csv generated with clean_chat.jl
chat = DataFrame(CSV.File("data/cleaned_chat.csv"))

# Number of messages
nrow(chat)

# Custom color pallete
custom_pal = [
    "#002b5b",
    "#1a5f7a",
    "#00b4d8",
    "#42dea5",
    "#25d366",
    "#C97064"
]

# Plots -----

## Messages per user -----------
# Per user
msgs_per_user =
    @chain chat begin
        @by(:name, :n = length(:name))
        @orderby(:n)
    end

msgs_per_user_plot =
    plot(
        msgs_per_user[end-4:end, :],
        x=:n,
        y=:name,
        kind="bar",
        orientation="h",
        marker=attr(color=custom_pal[5], height=1),
        PlotHelpers.layout(),
        config=PlotHelpers.config()
    )

relayout!(msgs_per_user_plot,
    xaxis=attr(title="Number of messages"),
    yaxis=attr(title="", showticklabels=false),
    margin=attr(r=600)
)
savefig(msgs_per_user_plot, "svg/msgs_per_user_plot.html")

# Messages per active days
msgs_per_active =
    @chain chat begin
        @by(:name, :min = minimum(:date), :n = length(:name))
        @transform :active_days = Int.((today() - :min) / Day(1))
        @transform @byrow :msgs_per_day = :n / :active_days
        @orderby(:msgs_per_day)
    end

msgs_per_active[end-10:end, :]

# Messages per time -----
## Per hour of the day -----
msgs_per_dayhour =
    @chain chat begin
        @transform :hour = hour.(:time)
        @by(:hour, :n = length(:message))
        @transform :hour_str = string.(:hour, ":00")
    end

perhour_plot =
    plot(
        msgs_per_dayhour,
        x=:hour,
        y=:n,
        kind="bar",
        marker=attr(color=custom_pal[6]),
        PlotHelpers.layout(),
        config=PlotHelpers.config()
    )

relayout!(perhour_plot,
    xaxis=attr(dtick=1, tick0=0, title="Hour of the day"),
    yaxis=attr(title="", gridwidth=0.5)
)
savefig(perhour_plot, "svg/perhour_plot.html")

polar_perhour_plot =
    plot(scatterpolar(
            msgs_per_dayhour,
            theta=:hour_str,
            r=:n,
            mode="lines",
            marker=attr(color=custom_pal[3]),
            fill="toself"
        ), PlotHelpers.layout())

relayout!(polar_perhour_plot,
    polar=attr(
        angularaxis=attr(rotation=90, direction="clockwise"),
        radialaxis=attr(showticklabels=false, gridwidth=0.5),
        bgcolor="rgba(0,0,0,0)"
    )
)
polar_perhour_plot
savefig(polar_perhour_plot, "svg/polar_perhour_plot.html")

## Per day of the week -----
msgs_per_weekday =
    @chain chat begin
        @transform :wday = dayname.(:date)
        @by(:wday, :n = length(:message))
    end

polar_weekday_plot =
    plot(scatterpolar(
        msgs_per_weekday,
            theta=:wday,
            r=:n,
            mode="lines",
            marker=attr(color=custom_pal[3]),
            fill="toself"
        ), PlotHelpers.layout())

relayout!(polar_weekday_plot,
    polar=attr(
        angularaxis=attr(rotation=90+360/7, direction="clockwise"),
        radialaxis=attr(showticklabels=true, gridwidth=0.5),
        bgcolor="rgba(0,0,0,0)"
    )
)

polar_weekday_plot

savefig(polar_weekday_plot, "svg/polar_weekday_plot.html")

## Historic per month -----
# We've had the chat for less than a year
msgs_per_month =
    @chain chat begin
        @transform :month = string.(monthname.(:date), " ", year.(:date) .% 1000)
        @by(:month, :n = length(:message))
    end

month_plot =
    plot(
        msgs_per_month,
        x=:month,
        y=:n,
        kind="scatter",
        fill="tozeroy",
        marker=attr(color=custom_pal[5]),
        PlotHelpers.layout(),
        config=PlotHelpers.config()
    )

relayout!(month_plot,
    xaxis=attr(title="", tickangle=-45, showspikes=true),
    yaxis=attr(title="", gridwidth=0.5),
    margin=attr(r=300)
)

savefig(month_plot, "svg/month_plot.html")

# Hummus?
msgs_per_date =
    @chain chat begin
        @by(:date, :n = length(:message))
        @orderby(:n)
    end

# Number of emojis -----
# Union of all messages
all_messages = string(chat[:, :message])[23:end] # Ignore Union type specification

symbols = StringTools.count_symbols(all_messages)
total_symbols = StringTools.sum_symbols(symbols)

media = StringTools.count_media(all_messages)

# Wordcloud -----
stopwords = ["Media", "omitted", "u200d", "385"]

wc = PlotHelpers.wordcloud2(all_messages, stopwords, "res/split_mask.png", custom_pal[3:end])

paint(wc, "svg/wordcloud.svg", background=false)
