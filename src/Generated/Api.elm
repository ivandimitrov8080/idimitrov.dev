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
    , accountEmail : String
    , accountPassword : String
    , accountProfile : Maybe Profile
    }


jsonDecAccount : Json.Decode.Decoder Account
jsonDecAccount =
    Json.Decode.succeed (\paccountId paccountEmail paccountPassword paccountProfile -> { accountId = paccountId, accountEmail = paccountEmail, accountPassword = paccountPassword, accountProfile = paccountProfile })
        |> fnullable "accountId" Json.Decode.int
        |> required "accountEmail" Json.Decode.string
        |> required "accountPassword" Json.Decode.string
        |> fnullable "accountProfile" jsonDecProfile


jsonEncAccount : Account -> Value
jsonEncAccount val =
    Json.Encode.object
        [ ( "accountId", maybeEncode Json.Encode.int val.accountId )
        , ( "accountEmail", Json.Encode.string val.accountEmail )
        , ( "accountPassword", Json.Encode.string val.accountPassword )
        , ( "accountProfile", maybeEncode jsonEncProfile val.accountProfile )
        ]


type alias Profile =
    { profileName : String
    , test : Bool
    }


jsonDecProfile : Json.Decode.Decoder Profile
jsonDecProfile =
    Json.Decode.succeed (\pprofileName ptest -> { profileName = pprofileName, test = ptest })
        |> required "profileName" Json.Decode.string
        |> required "test" Json.Decode.bool


jsonEncProfile : Profile -> Value
jsonEncProfile val =
    Json.Encode.object
        [ ( "profileName", Json.Encode.string val.profileName )
        , ( "test", Json.Encode.bool val.test )
        ]


type alias LoginResponse =
    { token : String
    , profile : Maybe Profile
    }


jsonDecLoginResponse : Json.Decode.Decoder LoginResponse
jsonDecLoginResponse =
    Json.Decode.succeed (\ptoken pprofile -> { token = ptoken, profile = pprofile })
        |> required "token" Json.Decode.string
        |> fnullable "profile" jsonDecProfile


jsonEncLoginResponse : LoginResponse -> Value
jsonEncLoginResponse val =
    Json.Encode.object
        [ ( "token", Json.Encode.string val.token )
        , ( "profile", maybeEncode jsonEncProfile val.profile )
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
                [ Maybe.map (Http.header "Authorization") header_Authorization
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
