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


type alias Account =
    { accountId : Maybe Int
    , accountName : String
    , accountPassword : String
    , accountProfile : Profile
    }


jsonDecAccount : Json.Decode.Decoder Account
jsonDecAccount =
    Json.Decode.succeed (\paccountId paccountName paccountPassword paccountProfile -> { accountId = paccountId, accountName = paccountName, accountPassword = paccountPassword, accountProfile = paccountProfile })
        |> fnullable "accountId" Json.Decode.int
        |> required "accountName" Json.Decode.string
        |> required "accountPassword" Json.Decode.string
        |> required "accountProfile" jsonDecProfile


jsonEncAccount : Account -> Value
jsonEncAccount val =
    Json.Encode.object
        [ ( "accountId", maybeEncode Json.Encode.int val.accountId )
        , ( "accountName", Json.Encode.string val.accountName )
        , ( "accountPassword", Json.Encode.string val.accountPassword )
        , ( "accountProfile", jsonEncProfile val.accountProfile )
        ]


type alias Profile =
    { profileName : String
    }


jsonDecProfile : Json.Decode.Decoder Profile
jsonDecProfile =
    Json.Decode.succeed (\pprofileName -> { profileName = pprofileName }) |> custom Json.Decode.string


jsonEncProfile : Profile -> Value
jsonEncProfile val =
    Json.Encode.string val.profileName


type alias LoginResponse =
    { token : String
    , profile : Profile
    }


jsonDecLoginResponse : Json.Decode.Decoder LoginResponse
jsonDecLoginResponse =
    Json.Decode.succeed (\ptoken pprofile -> { token = ptoken, profile = pprofile })
        |> required "token" Json.Decode.string
        |> required "profile" jsonDecProfile


jsonEncLoginResponse : LoginResponse -> Value
jsonEncLoginResponse val =
    Json.Encode.object
        [ ( "token", Json.Encode.string val.token )
        , ( "profile", jsonEncProfile val.profile )
        ]


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
