module Main exposing (main)

import Browser
import Browser.Events exposing (onAnimationFrame)
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Color exposing (Color)
import Cube
import Html exposing (..)
import Html.Attributes exposing (..)
import Time exposing (Posix)


type alias Point =
    { x : Float
    , y : Float
    , size : Float
    , deviation : Float
    , speedMod : Float
    }


type alias Model =
    { pts : List Point, cubeTheta : Float }


type Msg
    = AnimationFrame Posix


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
            ( { model | pts = List.map updatePoint model.pts, cubeTheta = model.cubeTheta + 0.01 }
            , Cmd.none
            )


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
        ]


drawPoint : Point -> Shape
drawPoint { x, y, size } =
    circle ( x, y ) size
