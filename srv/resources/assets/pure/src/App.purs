module App (runApp) where

import Prelude

import Data.Maybe (Maybe (..))
import Data.Record.Builder (merge)

import Control.Monad.Eff (Eff)
import Control.Monad.Aff (liftEff')
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Ref (REF)
import Control.Monad.Eff.Exception.Unsafe (unsafeThrow)

import DOM (DOM)
import DOM.HTML (window) as DOM
import DOM.HTML.Window (document) as DOM
import DOM.HTML.Types (htmlDocumentToDocument) as DOM
import DOM.Node.NonElementParentNode (getElementById) as DOM

import DOM.Node.Types ( Element
                      , ElementId (ElementId)
                      , documentToNonElementParentNode
                      ) as DOM

import React (ReactClass, getProps, createElement)
import ReactDOM (render)
import React.DOM (div', h1', text)

import Utils (StoreConnectEff, storeConnect, createClassStatelessWithSpec)
import Router (Location (..), initRouter, navigateToRoute)
import Component.Spinner (spinner)

import App.Store ( AppContext
                 , AppState
                 , AppAction (..)
                 , createAppContext
                 , dispatch
                 , subscribe
                 )


appRender
  :: forall eff
   . ReactClass { location   :: Location
                , appContext :: AppContext (StoreConnectEff eff)
                }

appRender = createClassStatelessWithSpec specMiddleware $ \props -> div' $

  case props.location of
    {-- DiagTreeEditPartial -> --}
    _ -> [ h1' [text "Loading…"]
         , createElement spinner { appContext : props.appContext } []
         ]

  where
    specMiddleware = _
      { shouldComponentUpdate = \this nextProps _ ->
          getProps this <#> _.location <#> (_ /= nextProps.location)
      }


app
  :: forall eff
   . ReactClass { appContext :: AppContext (StoreConnectEff eff) }

app = storeConnect f appRender
  where
    f appState = merge { location: appState.currentLocation }


runApp
  :: forall eff
   . Eff ( StoreConnectEff ( console :: CONSOLE
                           , dom :: DOM
                           , ref :: REF
                           | eff
                           )
         ) Unit

runApp = do
  (appEl :: DOM.Element) <-
    DOM.window
    >>= DOM.document
    >>= DOM.getElementById (DOM.ElementId "app")
        <<< DOM.documentToNonElementParentNode
        <<< DOM.htmlDocumentToDocument
    >>= case _ of
             Nothing -> unsafeThrow "#app element not found"
             Just el -> pure el

  appCtx <- createAppContext storeReducer appInitialState
  initRouter $ dispatch appCtx <<< Navigate

  void $ subscribe appCtx $ const $ case _ of
    Navigate route -> liftEff' $ navigateToRoute route
    _              -> pure unit

  void $ render (createElement app { appContext: appCtx } []) appEl

  where

    appInitialState :: AppState
    appInitialState = { currentLocation: Empty
                      }

    storeReducer state (Navigate route) =
      if state.currentLocation /= route
         then Just $ state {currentLocation = route}
         else Nothing
