#!/bin/zsh
# - KalWing quOTE fetcher -
# Simple plugin that fetch quotes from an api on my website, and display them.
# It also had to handle dialog.
# This is completely useless and just for my personal use. Wanted to dip into shell
# scripting again.
# The api must return an object with this form :
# {"lines":
#     [
#         {
#             "author":"aaa",
#             "quote":"qqq"
#         },{
#             "author":"AAA",
#             "quote":"QQQ"
#         },
#         ...
#     ]
# }


display_kwote () {
    # jq transforms the api return to something like:
    # [
    #   "Shepard",
    #   "Come on, Liara. You've seen the data. Even if we win, you and I won't live to see the parade.",
    #   "Liara",
    #   "Then what's the damn point? Of drinks... or... any of it... if we could all die tomorrow?",
    #   "Shepard",
    #   "It's not tomorrow yet."
    # ]
    # display_kwote just has to display line alternatively

    line_count=0
    while read quotes; do
        if [[ -z "$author" && $quotes == \"*\", ]]; then
            author=$quotes
        elif [[ $quotes =~ \"*\",?$ ]]; then
            quote=$quotes
        fi

        if [[ -n "$author" && -n "$quote" ]]; then
            stripped_text=${author#\"}  # Remove leading quote
            stripped_author=${stripped_text%\",}
            stripped_text=${quote#\"}  # Remove leading quote
            stripped_text=${stripped_text%,}
            stripped_quote=${stripped_text%\"}
            if [[ $(( line_count % 2 )) == 0 ]]; then
                author_color="\e[1;37m"
                quote_color="\e[0;35m"
            else
                author_color="\e[0;37m"
                quote_color="\e[0;34m"
            fi
            if [[ -n "$stripped_author" ]]; then
                em=" — "
            else
                em=""
            fi
            echo "$author_color$stripped_author\e[0m$em$quote_color“$stripped_quote”\e[0m"
            # Reset for next entry
            author=""
            quote=""
            line_count=$(( line_count + 1 ))
        fi
    done
}


fetch_kwote () {
    if [[ $# < 1 ]]; then
        echo "Usage fetch_kwote API_url [timeout]"
    fi
    if [[ $# -eq 2 ]]; then
        timeout=$2
    else
        timeout=5
    fi

    # Test jq parsing and display_kwote without an API:
    # TEST="{\"lines\":[{\"author\":\"Shepard\",\"quote\":\"Come on, Liara. You've seen the data. Even if we win, you and I won't live to see the parade.\"},{\"author\":\"Liara\",\"quote\":\"Then what's the damn point? Of drinks... or... any of it... if we could all die tomorrow?\"},{\"author\":\"Shepard\",\"quote\":\"It's not tomorrow yet.\"}],\"tag\":\"mass_effect\"}"
    # echo "${TEST}" | jq '[.lines.[] | .author, .quote]' | display_quote

    curl --connect-timeout $timeout --silent $1 | jq '[.lines.[] | .author, .quote]' | display_kwote
    # Pretty straightforward, here's jq (great) documentation on the items used :
    # Array/Object Value Iterator: .[]
    # When given a JSON object (aka dictionary or  hash)  as  input,  .foo
    #       produces the value at the key "foo" if the key is present, or null otherwise.
    # If two filters are separated by a comma, then the same input will be fed into both and  the  two  filters´  output
    #       value  streams  will be concatenated in order
    # The  |  operator combines two filters by feeding the output(s) of the one on the left into the input of the one on
    #        the right. It´s similar to the Unix shell´s pipe, if you´re used to that.
}