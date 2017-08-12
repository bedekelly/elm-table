module Main exposing (..)

import Date exposing (fromString)
import Date.Extra.Config.Config_en_gb
import Date.Extra.Format as Date
import Html exposing (Html, div, h1, input, node, tbody, td, text, th, thead, tr, h3, header)
import Html.Attributes exposing (autofocus, class, href, id, rel, src, title, type_, placeholder, name)
import Html.Events exposing (onInput, onClick)
import Http
import Json.Decode exposing (at, field, int, keyValuePairs, list, map4, string)
import List exposing (sortBy)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Transaction =
    { category : String
    , time : String
    , amount : Int
    , description : String
    }


type alias Transactions =
    List Transaction


type alias Model =
    { transactions : Transactions
    , input : String
    , msg : String
    , sortCategory : Field
    , order : Order
    }


type Field
    = Timestamp
    | Amount


type Order
    = Ascending
    | Descending


type Msg
    = DataLoaded (Result Http.Error Transactions)
    | Input String
    | SortBy Field


init : ( Model, Cmd Msg )
init =
    ( Model [] "" "Loading..." Timestamp Descending, getData )


getData : Cmd Msg
getData =
    let
        url =
            "https://fux7yt6bl8.execute-api.eu-west-2.amazonaws.com/prod/transaction"

        request =
            Http.get url decodeTransactions
    in
        Http.send DataLoaded request


decodeTransactions : Json.Decode.Decoder (List Transaction)
decodeTransactions =
    field "transactions" <|
        list <|
            map4 Transaction
                (field "category" string)
                (field "timestamp" string)
                (field "amount" int)
                (field "description" string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DataLoaded (Ok transactions) ->
            ( Model
                (Debug.log
                    "txs"
                    transactions
                )
                model.input
                "Loaded!"
                model.sortCategory
                model.order
            , Cmd.none
            )

        DataLoaded (Err msg) ->
            ( { model | msg = "Please make sure all your transactions are categorised." }, Cmd.none )

        Input txt ->
            ( Model model.transactions txt "Sorting..." model.sortCategory model.order, Cmd.none )

        SortBy category ->
            if category == model.sortCategory then
                ( { model | order = opp model.order }, Cmd.none )
            else
                ( { model | sortCategory = category }, Cmd.none )


opp : Order -> Order
opp c =
    case c of
        Ascending ->
            Descending

        Descending ->
            Ascending


sortedTransactions : Transactions -> Field -> Order -> Transactions
sortedTransactions transactions key order =
    let
        txs =
            case key of
                Amount ->
                    sortBy .amount transactions

                Timestamp ->
                    sortBy .time transactions
    in
        if order == Descending then
            List.reverse txs
        else
            txs


title : Html Msg
title =
    h1 [] [ text "All Transactions" ]


searchbar : Html Msg
searchbar =
    input [ type_ "text", onInput Input, class "u-full-width", autofocus True, placeholder "Search categories, descriptions..." ] []


view : Model -> Html.Html Msg
view model =
    div []
        [ meta
        , styles
        , content model
        ]


content : Model -> Html Msg
content model =
    div [ class "container" ]
        [ topContainer
        , loadingOrTable model
        ]


topContainer : Html Msg
topContainer =
    header [ class "u-full-width" ]
        [ title
        , searchbar
        ]


loadingOrTable : Model -> Html Msg
loadingOrTable model =
    let
        content =
            case model.transactions of
                [] ->
                    h3 [] [ text model.msg ]

                _ ->
                    list2Table model
    in
        div [ class "table-container" ] [ content ]


contains : String -> String -> Bool
contains haystack needle =
    String.contains (String.toLower needle) (String.toLower haystack)


list2Table : Model -> Html Msg
list2Table model =
    let
        txContains str tx =
            (contains tx.description str) || (contains tx.category str)

        unsortedTxs =
            List.filter (txContains model.input) model.transactions

        txs =
            sortedTransactions unsortedTxs model.sortCategory model.order
    in
        Html.table [ class "u-full-width" ]
            [ thead []
                [ tr []
                    [ th [] [ text "Category" ]
                    , th [ onClick (SortBy Timestamp), class "order-heading" ] [ text "Timestamp" ]
                    , th [] [ text "Description" ]
                    , th [ onClick (SortBy Amount), class "order-heading" ] [ text "Amount" ]
                    ]
                ]
            , tbody []
                (List.map
                    transactionRow
                    txs
                )
            ]


transactionRow : Transaction -> Html Msg
transactionRow { category, time, amount, description } =
    tr []
        [ td [ class "category-cell" ] [ text category ]
        , td [] [ text <| fromStamp time ]
        , td [ Html.Attributes.title description, class "description-cell" ] [ text description ]
        , td []
            [ text <| currency amount
            ]
        ]


fromStamp : String -> String
fromStamp isoTimestamp =
    case fromString isoTimestamp of
        Ok date ->
            Date.format
                Date.Extra.Config.Config_en_gb.config
                Date.isoDateFormat
                date

        Err _ ->
            "-"


currency : Int -> String
currency amount =
    let
        sign =
            if amount < 0 then
                "- "
            else
                ""

        pounds =
            abs <| amount // 100

        pence =
            pencePad <| toString <| (abs amount) - (abs pounds * 100)
    in
        sign ++ "£ " ++ toString pounds ++ "." ++ pence


pencePad : String -> String
pencePad =
    String.padLeft 2 '0'


stylesheets : List String
stylesheets =
    [ "https://cdnjs.cloudflare.com/ajax/libs/normalize/7.0.0/normalize.min.css"
    , "https://cdnjs.cloudflare.com/ajax/libs/skeleton/2.0.4/skeleton.min.css"
    , "static/css/style.css"
    ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


link : List (Html.Attribute msg) -> List (Html msg) -> Html msg
link =
    node "link"


stylesheet : String -> Html msg
stylesheet url =
    link [ rel "stylesheet", href url ] []


script : String -> Html msg
script url =
    node "script" [ src url ] []


styles : Html msg
styles =
    div [ id "styles" ] (List.map stylesheet stylesheets)


meta : Html msg
meta =
    Html.node "meta" [ name "viewport", Html.Attributes.content "width=device-width, initial-scale=1" ] []
