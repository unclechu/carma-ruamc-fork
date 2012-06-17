
module Snaplet.DbLayer.Triggers
  (triggerUpdate
  ,triggerCreate
  ) where

import Control.Monad (foldM)
import Control.Monad.Trans
import Control.Monad.Trans.State

import Data.Map (Map)
import qualified Data.Map as Map
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B

import Snap.Snaplet (Handler(..))
import Snaplet.DbLayer.Types
import Snaplet.DbLayer.Triggers.Types
import Snaplet.DbLayer.Triggers.Defaults



triggerCreate :: ModelName -> Object -> DbHandler b Object
triggerCreate model obj = return
  $ Map.findWithDefault Map.empty model defaults

triggerUpdate :: ObjectId -> Object -> DbHandler b ObjectMap
triggerUpdate objId commit = return $ Map.singleton objId Map.empty
--  = loop 5 emptyContext $ Map.singleton objId commit
  where
    cfg = Map.empty
    loop 0 cxt changes = return $ unionMaps changes $ updates cxt
    loop n cxt changes
      | Map.null changes = return $ updates cxt
      | otherwise = do
        let tgs = matchingTriggers cfg changes
        let cxt' = cxt
              {updates = unionMaps changes $ updates cxt
              ,current = Map.empty
              }
        cxt'' <- foldM (flip execStateT) cxt' tgs
        loop (n-1) cxt'' $ current cxt''


unionMaps :: ObjectMap -> ObjectMap -> ObjectMap
unionMaps = Map.unionWith Map.union

matchingTriggers :: TriggerMap b -> ObjectMap -> [TriggerMonad b]
matchingTriggers cfg updates
  = concatMap triggerModels $ Map.toList updates
  where
    triggerModels (objId, obj)
      = concat $ Map.elems
      $ Map.intersectionWith applyTriggers modelTriggers obj
      where
        model = fst $ B.break (==':') objId
        modelTriggers = Map.findWithDefault Map.empty model cfg
        applyTriggers tgs val = map (\t -> t objId val) tgs