module Main exposing (..)

import Json.Decode exposing (keyValuePairs, at, int, list, field, string, map4)
import Html exposing (div, text, td, tr, thead, tbody, th, input, h1)
import Html.Attributes exposing (type_)
import Html.Events exposing (onInput)
import Http
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
    }


type Msg
    = LoadData
    | DataLoaded (Result Http.Error Transactions)
    | Input String


init : ( Model, Cmd Msg )
init =
    ( model, getData )


model : Model
model =
    Model [] ""


getData : Cmd Msg
getData =
    let
        url =
            "https://fux7yt6bl8.execute-api.eu-west-2.amazonaws.com/prod/transaction"

        request =
            Http.get url decodeTransactions
    in
        Http.send DataLoaded request


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
        LoadData ->
            ( model, Cmd.none )

        DataLoaded (Ok transactions) ->
            ( Model
                (sortBy .time transactions)
                model.input
            , Cmd.none
            )

        DataLoaded (Err msg) ->
            ( model, getData )

        Input txt ->
            ( Model model.transactions txt, Cmd.none )


title =
    h1 [] [ text "All Transactions" ]


searchbar =
    input [ type_ "text", onInput Input ] []


view : Model -> Html.Html Msg
view model =
    div []
        [ title
        , searchbar
        , list2Table model
        ]


list2Table model =
    let
        txContains str tx =
            (String.contains str tx.description) || (String.contains str tx.category)

        txs =
            List.filter (txContains model.input) model.transactions
    in
        Html.table []
            [ thead []
                [ tr []
                    [ th [] [ text "Category" ]
                    , th [] [ text "Timestamp" ]
                    , th [] [ text "Description" ]
                    , th [] [ text "Amount" ]
                    ]
                , tbody []
                    (List.map
                        transactionRow
                        txs
                    )
                ]
            ]


transactionRow { category, time, amount, description } =
    tr []
        [ td [] [ text category ]
        , td [] [ text time ]
        , td [] [ text description ]
        , td []
            [ text <|
                (\x -> "£ " ++ x) <|
                    toString <|
                        -amount
                            // 100
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
