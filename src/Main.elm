module Main exposing (main)

import Browser
import Browser.Events exposing (onAnimationFrame, onClick)
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Color exposing (Color)
import Cube
import Generated.Api exposing (Account, LoginResponse, Profile, postLogin, postRegister)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http exposing (Error)
import Time exposing (Posix)


type alias Point =
    { x : Float
    , y : Float
    , size : Float
    , deviation : Float
    , speedMod : Float
    }


type alias Model =
    { pts : List Point
    , cubeTheta : Float
    , errors : List Error
    , account : Account
    }


type Msg
    = AnimationFrame Posix
    | Register Account
    | Login Account
    | RegisterSuccess (Result Http.Error LoginResponse)
    | LoginSuccess (Result Http.Error LoginResponse)
    | AccountNameChanged String
    | AccountPasswordChanged String


main : Program () Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }


subscriptions : Model -> Sub Msg
subscriptions _ =
    onAnimationFrame AnimationFrame


h : Float
h =
    500


w : Float
w =
    500


padding : Float
padding =
    w / 6


cellW : Float
cellW =
    w - (padding * 2)


cellH : Float
cellH =
    h - (padding * 2)


particleColor : Color
particleColor =
    Color.rgba 0 0 0 0.3


numParticles : Int
numParticles =
    1000


init : () -> ( Model, Cmd Msg )
init () =
    ( { pts =
            List.range 0 numParticles
                |> List.map
                    (\i ->
                        { x = w / 2
                        , y = h / 2
                        , size = toFloat (modBy 2 i + 1)
                        , speedMod = toFloat (modBy 345 (i * 4236))
                        , deviation = toFloat (modBy 4435 (i * 2346))
                        }
                    )
      , cubeTheta = 0
      , errors = []
      , account = Account Nothing "anon" "" (Profile "anon")
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame time ->
            let
                timef =
                    time |> Time.posixToMillis |> toFloat

                normalize x =
                    (x + 1) / 2

                updatePoint point =
                    { point
                        | x =
                            normalize (sin ((timef / (300 + point.speedMod)) + point.deviation))
                                * cellW
                                + padding
                        , y =
                            normalize (cos ((timef / (500 - point.speedMod)) + point.deviation + 4543))
                                * cellH
                                + padding
                    }
            in
            ( { model | pts = List.map updatePoint model.pts, cubeTheta = model.cubeTheta + 0.005 }
            , Cmd.none
            )

        Register account ->
            ( model, postRegister account RegisterSuccess )

        RegisterSuccess result ->
            case result of
                Ok _ ->
                    ( model
                    , Cmd.none
                    )

                Err err ->
                    ( { model | errors = model.errors ++ [ err ] }
                    , Cmd.none
                    )

        LoginSuccess result ->
            case result of
                Ok _ ->
                    ( model
                    , Cmd.none
                    )

                Err err ->
                    ( { model | errors = model.errors ++ [ err ] }
                    , Cmd.none
                    )

        AccountNameChanged n ->
            let
                acc =
                    model.account
            in
            ( { model | account = { acc | accountName = n } }, Cmd.none )

        AccountPasswordChanged p ->
            let
                acc =
                    model.account
            in
            ( { model | account = { acc | accountPassword = p } }, Cmd.none )

        Login account ->
            ( model, postLogin account LoginSuccess )


view : Model -> Html Msg
view model =
    div []
        [ Canvas.toHtml
            ( round w, round h )
            []
            [ shapes [ fill Color.white ] [ rect ( 0, 0 ) w h ]
            , shapes [ fill particleColor ] (List.map drawPoint model.pts)
            ]
        , Cube.view model.cubeTheta
        , div [] [ Html.text model.account.accountName ]
        , div []
            [ div []
                [ label [ for "username" ] [ Html.text "Username" ]
                , input
                    [ id "username"
                    , type_ "text"
                    , placeholder "your username"
                    , value model.account.accountName
                    , onInput AccountNameChanged
                    ]
                    []
                ]
            , div []
                [ label [ for "password" ] [ Html.text "Password" ]
                , input
                    [ id "password"
                    , type_ "password"
                    , placeholder "your password"
                    , value model.account.accountPassword
                    , onInput AccountPasswordChanged
                    ]
                    []
                ]
            , button [ Html.Events.onClick (Register model.account) ] [ Html.text "Register" ]
            , button [ Html.Events.onClick (Login model.account) ] [ Html.text "Login" ]
            ]
        ]


drawPoint : Point -> Shape
drawPoint { x, y, size } =
    circle ( x, y ) size
