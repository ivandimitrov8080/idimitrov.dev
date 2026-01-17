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
    , itemName : String
    }


jsonDecItem : Json.Decode.Decoder Item
jsonDecItem =
    Json.Decode.succeed (\pitemId pitemText pitemName -> { itemId = pitemId, itemText = pitemText, itemName = pitemName })
        |> required "itemId" Json.Decode.int
        |> required "itemText" Json.Decode.string
        |> required "itemName" Json.Decode.string


jsonEncItem : Item -> Value
jsonEncItem val =
    Json.Encode.object
        [ ( "itemId", Json.Encode.int val.itemId )
        , ( "itemText", Json.Encode.string val.itemText )
        , ( "itemName", Json.Encode.string val.itemName )
        ]


type alias Account =
    { accountId : Int
    , accountName : String
    , accountPassword : String
    }


jsonDecAccount : Json.Decode.Decoder Account
jsonDecAccount =
    Json.Decode.succeed (\paccountId paccountName paccountPassword -> { accountId = paccountId, accountName = paccountName, accountPassword = paccountPassword })
        |> required "accountId" Json.Decode.int
        |> required "accountName" Json.Decode.string
        |> required "accountPassword" Json.Decode.string


jsonEncAccount : Account -> Value
jsonEncAccount val =
    Json.Encode.object
        [ ( "accountId", Json.Encode.int val.accountId )
        , ( "accountName", Json.Encode.string val.accountName )
        , ( "accountPassword", Json.Encode.string val.accountPassword )
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
            Url.Builder.crossOrigin "http://localhost:8080"
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


getItemByItemText : String -> (Result Http.Error Item -> msg) -> Cmd msg
getItemByItemText capture_itemText toMsg =
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
                , capture_itemText
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


postRegister : Account -> (Result Http.Error Account -> msg) -> Cmd msg
postRegister body toMsg =
    let
        params =
            List.filterMap identity
                (List.concat
                    []
                )
    in
    Http.request
        { method =
            "POST"
        , headers =
            []
        , url =
            Url.Builder.crossOrigin "http://localhost:8080"
                [ "register"
                ]
                params
        , body =
            Http.jsonBody (jsonEncAccount body)
        , expect =
            Http.expectJson toMsg jsonDecAccount
        , timeout =
            Nothing
        , tracker =
            Nothing
        }


postLogin : Account -> (Result Http.Error Account -> msg) -> Cmd msg
postLogin body toMsg =
    let
        params =
            List.filterMap identity
                (List.concat
                    []
                )
    in
    Http.request
        { method =
            "POST"
        , headers =
            []
        , url =
            Url.Builder.crossOrigin "http://localhost:8080"
                [ "login"
                ]
                params
        , body =
            Http.jsonBody (jsonEncAccount body)
        , expect =
            Http.expectJson toMsg jsonDecAccount
        , timeout =
            Nothing
        , tracker =
            Nothing
        }
