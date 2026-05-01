port module Generated.Api exposing (..)

-- The following module comes from bartavelle/json-helpers

import Dict exposing (Dict)
import Http
import Iso8601
import Json.Decode
import Json.Encode exposing (Value)
import Json.Helpers exposing (..)
import Set
import String
import Time exposing (Posix)
import Url.Builder


jsonDecPosix : Json.Decode.Decoder Posix
jsonDecPosix =
    Iso8601.decoder


jsonEncPosix : Posix -> Value
jsonEncPosix posix =
    Iso8601.encode posix


port storeToken : String -> Cmd msg


port clearToken : () -> Cmd msg


port onTokenLoaded : (Maybe String -> msg) -> Sub msg


bearerToken : Maybe String -> Maybe String
bearerToken token =
    Maybe.map (\t -> "Bearer " ++ t) token


storeLoginToken : LoginResponse -> Cmd msg
storeLoginToken response =
    storeToken response.token


type alias Account =
    { accountId : Maybe Int
    , accountName : String
    , accountPassword : String
    , accountProfile : Maybe Profile
    }


jsonDecAccount : Json.Decode.Decoder Account
jsonDecAccount =
    Json.Decode.succeed Account
        |> fnullable "accountId" Json.Decode.int
        |> required "accountName" Json.Decode.string
        |> required "accountPassword" Json.Decode.string
        |> fnullable "accountProfile" jsonDecProfile


jsonEncAccount : Account -> Value
jsonEncAccount val =
    Json.Encode.object
        [ ( "accountId", maybeEncode Json.Encode.int val.accountId )
        , ( "accountName", Json.Encode.string val.accountName )
        , ( "accountPassword", Json.Encode.string val.accountPassword )
        , ( "accountProfile", maybeEncode jsonEncProfile val.accountProfile )
        ]


type alias Profile =
    { profileName : String
    , profileCreatedAt : Posix
    }


jsonDecProfile : Json.Decode.Decoder Profile
jsonDecProfile =
    Json.Decode.succeed Profile
        |> required "profileName" Json.Decode.string
        |> required "profileCreatedAt" jsonDecPosix


jsonEncProfile : Profile -> Value
jsonEncProfile val =
    Json.Encode.object
        [ ( "profileName", Json.Encode.string val.profileName )
        , ( "profileCreatedAt", jsonEncPosix val.profileCreatedAt )
        ]


type alias LoginResponse =
    { token : String
    , responseProfile : Maybe Profile
    }


jsonDecLoginResponse : Json.Decode.Decoder LoginResponse
jsonDecLoginResponse =
    Json.Decode.succeed LoginResponse
        |> required "token" Json.Decode.string
        |> fnullable "responseProfile" jsonDecProfile


jsonEncLoginResponse : LoginResponse -> Value
jsonEncLoginResponse val =
    Json.Encode.object
        [ ( "token", Json.Encode.string val.token )
        , ( "responseProfile", maybeEncode jsonEncProfile val.responseProfile )
        ]


getProfile : Maybe String -> (Result Http.Error Profile -> msg) -> Cmd msg
getProfile header_Authorization toMsg =
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
            List.filterMap identity
                [ Maybe.map (Http.header "Authorization") (bearerToken header_Authorization)
                ]
        , url =
            Url.Builder.crossOrigin "http://localhost:1337"
                [ "profile"
                ]
                params
        , body =
            Http.emptyBody
        , expect =
            Http.expectJson toMsg jsonDecProfile
        , timeout =
            Nothing
        , tracker =
            Nothing
        }


postRegister : Account -> (Result Http.Error LoginResponse -> msg) -> Cmd msg
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
            Url.Builder.crossOrigin "http://localhost:1337"
                [ "register"
                ]
                params
        , body =
            Http.jsonBody (jsonEncAccount body)
        , expect =
            Http.expectJson toMsg jsonDecLoginResponse
        , timeout =
            Nothing
        , tracker =
            Nothing
        }


postLogin : Account -> (Result Http.Error LoginResponse -> msg) -> Cmd msg
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
            Url.Builder.crossOrigin "http://localhost:1337"
                [ "login"
                ]
                params
        , body =
            Http.jsonBody (jsonEncAccount body)
        , expect =
            Http.expectJson toMsg jsonDecLoginResponse
        , timeout =
            Nothing
        , tracker =
            Nothing
        }
