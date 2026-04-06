module Main exposing (main)

import Browser
import Generated.Api
    exposing
        ( Account
        , LoginResponse
        , Profile
        , clearToken
        , getProfile
        , onTokenLoaded
        , postLogin
        , postRegister
        , storeLoginToken
        )
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http exposing (Error(..))


type alias Flags =
    Maybe String


type alias Model =
    { errors : List Error
    , account : Account
    , token : Maybe String
    , profile : Maybe Profile
    }


type Msg
    = Register Account
    | Login Account
    | RegisterSuccess (Result Http.Error LoginResponse)
    | LoginSuccess (Result Http.Error LoginResponse)
    | FetchProfile (Result Http.Error Profile)
    | AccountNameChanged String
    | AccountPasswordChanged String
    | TokenLoaded (Maybe String)


main : Program Flags Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }


subscriptions : Model -> Sub Msg
subscriptions _ =
    onTokenLoaded TokenLoaded


init : Flags -> ( Model, Cmd Msg )
init maybeToken =
    ( { errors = []
      , account = Account Nothing "" "" Nothing
      , token = maybeToken
      , profile = Nothing
      }
    , case maybeToken of
        Just token ->
            getProfile (Just token) FetchProfile

        Nothing ->
            Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Register account ->
            ( model, postRegister account RegisterSuccess )

        RegisterSuccess result ->
            case result of
                Ok loginResponse ->
                    ( { model | token = Just loginResponse.token }
                    , Cmd.batch
                        [ storeLoginToken loginResponse
                        , getProfile (Just loginResponse.token) FetchProfile
                        ]
                    )

                Err err ->
                    ( { model | errors = model.errors ++ [ err ] }
                    , Cmd.none
                    )

        LoginSuccess result ->
            case result of
                Ok loginResponse ->
                    ( { model | token = Just loginResponse.token }
                    , Cmd.batch
                        [ storeLoginToken loginResponse
                        , getProfile (Just loginResponse.token) FetchProfile
                        ]
                    )

                Err err ->
                    ( { model | errors = model.errors ++ [ err ] }
                    , Cmd.none
                    )

        FetchProfile result ->
            case result of
                Ok profile ->
                    ( { model | profile = Just profile }
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

        TokenLoaded maybeToken ->
            case maybeToken of
                Just token ->
                    ( { model | token = Just token }
                    , getProfile (Just token) FetchProfile
                    )

                Nothing ->
                    ( { model | token = Nothing, profile = Nothing }
                    , clearToken ()
                    )


errorToString : Error -> String
errorToString e =
    case e of
        BadUrl u ->
            u

        Timeout ->
            ""

        NetworkError ->
            ""

        BadStatus i ->
            String.fromInt i

        BadBody m ->
            m


view : Model -> Html Msg
view model =
    div []
        [ div [] [ Html.text (Maybe.withDefault "" (Maybe.map .accountName (Just model.account))) ]
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
            , div [] [ span [] [ Html.text "Current profile name" ] ]
            , div []
                [ span []
                    [ case model.profile of
                        Just p ->
                            Html.text p.profileName

                        Nothing ->
                            Html.text ""
                    ]
                ]
            , div [] (List.map (\e -> span [] [ Html.text (errorToString e) ]) model.errors)
            ]
        ]
