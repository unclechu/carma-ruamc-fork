
{-# LANGUAGE BangPatterns #-}
module ApplicationInit (appInit) where

import Control.Applicative
import Control.Monad.IO.Class

import qualified Data.Map as Map
import Data.ByteString (ByteString)
import Data.Configurator
import Control.Concurrent.STM

import System.Log(newLog, fileCfg, logger, text, file)

import Data.Pool
import Database.PostgreSQL.Simple as Pg

import Snap.Core
import Snap.Snaplet
import Snap.Snaplet.Heist
import Snap.Snaplet.Auth hiding (session)
import Snap.Snaplet.Auth.Backends.JsonFile
import Snap.Snaplet.Session.Backends.CookieSession
import Snap.Util.FileServe (serveDirectory, serveFile)
------------------------------------------------------------------------------
import Snap.Snaplet.Vin
import Snaplet.SiteConfig
import Snaplet.DbLayer
import Snaplet.FileUpload
import Snaplet.Geo
------------------------------------------------------------------------------
import Application
import ApplicationHandlers
import AppHandlers.ActionAssignment
import AppHandlers.CustomSearches
----------------------------------------------------------------------
import Util (readJSON, UsersDict(..))




------------------------------------------------------------------------------
-- | The application's routes.
routes :: [(ByteString, AppHandler ())]
routes = [ ("/",              method GET $ authOrLogin indexPage)
         , ("/login/",        method GET loginForm)
         , ("/login/",        method POST doLogin)
         , ("/logout/",       doLogout)
         , ("/nominatim",     method GET geodecode)
         , ("/s/",            serveDirectory "resources/static")
         , ("/s/screens",     serveFile "resources/site-config/screens.json")
         , ("/report",        chkAuth . method GET  $ report)
         , ("/all/:model",    chkAuth . method GET  $ readAllHandler)
         , ("/callsByPhone/:phone",
                              chkAuth . method GET    $ searchCallsByPhone)
         , ("/actionsFor/:id",chkAuth . method GET    $ getActionsForCase)
         , ("/myActions",     chkAuth . method GET    $ myActionsHandler)
         , ("/allActions",    chkAuth . method GET    $ allActionsHandler)
         , ("/allPartners",   chkAuth . method GET    $ allPartnersHandler)
         , ("/_whoami/",      chkAuth . method GET    $ serveUserCake)
         , ("/_/:model",      chkAuth . method POST   $ createHandler)
         , ("/_/:model/:id",  chkAuth . method GET    $ readHandler)
         , ("/_/:model/:id",  chkAuth . method PUT    $ updateHandler)
         , ("/_/:model/:id",  chkAuth . method DELETE $ deleteHandler)
         , ("/_/findOrCreate/:model/:id",
                              chkAuth . method POST $ findOrCreateHandler)
         , ("/_/report/",     chkAuth . method POST $ createReportHandler)
         , ("/_/report/:id",  chkAuth . method DELETE $ deleteReportHandler)
         , ("/search/:model", chkAuth . method GET  $ searchHandler)
         , ("/rkc",           chkAuth . method GET  $ rkcHandler)
         , ("/usersDict",     chkAuth . method GET  $ getUsersDict)
         , ("/activeUsers",   chkAuth . method GET  $ getActiveUsers)
         , ("/vin/upload",    chkAuth . method POST $ vinUploadData)
         , ("/vin/state",     chkAuth . method GET  $ vinStateRead)
         , ("/vin/state",     chkAuth . method POST $ vinStateRemove)
         , ("/opts/:model/:id/", chkAuth . method GET $ getSrvTarifOptions)
         , ("/smspost",       chkAuth . method POST $ smspost)
         , ("/sms/processing", chkAuth . method GET $ smsProcessingHandler)
         , ("/printSrv/:model/:id",
            chkAuth . method GET $ printServiceHandler)
         , ("/errors",        method POST errorsHandler)
         ]


------------------------------------------------------------------------------
-- | The application initializer.
appInit :: SnapletInit App App
appInit = makeSnaplet "app" "Forms application" Nothing $ do
  cfg <- getSnapletUserConfig

  h <- nestSnaplet "heist" heist $ heistInit "resources/templates"
  addAuthSplices auth

  sesKey <- liftIO $
            lookupDefault "resources/private/client_session_key.aes"
                          cfg "session-key"
  rmbKey <- liftIO $
            lookupDefault "resources/private/site_key.txt"
                          cfg "remember-key"
  rmbPer <- liftIO $
            lookupDefault 14
                          cfg "remember-period"
  authDb <- liftIO $
            lookupDefault "resources/private/users.json"
                          cfg "user-db"

  s <- nestSnaplet "session" session $
       initCookieSessionManager sesKey "_session" Nothing
  authMgr <- nestSnaplet "auth" auth $
       initJsonFileAuthManager
       defAuthSettings{ asSiteKey = rmbKey
                      , asRememberPeriod = Just (rmbPer * 24 * 60 * 60)}
                               session authDb
  logdUsrs <- liftIO $ newTVarIO Map.empty
  !allUsrs <- liftIO $ readJSON authDb

  c <- nestSnaplet "cfg" siteConfig $ initSiteConfig "resources/site-config"

  d <- nestSnaplet "db" db $ initDbLayer allUsrs "resources/site-config"
 
  -- init PostgreSQL connection pool that will be used for searching only
  let lookupCfg nm = lookupDefault (error $ show nm) cfg nm
  cInfo <- liftIO $ Pg.ConnectInfo
            <$> lookupCfg "pg_host"
            <*> lookupCfg "pg_port"
            <*> lookupCfg "pg_search_user"
            <*> lookupCfg "pg_search_pass"
            <*> lookupCfg "pg_db_name"
  -- FIXME: force cInfo evaluation
  pgs <- liftIO $ createPool (Pg.connect cInfo) Pg.close 1 5 20
  cInfo <- liftIO $ (\u p -> cInfo {connectUser = u, connectPassword = p})
            <$> lookupCfg "pg_actass_user"
            <*> lookupCfg "pg_actass_pass"
  pga <- liftIO $ createPool (Pg.connect cInfo) Pg.close 1 5 20

  v <- nestSnaplet "vin" vin vinInit
  fu <- nestSnaplet "upload" fileUpload fileUploadInit
  g <- nestSnaplet "geo" geo geoInit

  l <- liftIO $ newLog (fileCfg "resources/site-config/db-log.cfg" 10)
       [logger text (file "log/frontend.log")]

  addRoutes routes
  return $ App h s authMgr logdUsrs allUsrs c d pgs pga v fu g l
