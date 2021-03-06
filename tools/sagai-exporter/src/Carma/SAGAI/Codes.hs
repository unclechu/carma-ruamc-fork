{-# LANGUAGE OverloadedStrings #-}

{-|

Expense types, codes and servicing costs.

These should not fall into wrong hands.

TODO Load sensitive data from external files.

-}


module Carma.SAGAI.Codes
    ( ExpenseType(..)
    , CodeRow(..)
    , codesData
    , rentCostsPSA
    , rentCosts
    )

where

import Data.ByteString as BS
import Data.Map as M

import Data.Model

import Carma.Model.CarClass
import Carma.Model.Program


data ExpenseType = Dossier
                 | FalseCall
                 | PhoneServ
                 | Charge
                 | Condition
                 | Starter
                 | Lights
                 | Towage
                 | RepTowage
                 | Rent
                   deriving (Eq, Ord, Show)


-- | Data for particular type of expense.
data CodeRow = CodeRow { cost             :: Double
                       , impCode          :: BS.ByteString
                       , serviceImpCode   :: BS.ByteString
                       , causeCode        :: BS.ByteString
                       , defCode          :: BS.ByteString
                       }


-- | List of costs and I/C/D codes for all programs and expenses.
--
-- Costs for Rent expenses are ignored (see 'rentCostsPSA' &
-- 'rentCosts' instead).
codesData :: M.Map (IdentI Program, ExpenseType) CodeRow
codesData = M.fromList
    [ ((citroen, Dossier),     CodeRow 1354.64 "DV1" "DV4" "9929" "G5F")
    , ((citroen, FalseCall),   CodeRow 677.32  "DR1" "DR4" "9943" "296")
    , ((citroen, PhoneServ),   CodeRow 414.18  "DV1" "DV4" "9939" "G5F")
    , ((citroen, Charge),      CodeRow 2153.5  "DR1" "DR4" "996L" "446")
    , ((citroen, Condition),   CodeRow 2153.5  "DR1" "DR4" "996D" "199")
    , ((citroen, Starter),     CodeRow 2153.5  "DR1" "DR4" "996A" "135")
    , ((citroen, Lights),      CodeRow 2153.5  "DR1" "DR4" "996M" "446")
    , ((citroen, Towage),      CodeRow 3434.98 "DR1" "DR4" "9934" "G5F")
    , ((citroen, RepTowage),   CodeRow 2370.62 "DR1" "DR4" "9936" "G5F")
    , ((citroen, Rent),        CodeRow 0       "PV1" "PV4" "9927" "PZD")
    , ((peugeot, Dossier),     CodeRow 1354.64 "24E" "FCA" "8999" "G5D")
    , ((peugeot, FalseCall),   CodeRow 677.32  "24E" "FCA" "8943" "G5D")
    , ((peugeot, PhoneServ),   CodeRow 414.18  "24E" "FCA" "8990" "G5D")
    , ((peugeot, Charge),      CodeRow 2153.5  "24E" "FCA" "8962" "G5D")
    , ((peugeot, Condition),   CodeRow 2153.5  "24E" "FCA" "8954" "G5D")
    , ((peugeot, Starter),     CodeRow 2153.5  "24E" "FCA" "8963" "G5D")
    , ((peugeot, Towage),      CodeRow 3434.98 "24E" "FCA" "8950" "G5D")
    , ((peugeot, RepTowage),   CodeRow 2370.62 "24E" "FCA" "8983" "G5D")
    , ((peugeot, Rent),        CodeRow 0       "24E" "FCA" "8997" "PZD")
    ]


-- | Daily costs for car rent service provided by PSA dealers.
--
-- Map key is a @(subprogram, carClass)@ tuple.
rentCostsPSA :: M.Map (IdentI Program, IdentI CarClass) Double
rentCostsPSA = M.fromList
    [ ((citroen, psab),  2040.22)
    , ((citroen, psam1), 2400.12)
    , ((citroen, psam2), 3360.64)
    , ((peugeot, psab),  2040.20)
    , ((peugeot, psam1), 2400.10)
    , ((peugeot, psam2), 3360.60)
    ]


-- | Daily costs for car rent service provided by third-party dealers.
rentCosts :: M.Map (IdentI Program, IdentI CarClass) Double
rentCosts = M.fromList
    [ ((citroen, psab),  2074.44)
    , ((citroen, psam1), 2725.80)
    , ((citroen, psam2), 3588.38)
    , ((citroen, psah),  4712.92)
    , ((peugeot, psab),  2074.44)
    , ((peugeot, psam1), 2725.80)
    , ((peugeot, psam2), 3588.38)
    , ((peugeot, psah),  4712.92)
    ]
