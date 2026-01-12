module Generated.Api exposing (..)

-- The following module comes from bartavelle/json-helpers

import Dict exposing (Dict)
import Http
import Json.Decode
import Json.Encode exposing (Value)
import Json.Helpers exposing (..)
import Set
import String
import Url.Builder


type alias Item =
    { itemId : Int
    , itemText : String
    }


jsonDecItem : Json.Decode.Decoder Item
jsonDecItem =
    Json.Decode.succeed (\pitemId pitemText -> { itemId = pitemId, itemText = pitemText })
        |> required "itemId" Json.Decode.int
        |> required "itemText" Json.Decode.string


jsonEncItem : Item -> Value
jsonEncItem val =
    Json.Encode.object
        [ ( "itemId", Json.Encode.int val.itemId )
        , ( "itemText", Json.Encode.string val.itemText )
        ]


getItem : (Result Http.Error (List Item) -> msg) -> Cmd msg
getItem toMsg =
    let
        params =
            List.filterMap identity
                (List.concat
                    []
                )
    in
    Http.request
        { method =
            "GET"
        , headers =
            []
        , url =
            Url.Builder.crossOrigin "http://localhost:8080"
                [ "item"
                ]
                params
        , body =
            Http.emptyBody
        , expect =
            Http.expectJson toMsg (Json.Decode.list jsonDecItem)
        , timeout =
            Nothing
        , tracker =
            Nothing
        }


getItemByItemId : Int -> (Result Http.Error Item -> msg) -> Cmd msg
getItemByItemId capture_itemId toMsg =
    let
        params =
            List.filterMap identity
                (List.concat
                    []
                )
    in
    Http.request
        { method =
            "GET"
        , headers =
            []
        , url =
            Url.Builder.crossOrigin ""
                [ "item"
                , capture_itemId |> String.fromInt
                ]
                params
        , body =
            Http.emptyBody
        , expect =
            Http.expectJson toMsg jsonDecItem
        , timeout =
            Nothing
        , tracker =
            Nothing
        }
