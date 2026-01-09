module Main exposing (..)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--

import Browser
import Html exposing (Html, br, button, div, text)
import Html.Events exposing (onClick)
import Random



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { value : Int, inc : Int }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model 0 0, Cmd.none )



-- UPDATE


type Msg
    = Increment
    | Decrement
    | GenerateRandom
    | NewRandom Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | value = model.value + model.inc }, Cmd.none )

        Decrement ->
            ( { model | value = model.value - model.inc }, Cmd.none )

        NewRandom n ->
            ( { model | inc = n }, Cmd.none )

        GenerateRandom ->
            ( model, Random.generate NewRandom (Random.int 1 100) )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt model.value) ]
        , button [ onClick Increment ] [ text "+" ]
        , br [] []
        , button [ onClick GenerateRandom ] [ text "+" ]
        ]
