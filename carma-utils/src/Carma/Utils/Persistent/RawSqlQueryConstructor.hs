{-# LANGUAGE RankNTypes, ScopedTypeVariables, ExistentialQuantification #-}
{-# LANGUAGE KindSignatures, DataKinds, GADTs, ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts, UndecidableInstances, TypeApplications #-}
{-# LANGUAGE QuasiQuotes, OverloadedStrings, LambdaCase #-}

-- | Helper to build kinda interpolated relatively safe RAW SQL.
--
-- By \"interpolated" it means that you use values and other dynamic stuff
-- inplace, instead of adding placeholders and providing a value apart in a
-- list.
--
-- See also "Carma.Monad.Esqueleto.MonadRawEsqueleto", you're supposed to use
-- this builder of raw SQL queries inside such a monad.
module Carma.Utils.Persistent.RawSqlQueryConstructor
     ( RawSqlPiece (..)
     , RawPieceConstraint
     , RawValueConstraint

     , TableAliasToken
     , mkTableAliasToken
     , tableAliasTokenAliasProxy

     , TableAliasFieldToken
     , mkTableAliasFieldToken
     , tableAliasFieldTokenAliasProxy

     , AliasByTableAliasToken (..)

     , buildRawSql

     , getTableByItsField

     , RawFieldConstructor (..)
     , RawFieldValueConstructor (..)

     , RawBasic (..), raw
     , RawBasicJoin (..)
     , RawBasicType (..), toRawSqlType
     , RawAliasAs' (..)

     , rawSelect
     , rawSelectDistinct
     , rawSelectDistinctOn
     , rawWith
     , rawSelectAlias
     , rawIntersected
     , rawSeq
     , rawSome
     , rawAll

     , rawLimitTo
     , rawOffsetBy
     , rawPaging

     , OrderBy (..)
     , rawOrderBy

     , rawEqual,           rawEqual',          rawEqualField
     , rawNotEqual,        rawNotEqual',       rawNotEqualField
     , rawGreater,         rawGreater',        rawGreaterField
     , rawGreaterOrEqual,  rawGreaterOrEqual', rawGreaterOrEqualField
     , rawLess,            rawLess',           rawLessField
     , rawLessOrEqual,     rawLessOrEqual',    rawLessOrEqualField

     , rawIsNull,  rawIsNotNull
     , rawIsNull', rawIsNotNull'
     , rawIn,      rawNotIn

     , rawCount
     , rawCoalesce
     , rawNullIf
     , rawBranching
     , rawConcat
     , rawLength
     , rawCast
     , rawNow

     , rawMatchRegex,    rawMatchRegex'
     , rawNotMatchRegex, rawNotMatchRegex'
     ) where

import           GHC.TypeLits

import           Data.Proxy
import           Data.Typeable
import           Data.Functor.Identity
import qualified Data.Vector as V
import           Data.String (IsString (fromString))
import           Data.Text (Text)
import           Text.InterpolatedString.QM

import           Database.Persist

import           Carma.Utils.Operators
import           Carma.Utils.Cons


------------------------------------------------------------------------------
-- Main types and instances
------------------------------------------------------------------------------


type RawPieceConstraint f =
   ( Functor f
   , Foldable f
   , Applicative f
   , Cons' f (RawSqlPiece f)
   , Show (f (RawSqlPiece f))
   , Eq (f (RawSqlPiece f))
   )

type RawValueConstraint fieldType =
   ( PersistField fieldType
   , Typeable fieldType
   , Show fieldType
   )

-- | General structure of a piece of raw SQL query.
data RawSqlPiece (f :: * -> *)
   = RawPlain Text
   -- ^ A piece of plain SQL text

   | forall model
   . PersistEntity model
   => RawTable (Proxy model)
   -- ^ Table name

   | forall model fieldType
   . (PersistEntity model, RawValueConstraint fieldType)
   => RawField (EntityField model fieldType)
   -- ^ Field name in context of table name

   | forall a
   . RawValueConstraint a
   => RawValue a
   -- ^ An interpolated value

   | forall model fieldType
   . (PersistEntity model, RawValueConstraint fieldType)
   => RawFieldValue (EntityField model fieldType) fieldType
   -- ^ A proven table field interpolated value
   --   (proven type of that value by provided field).

   | forall m alias fieldType
   . (PersistEntity m, KnownSymbol alias, RawValueConstraint fieldType)
   => RawTableAliasFieldValue (TableAliasFieldToken m alias fieldType) fieldType
   -- ^ A proven table field interpolated value in context of alias
   --   (proven type of that value by provided field).

   | forall model alias
   . (PersistEntity model, KnownSymbol alias)
   => RawTableAlias (TableAliasToken model alias)
   -- ^ Declare a table name with some alias to it
   --   ("AS" and then alias name, usual for "FROM"-statement).

   | forall model alias fieldType
   . (PersistEntity model, KnownSymbol alias, RawValueConstraint fieldType)
   => RawTableAliasField (TableAliasFieldToken model alias fieldType)
   -- ^ Field in context of table alias.

   | forall alias
   . (KnownSymbol alias, Show (f (RawSqlPiece f)), Eq (f (RawSqlPiece f)))
   => RawAliasAs (Proxy alias) (f (RawSqlPiece f))
   -- ^ Declare a table name with some alias to it in @WITH@-statement form
   --   (alias name first then "AS").
   --
   -- @[RawSqlPiece]@ are innards of this @WITH@ alias.

   | forall alias
   . KnownSymbol alias
   => RawAlias (Proxy alias)
   -- ^ Just print alias name.

   | forall alias
   . KnownSymbol alias
   => RawAliasedName (Proxy alias) Text
   -- ^ Declare name which is requested from provided alias.
   --
   -- Useful to call something defined in @WITH@-statement.
   -- To call something from a table please use "RawTableAliasField".

   | (Show (f (RawSqlPiece f)), Eq (f (RawSqlPiece f)))
   => RawWrap (f (RawSqlPiece f))
   -- ^ To wrap something into parenthesis

   | (Show (f (RawSqlPiece f)), Eq (f (RawSqlPiece f)))
   => RawWrap' (Text, Text) (f (RawSqlPiece f))
   -- ^ Like "RawWrap" but with custom open and close wrapping symbols.

-- | Token to share between defining a table and requesting it
--   or something from it.
data TableAliasToken (model :: *) (alias :: Symbol) = TableAliasToken

-- | Token to share between defining a field and a value for/of it
--   (or to compare with that field).
--
-- It helps to make sure you compare a field with the same type.
newtype TableAliasFieldToken (model :: *) (alias :: Symbol) (fieldType :: *)
      = TableAliasFieldToken (EntityField model fieldType)

instance Eq (f (RawSqlPiece f)) => Eq (RawSqlPiece f) where
  RawPlain x == RawPlain y = x == y
  RawPlain _ == _ = False

  RawTable                x == RawTable              y =
    entityDefByModelProxy x == entityDefByModelProxy y

  RawTable _ == _ = False

  RawField             x == RawField         y =
    entityDefByField x   == entityDefByField y &&
    persistFieldDef    x == persistFieldDef  y

  RawField _ == _ = False

  -- Equality of database value representation
  RawValue         x == RawValue       y =
    toPersistValue x == toPersistValue y

  RawValue _ == _ = False

  -- Equality of database value representation
  RawFieldValue      x y == RawFieldValue   a b =
    persistFieldDef  x   == persistFieldDef a    &&
    toPersistValue     y == toPersistValue    b

  RawFieldValue _ _ == _ = False

  RawTableAliasFieldValue          x y == RawTableAliasFieldValue        a b =
    entityDefByTableAliasToken     x   == entityDefByTableAliasToken     a   &&
    aliasByTableAliasToken'        x   == aliasByTableAliasToken'        a   &&
    fieldDefByTableAliasFieldToken x   == fieldDefByTableAliasFieldToken a   &&
    toPersistValue                   y == toPersistValue                   b

  RawTableAliasFieldValue _ _ == _ = False

  RawTableAlias                x == RawTableAlias              y =
    entityDefByTableAliasToken x == entityDefByTableAliasToken y &&
    aliasByTableAliasToken'    x == aliasByTableAliasToken'    y

  RawTableAlias _ == _ = False

  RawTableAliasField               x == RawTableAliasField             y =
    entityDefByTableAliasToken     x == entityDefByTableAliasToken     y &&
    aliasByTableAliasToken'        x == aliasByTableAliasToken'        y &&
    fieldDefByTableAliasFieldToken x == fieldDefByTableAliasFieldToken y

  RawTableAliasField _ == _ = False

  RawAliasAs  x y == RawAliasAs a b =
    symbolVal x   == symbolVal  a   &&
                y ==              b

  RawAliasAs _ _ == _ = False

  RawAlias x == RawAlias y = symbolVal x == symbolVal y
  RawAlias _ == _ = False

  RawAliasedName x y == RawAliasedName a b =
    symbolVal    x   == symbolVal      a   &&
                   y ==                  b

  RawAliasedName _ _ == _ = False

  RawWrap x == RawWrap y = x == y
  RawWrap _ == _ = False

  RawWrap' x y == RawWrap' a b = x == a && y == b
  RawWrap' _ _ == _ = False

instance Show (f (RawSqlPiece f)) => Show (RawSqlPiece f) where
  show (RawPlain x) = [qm| RawPlain {show x} |]

  show (RawTable x) = go where
    model = entityDefByModelProxy x

    go = [qm|
      RawTable (
        model name: "{unHaskellName $ entityHaskell model}", \
        table name (as in database): "{unDBName $ entityDB model}"
      )
    |]

  show (RawField x) = go where
    model = entityDefByField x
    field = persistFieldDef  x

    go = [qm|
      RawField (
        model name: "{unHaskellName $ entityHaskell model}", \
        table name (as in database): "{unDBName $ entityDB model}", \
        field name: "{unHaskellName $ fieldHaskell field}", \
        field name (as in database): "{unDBName $ fieldDB field}"
      )
    |]

  show (RawValue x) = [qm| RawValue ({show x}) |]

  show (RawFieldValue x y) = go where
    model = entityDefByField x
    field = persistFieldDef  x

    go = [qm|
      RawFieldValue (
        model name: "{unHaskellName $ entityHaskell model}", \
        table name (as in database): "{unDBName $ entityDB model}", \
        field name: "{unHaskellName $ fieldHaskell field}", \
        field name (as in database): "{unDBName $ fieldDB field}", \
        value: {show y}
      )
    |]

  show (RawTableAliasFieldValue x y) = go where
    model = entityDefByTableAliasToken     x
    field = fieldDefByTableAliasFieldToken x

    go = [qm|
      RawTableAliasFieldValue (
        model name: "{unHaskellName $ entityHaskell model}", \
        table name (as in database): "{unDBName $ entityDB model}", \
        table alias: "{aliasByTableAliasToken' x}", \
        field name: "{unHaskellName $ fieldHaskell field}", \
        field name (as in database): "{unDBName $ fieldDB field}", \
        value: {show y}
      )
    |]

  show (RawTableAlias x) = go where
    model = entityDefByTableAliasToken x

    go = [qm|
      RawTableAlias (
        model name: "{unHaskellName $ entityHaskell model}", \
        table name (as in database): "{unDBName $ entityDB model}", \
        table alias: "{aliasByTableAliasToken' x}"
      )
    |]

  show (RawTableAliasField x) = go where
    model = entityDefByTableAliasToken     x
    field = fieldDefByTableAliasFieldToken x

    go = [qm|
      RawTableAliasField (
        model name: "{unHaskellName $ entityHaskell model}", \
        table name (as in database): "{unDBName $ entityDB model}", \
        table alias: "{aliasByTableAliasToken' x}",
        field name: "{unHaskellName $ fieldHaskell field}", \
        field name (as in database): "{unDBName $ fieldDB field}"
      )
    |]

  show (RawAliasAs x y) = [qm|
    RawAliasAs (alias: "{symbolVal x}", innards: {y})
  |]

  show (RawAlias x) = [qm| RawAlias "{symbolVal x}" |]

  show (RawAliasedName x y) = [qm|
    RawAliasedName (alias: "{symbolVal x}", name: "{y}")
  |]

  show (RawWrap x) = [qm| RawWrap ({x}) |]
  show (RawWrap' (x, y) z) = [qm| RawWrap' ("{x}", "{y}") ({z}) |]


------------------------------------------------------------------------------
-- Builder of an SQL request
------------------------------------------------------------------------------


newtype DefinedTableAlias   = DefinedTableAlias   String deriving (Eq, Show)
newtype RequestedTableAlias = RequestedTableAlias String deriving (Eq, Show)
newtype DefinedWithAlias    = DefinedWithAlias    String deriving (Eq, Show)
newtype RequestedWithAlias  = RequestedWithAlias  String deriving (Eq, Show)

-- | For validation.
type AliasesAccumulator =
   ( V.Vector DefinedTableAlias
   , V.Vector RequestedTableAlias
   , V.Vector DefinedWithAlias
   , V.Vector RequestedWithAlias
   )


-- | Constructor of a raw SQL request.
--
-- Usage example:
--
-- @
-- result <-
--   let
--     inferTypes
--       :: forall model a b c x
--        . x ~ (Single a, Single b, Single c)
--       => Proxy model
--       -> EntityField model a
--       -> EntityField model b
--       -> EntityField model c
--       -> ReaderT SqlBackend m [x]
--       -> ReaderT SqlBackend m [x]
--
--     inferTypes Proxy _ _ _ = id
--
--     contract      = Proxy :: Proxy Contract
--     idField       = ContractId
--     vinField      = ContractVin
--     isActiveField = ContractIsActive
--   in
--     inferTypes contract idField vinField isActiveField
--       $ uncurry rawEsqueletoSql
--       $ buildRawSql
--       [ rawSelect
--           [ RawField idField
--           , RawField vinField
--           , RawField isActiveField
--           ]
--       , raw FROM
--       ,   getTableByItsField idField
--       , raw WHERE
--       ,   rawAll
--             [ isActiveField `rawEqual` True
--             , rawIsNotNull vinField
--             , vinField `rawNotEqual` Just ""
--             ]
--       , rawOrderBy [Ascending vinField, Descending idField]
--       , rawLimitTo 10
--       ]
-- @
buildRawSql
  :: forall f. Foldable f
  => f (RawSqlPiece f)
  -> (Text, [PersistValue])

buildRawSql = x where
  x = foldl pieceReducer ((mempty, mempty, mempty, mempty), mempty, mempty)
    ? \(aliases, sql, values) -> validate aliases `seq` (sql, V.toList values)

  pieceReducer
    :: (AliasesAccumulator, Text, V.Vector PersistValue)
    -> RawSqlPiece f
    -> (AliasesAccumulator, Text, V.Vector PersistValue)

  pieceReducer (aliases, sql, values) (RawPlain plain) =
    (aliases, [qm| {sql}{plain} |], values)

  pieceReducer (aliases, sql, values) (RawTable p@Proxy) = go where
    go = (aliases, [qm| {sql}{show tableDBName} |], values)
    tableDBName = unDBName $ entityDB $ entityDefByModelProxy p

  pieceReducer (aliases, sql, values) (RawField field) = go where
    go = (aliases, [qm| {sql}{show tableDBName}.{show fieldDBName} |], values)
    tableDBName = unDBName $ entityDB $ entityDefByField field
    fieldDBName = unDBName $ fieldDB $ persistFieldDef field

  pieceReducer (aliases, sql, values) (RawValue value) =
    (aliases, [qm| {sql}? |], values `V.snoc` toPersistValue value)

  pieceReducer (aliases, sql, values) (RawFieldValue _ value) =
    (aliases, [qm| {sql}? |], values `V.snoc` toPersistValue value)

  pieceReducer (aliases, sql, values) (RawTableAliasFieldValue t v) = go where
    go = (newAliases, [qm| {sql}? |], values `V.snoc` toPersistValue v)
    alias = RequestedTableAlias $ aliasByTableAliasToken t

    -- | I'm not sure whether we should add requested alias to the accumulator
    --   since we don't really use it here.
    newAliases = case aliases of (a, b, c, d) -> (a, b `V.snoc` alias, c, d)

  pieceReducer (aliases, sql, values) (RawTableAlias token) = go where
    go = (newAliases, [qm| {sql}{show tableDBName} AS {show alias} |], values)
    newAliases = case aliases of (a, b, c, d) -> (a `V.snoc` alias', b, c, d)
    tableDBName = unDBName $ entityDB entity
    entity = entityDefByTableAliasToken token
    alias = aliasByTableAliasToken token
    alias' = DefinedTableAlias alias

  pieceReducer (aliases, sql, values) (RawTableAliasField token) = go where
    go = (newAliases, [qm| {sql}{show alias}.{show fieldDBName} |], values)
    newAliases = case aliases of (a, b, c, d) -> (a, b `V.snoc` alias', c, d)
    fieldDBName = unDBName $ fieldDB field
    field = fieldDefByTableAliasFieldToken token
    alias = aliasByTableAliasToken token
    alias' = RequestedTableAlias alias

  pieceReducer (aliases, sql, values) (RawAliasAs as@Proxy children) = go where
    go = (newAliases, [qm| {sql}{show alias} AS ({childrenPlain}) |], newValues)
    newValues = values `mappend` childrenValues
    alias' = DefinedWithAlias alias
    alias = symbolVal as

    newAliases =
      case (aliases, childrenAliases) of
           ((a, b, c, d), (b', d')) ->
             ( a
             , b `mappend` b'
             , c `V.snoc` alias'
             , d `mappend` d'
             )

    childrenInitAcc = case aliases of (a, _, c, _) -> (a, mempty, c, mempty)

    (childrenAliases, childrenPlain, childrenValues)
      = foldl pieceReducer (childrenInitAcc, mempty, mempty) children
      & \(aliases'@(_, b, _, d), sql', values') ->
          validate aliases' `seq` ((b, d), sql', values')

  pieceReducer (aliases, sql, values) (RawAlias as@Proxy) = go where
    go = (newAliases, [qm| {sql}{show alias} |], values)
    newAliases = case aliases of (a, b, c, d) -> (a, b, c, d `V.snoc` alias')
    alias' = RequestedWithAlias alias
    alias = symbolVal as

  pieceReducer (aliases, sql, values) (RawAliasedName as@Proxy n) = go where
    go = (newAliases, [qm| {sql}{show alias}.{show n} |], values)
    newAliases = case aliases of (a, b, c, d) -> (a, b, c, d `V.snoc` alias')
    alias' = RequestedWithAlias alias
    alias = symbolVal as

  pieceReducer (aliases, sql, values) (RawWrap children) = go where
    go = (newAliases, [qm| {sql}({childrenPlain}) |], newValues)
    newValues = values `mappend` childrenValues

    (newAliases, childrenPlain, childrenValues)
      = foldl pieceReducer (aliases, mempty, mempty) children
      & \result@(aliases', _, _) -> validate aliases' `seq` result

  pieceReducer (aliases, sql, values) (RawWrap' (l, r) children) = go where
    go = (newAliases, [qm| {sql}{l}{childrenPlain}{r} |], newValues)
    newValues = values `mappend` childrenValues

    (newAliases, childrenPlain, childrenValues)
      = foldl pieceReducer (aliases, mempty, mempty) children
      & \result@(aliases', _, _) -> validate aliases' `seq` result

  -- | TODO implement
  --
  -- TODO check that all contextual aliased names are have their aliases
  --      defined, keep in mind that an alias can be defined after it's being
  --      used.
  --
  -- TODO "RawAliasAs" shouldn't export any aliases to upper level except only
  --      the alias of itself (first @Proxy@ parameter of constructor).
  --
  -- TODO "RawAliasAs" should inherit defined aliases from upper level.
  --      It might be tricky since names from upper level may be defined after
  --      they are being used.
  --
  -- TODO check that all aliases have unique name, do not allow to declare alias
  --      with the same name more than once.
  --      It might be tricky to check such name duplicated inside children of
  --      "RawAliasAs".
  --
  -- This validator wouldn't give you total runtime proof but can cover most of
  -- the typical errors caused by a human.
  --
  -- It should just end with "error" function with some proper error message in
  -- case of failure of validation.
  validate :: AliasesAccumulator -> ()
  validate (_, _, _, _) = ()


------------------------------------------------------------------------------
-- Safe constructors of alias tokens
------------------------------------------------------------------------------


-- | Make a token of a table with an alias name which can be used both for
--   defining such a table name (with @AS@ alias) or requesting that table by
--   its alias name.
--
-- Better to use it with @TypeApplications@ extension.
--
-- Usage example:
--
-- @
-- mkTableAliasToken @Contract @"c"
-- @
mkTableAliasToken
  :: (PersistEntity model, KnownSymbol alias)
  => TableAliasToken model alias

mkTableAliasToken = TableAliasToken


tableAliasTokenAliasProxy
  :: forall model alias. (PersistEntity model, KnownSymbol alias)
  => TableAliasToken model alias
  -> Proxy alias

tableAliasTokenAliasProxy TableAliasToken = Proxy


-- | Makes a field token of a table with an alias name.
--
-- Useful for accessing a field of a table by table's alias name.
--
-- Usage example:
--
-- @
-- let contractT = mkTableAliasToken @Contract @"c"
-- let vinFieldT = mkTableAliasFieldToken contractT ContractVin
-- @
mkTableAliasFieldToken
  :: (PersistEntity model, KnownSymbol alias, RawValueConstraint fieldType)
  => TableAliasToken model alias
  -> EntityField model fieldType
  -> TableAliasFieldToken model alias fieldType

mkTableAliasFieldToken TableAliasToken = TableAliasFieldToken


tableAliasFieldTokenAliasProxy
  :: (PersistEntity model, KnownSymbol alias, RawValueConstraint fieldType)
  => TableAliasFieldToken model alias fieldType
  -> Proxy alias

tableAliasFieldTokenAliasProxy (TableAliasFieldToken _) = Proxy


------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------


-- | Extracts "EntityDef" of a model by its field.
--
-- @fieldType@ doesn't matter here.
entityDefByField
  :: forall model fieldType. (PersistEntity model, RawValueConstraint fieldType)
  => EntityField model fieldType
  -> EntityDef

entityDefByField _ = entityDef (pure undefined :: Identity model)


-- | Extracts "EntityDef" of a model provided as a type wrapped in @Proxy@.
entityDefByModelProxy
  :: forall model. PersistEntity model
  => Proxy model
  -> EntityDef

entityDefByModelProxy Proxy = entityDef (pure undefined :: Identity model)


-- | Polymorphic helper to extract "EntityDef" from an alias token.
class EntityDefByTableAliasToken t where
  entityDefByTableAliasToken :: t -> EntityDef

instance ( PersistEntity model
         , KnownSymbol alias
         ) => EntityDefByTableAliasToken (TableAliasToken model alias) where

  entityDefByTableAliasToken TableAliasToken =
    entityDef (pure undefined :: Identity model)

instance ( PersistEntity model
         , KnownSymbol alias
         , RawValueConstraint fieldType
         ) => EntityDefByTableAliasToken
         ( TableAliasFieldToken model alias fieldType
         ) where

  entityDefByTableAliasToken (TableAliasFieldToken _) =
    entityDef (pure undefined :: Identity model)


-- | Polymorphic helper to extract alias name
--   as a term-level string from an alias token.
class AliasByTableAliasToken t where
  aliasByTableAliasToken :: IsString s => t -> s

instance ( PersistEntity model
         , KnownSymbol alias
         ) => AliasByTableAliasToken (TableAliasToken model alias) where

  aliasByTableAliasToken TableAliasToken = fromString $ symbolVal $ Proxy @alias

instance ( PersistEntity model
         , KnownSymbol alias
         , RawValueConstraint fieldType
         ) => AliasByTableAliasToken
         ( TableAliasFieldToken model alias fieldType
         ) where

  aliasByTableAliasToken (TableAliasFieldToken _) =
    fromString $ symbolVal $ Proxy @alias


-- | "aliasByTableAliasToken" bounded to "String".
aliasByTableAliasToken' :: AliasByTableAliasToken t => t -> String
aliasByTableAliasToken' = aliasByTableAliasToken


-- | Extracts "FieldDef" from a field of a model provided by
--   "TableAliasFieldToken".
fieldDefByTableAliasFieldToken
  :: (PersistEntity model, KnownSymbol alias, RawValueConstraint fieldType)
  => TableAliasFieldToken model alias fieldType
  -> FieldDef

fieldDefByTableAliasFieldToken (TableAliasFieldToken x) = persistFieldDef x


-- | Gets a field and returns "RawSqlPiece" of its model table.
--
-- Helps to avoid cases when requested model differs from the model of fields,
-- it's kinda like an additional type-level protection.
getTableByItsField
  :: forall model fieldType f
   . (PersistEntity model, RawValueConstraint fieldType, RawPieceConstraint f)
  => EntityField model fieldType
  -> RawSqlPiece f

getTableByItsField _ = RawTable (Proxy :: Proxy model)


-- | Polymorphic between "RawField" and "RawTableAliasField".
class RawFieldConstructor field where
  rawFieldConstructor :: field -> RawSqlPiece f

instance ( PersistEntity model
         , RawValueConstraint fieldType
         ) => RawFieldConstructor (EntityField model fieldType) where

  rawFieldConstructor = RawField

instance ( PersistEntity model
         , KnownSymbol alias
         , RawValueConstraint fieldType
         ) => RawFieldConstructor
         ( TableAliasFieldToken model alias fieldType
         ) where

  rawFieldConstructor = RawTableAliasField


-- | Polymorphic between "RawFieldValue" and "RawTableAliasFieldValue".
class RawFieldValueConstructor t where
  rawFieldValueConstructor :: RawValueConstraint v => t v -> v -> RawSqlPiece f

instance PersistEntity m => RawFieldValueConstructor (EntityField m) where
  rawFieldValueConstructor = RawFieldValue

instance ( PersistEntity model
         , KnownSymbol alias
         ) => RawFieldValueConstructor (TableAliasFieldToken model alias) where

  rawFieldValueConstructor = RawTableAliasFieldValue


-- | Predefined basic raw SQL words.
--
-- By using these with "raw" you'd avoid typos which tend to appear when writing
-- raw SQL queries.
data RawBasic
   = INSERT_INTO | SELECT | SELECT_DISTINCT | UPDATE | DELETE_FROM
   | FROM | JOIN RawBasicJoin | WHERE | ORDER_BY | ASC | DESC | LIMIT | OFFSET
   | SET | DEFAULT | RETURNING | VALUES | USING | WITH
   | AND | OR | STAR | COMMA | SEMICOLON | EQUAL | NOT_EQUAL | GREATER
   | GREATER_OR_EQUAL | LESS | LESS_OR_EQUAL | NOT | NULL | AS | IS | IN | ON
   | BETWEEN | LIKE Bool -- ^ @Bool@ indicates whether it's case-sensitive
   | CASE | WHEN | THEN | ELSE | END
     deriving (Eq, Show)

-- | To specify which kind of @JOIN@ it is.
data RawBasicJoin
   = INNER -- ^ Returns records that have matching values in both tables.

   | LEFT  -- ^ Returns all records from the left table,
           --   and the matched records from the right table.

   | RIGHT -- ^ Returns all records from the right table,
           --   and the matched records from the left table.

   | FULL  -- ^ Returns all records when there is a match in either
           --   left or right table.

     deriving (Eq, Show)


rawBasicSql :: RawBasic -> Text
rawBasicSql = \case
  INSERT_INTO      -> "INSERT INTO"
  SELECT           -> "SELECT"
  UPDATE           -> "UPDATE"
  DELETE_FROM      -> "DELETE FROM"
  FROM             -> "FROM"
  JOIN INNER       -> "INNER JOIN"
  JOIN LEFT        -> "LEFT OUTER JOIN"
  JOIN RIGHT       -> "RIGHT OUTER JOIN"
  JOIN FULL        -> "FULL OUTER JOIN"
  WHERE            -> "WHERE"
  ORDER_BY         -> "ORDER BY"
  ASC              -> "ASC"
  DESC             -> "DESC"
  LIMIT            -> "LIMIT"
  OFFSET           -> "OFFSET"
  SELECT_DISTINCT  -> rawBasicSql SELECT `mappend` " DISTINCT"
  SET              -> "SET"
  DEFAULT          -> "DEFAULT"
  RETURNING        -> "RETURNING"
  VALUES           -> "VALUES"
  USING            -> "USING"
  WITH             -> "WITH"
  AND              -> "AND"
  OR               -> "OR"
  STAR             -> "*"
  COMMA            -> ","
  SEMICOLON        -> ";"
  EQUAL            -> "="
  NOT_EQUAL        -> "<>"
  GREATER          -> ">"
  GREATER_OR_EQUAL -> ">="
  LESS             -> "<"
  LESS_OR_EQUAL    -> "<="
  NOT              -> "NOT"
  NULL             -> "NULL"
  AS               -> "AS"
  IS               -> "IS"
  IN               -> "IN"
  ON               -> "ON"
  BETWEEN          -> "BETWEEN"
  LIKE True        -> "LIKE"
  LIKE False       -> "ILIKE"
  CASE             -> "CASE"
  WHEN             -> "WHEN"
  THEN             -> "THEN"
  ELSE             -> "ELSE"
  END              -> "END"


-- | Transforms predefined "RawBasic" word into raw SQL text as "RawSqlPiece".
raw :: Foldable f => RawBasic -> RawSqlPiece f
raw = RawPlain . (\x -> " " `mappend` x `mappend` " ") . rawBasicSql


-- | Selects some values (just values, fields, etc.)
--
-- @
-- rawSelect [RawField ContractId, RawField ContractVin]
-- @
--
-- Equals to:
--
-- @
-- RawWrap' mempty
--   [ raw SELECT
--   ,   rawSeq [RawField ContractId, RawField ContractVin]
--   ]
-- @
--
-- Or in a list of "buildRawSql":
--
-- @
-- [ raw SELECT
-- ,   rawSeq [RawField ContractId, RawField ContractVin]
-- , ...
-- ]
-- @
rawSelect
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawSelect x = RawWrap' mempty $ raw SELECT <| pure (rawSeq x)


-- | See description of "rawSelect".
--
-- @
-- rawSelectDistinct [RawField ContractId, RawField ContractVin]
-- @
--
-- Equals to:
--
-- @
-- RawWrap' mempty
--   [ raw SELECT_DISTINCT
--   ,   rawSeq [RawField ContractId, RawField ContractVin]
--   ]
-- @
--
-- Or in a list of "buildRawSql":
--
-- @
-- [ raw SELECT_DISTINCT
-- ,   rawSeq [RawField ContractId, RawField ContractVin]
-- , ...
-- ]
-- @
rawSelectDistinct
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawSelectDistinct x = RawWrap' mempty $ raw SELECT_DISTINCT <| pure (rawSeq x)


-- | See description of "rawSelect".
--
-- @
-- rawSelectDistinctOn
--   [ContractVin, ContractValidUntil]
--   [RawField ContractId, RawField ContractVin]
-- @
--
-- Equals to:
--
-- @
-- RawWrap' mempty
--   [ raw SELECT_DISTINCT, raw ON
--   ,   rawIntersected ("(", ") ") (raw COMMA) [ContractVin, ContractValidUntil]
--   ,   rawSeq [RawField ContractId, RawField ContractVin]
--   ]
-- @
--
-- Or in a list of "buildRawSql":
--
-- @
-- [ raw SELECT_DISTINCT, raw ON
-- ,   rawIntersected ("(", ") ") (raw COMMA) [ContractVin, ContractValidUntil]
-- ,   rawSeq [RawField ContractId, RawField ContractVin]
-- , ...
-- ]
-- @
rawSelectDistinctOn
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f) -- ^ A list of distinction criterias ("ON" expression)
  -> f (RawSqlPiece f) -- ^ A list of values to select
  -> RawSqlPiece f

rawSelectDistinctOn onList valuesList
   = RawWrap' mempty
   $ raw SELECT_DISTINCT
  <| raw ON
  <| rawIntersected ("(", ") ") (raw COMMA) onList
  <| pure (rawSeq valuesList)


-- | Declare @WITH@-statement using provided set of aliases.
--
-- @
-- rawWith
--   [ RawAlias (Proxy @"contract")
--       [rawSelect [raw STAR], raw FROM, RawTable (Proxy @Contract)]
--   , RawAlias (Proxy @"program")
--       [rawSelect [raw STAR], raw FROM, RawTable (Proxy @Program)]
--   ]
-- @
--
-- Equals to:
--
-- @
-- RawWrap' mempty
--   [ raw WITH
--   ,   rawSeq
--         [ RawAlias (Proxy @"contract")
--             [rawSelect [raw STAR], raw FROM, RawTable (Proxy @Contract)]
--         , RawAlias (Proxy @"program")
--             [rawSelect [raw STAR], raw FROM, RawTable (Proxy @Program)]
--         ]
--   ]
-- @
--
-- Or in a list of "buildRawSql":
--
-- @
-- [ raw WITH
-- ,   rawSeq
--       [ RawAlias (Proxy @"contract")
--           [rawSelect [raw STAR], raw FROM, RawTable (Proxy @Contract)]
--       , RawAlias (Proxy @"program")
--           [rawSelect [raw STAR], raw FROM, RawTable (Proxy @Program)]
--       ]
-- , ...
-- ]
-- @
rawWith
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawAliasAs' f)
  -> RawSqlPiece f

rawWith cteList = go where
  go = RawWrap' mempty $ raw WITH <| pure (rawSeq $ f <$> cteList)
  f (RawAliasAs' p x) = RawAliasAs p x


data RawAliasAs' f
   = forall alias
   . (KnownSymbol alias, Show (f (RawSqlPiece f)), Eq (f (RawSqlPiece f)))
   => RawAliasAs' (Proxy alias) (f (RawSqlPiece f))

instance Eq (RawAliasAs' f) => Eq (RawAliasAs' f) where
  RawAliasAs' x y == RawAliasAs' a b =
    symbolVal x   == symbolVal   a   &&
                y ==               b

instance Show (RawAliasAs' f) => Show (RawAliasAs' f) where
  show (RawAliasAs' x y) = [qm|
    RawAliasAs' (alias: "{symbolVal x}", innards: {y})
  |]


-- | Selects everything from virtual (or a real) table by an alias.
--
-- Useful when accessing something defined in @WITH@ section by an alias.
rawSelectAlias
  :: (RawPieceConstraint f, KnownSymbol a)
  => Proxy a
  -> RawSqlPiece f

rawSelectAlias p@Proxy
  = RawWrap
  $ raw SELECT <| raw STAR <| raw FROM <| pure (RawAlias p)


-- | Wraps list into provided custom open-close symbols and separates its values
--   with provided (as "RawSqlPiece") custom separator.
rawIntersected
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => (Text, Text)
  -> RawSqlPiece f
  -> f (RawSqlPiece f)
  -> RawSqlPiece f

rawIntersected openCloseSymbols separator =
  uncons ? \case
    Nothing -> RawPlain mempty
    Just (x, xs) ->
      RawWrap' openCloseSymbols $
        x <| foldr (\y acc -> separator <| y <| acc) mempty xs


-- | Just separates values with comma automatically.
--
-- Useful for enumerating fields, you don't have to write @raw COMMA@ between
-- entries manually, and you wouldn't accidentally miss one such a separator.
rawSeq
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawSeq = rawIntersected mempty $ raw COMMA


-- | A chain of conditions wrapped into parenthesis and joined with "OR".
--
-- Helps to not forget to add the "OR" SQL word.
rawSome
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawSome =
  uncons ? \case
    Nothing -> RawPlain mempty
    Just (x, xs) ->
      RawWrap $ x <| foldr (\y acc -> raw OR <| y <| acc) mempty xs


-- | A chain of conditions wrapped into parenthesis and joined with "AND".
--
-- Helps to not forget to add the "AND" SQL word.
rawAll
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawAll =
  uncons ? \case
    Nothing -> RawPlain mempty
    Just (x, xs) ->
      RawWrap $ x <| foldr (\y acc -> raw AND <| y <| acc) mempty xs


-- | Safe pattern for @[raw LIMIT, RawValue (x :: Word)]@
rawLimitTo :: RawPieceConstraint f => Word -> RawSqlPiece f
rawLimitTo = RawWrap' mempty . (raw LIMIT <|) . pure . RawValue


-- | Safe pattern for @[raw OFFSET, RawValue (x :: Word)]@
rawOffsetBy
  :: (RawPieceConstraint f, RawPieceConstraint f)
  => Word
  -> RawSqlPiece f

rawOffsetBy = RawWrap' mempty . (raw OFFSET <|) . pure . RawValue


type PageSize = Word
type Page = Word

-- | Safe pattern for pagination based on "LIMIT" and "OFFSET".
rawPaging :: RawPieceConstraint f => PageSize -> Page -> RawSqlPiece f
rawPaging pageSize page
  | page < 2 = rawLimitTo pageSize
  | otherwise =
      RawWrap' mempty $
        raw LIMIT  <| RawValue pageSize <|
        raw OFFSET <| pure (RawValue $ pageSize * pred page)


data OrderBy
   = forall field. RawFieldConstructor field => Ascending  field
   | forall field. RawFieldConstructor field => Descending field


rawOrderBy
  :: forall f. (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f OrderBy
  -> RawSqlPiece f

rawOrderBy = go where
  go = RawWrap' mempty . (raw ORDER_BY <|) . pure . rawSeq . fmap f

  f :: OrderBy -> RawSqlPiece f
  f (Ascending x)  = RawWrap' mempty $ rawFieldConstructor x <| pure (raw ASC)
  f (Descending x) = RawWrap' mempty $ rawFieldConstructor x <| pure (raw DESC)


type RawFilterByValue t f v inputValue =
   ( RawPieceConstraint f
   , RawValueConstraint v
   , RawFieldConstructor (t v)
   , RawFieldValueConstructor t
   )
  => t v
  -> inputValue -- ^ Either a protected value or a raw piece of SQL.
  -> RawSqlPiece f

rawFilterByValue
  :: RawSqlPiece f
  -> RawFilterByValue t f v (Either v (RawSqlPiece f))

rawFilterByValue pieceInBetween field value
   = RawWrap
   $ rawFieldConstructor field
  <| pieceInBetween
  <| pure (value & either (rawFieldValueConstructor field) id)


-- | For comparing two fields of probably different models.
type RawFilterByField t1 t2 f v =
   ( RawPieceConstraint f
   , RawValueConstraint v
   , RawFieldConstructor (t1 v)
   , RawFieldConstructor (t2 v)
   , RawFieldValueConstructor t1
   , RawFieldValueConstructor t2
   )
  => t1 v -- ^ Field A
  -> t2 v -- ^ Field B
  -> RawSqlPiece f

rawFilterByField :: RawSqlPiece f -> RawFilterByField t1 t2 f v
rawFilterByField pieceInBetween fieldA fieldB
  = rawFilterByValue pieceInBetween fieldA
  $ Right (rawFieldConstructor fieldB)


rawEqual :: RawFilterByValue t f v v
rawEqual t v = Left v & rawFilterByValue (raw EQUAL) t

rawEqual' :: RawFilterByValue t f v (RawSqlPiece f)
rawEqual' t v = Right v & rawFilterByValue (raw EQUAL) t

rawEqualField :: RawFilterByField t1 t2 f v
rawEqualField = rawFilterByField (raw EQUAL)


rawNotEqual :: RawFilterByValue t f v v
rawNotEqual t v = Left v & rawFilterByValue (raw NOT_EQUAL) t

rawNotEqual' :: RawFilterByValue t f v (RawSqlPiece f)
rawNotEqual' t v = Right v & rawFilterByValue (raw NOT_EQUAL) t

rawNotEqualField :: RawFilterByField t1 t2 f v
rawNotEqualField = rawFilterByField (raw NOT_EQUAL)


rawGreater :: RawFilterByValue t f v v
rawGreater t v = Left v & rawFilterByValue (raw GREATER) t

rawGreater' :: RawFilterByValue t f v (RawSqlPiece f)
rawGreater' t v = Right v & rawFilterByValue (raw GREATER) t

rawGreaterField :: RawFilterByField t1 t2 f v
rawGreaterField = rawFilterByField (raw GREATER)


rawGreaterOrEqual :: RawFilterByValue t f v v
rawGreaterOrEqual t v = Left v & rawFilterByValue (raw GREATER_OR_EQUAL) t

rawGreaterOrEqual' :: RawFilterByValue t f v (RawSqlPiece f)
rawGreaterOrEqual' t v = Right v & rawFilterByValue (raw GREATER_OR_EQUAL) t

rawGreaterOrEqualField :: RawFilterByField t1 t2 f v
rawGreaterOrEqualField = rawFilterByField (raw GREATER_OR_EQUAL)


rawLess :: RawFilterByValue t f v v
rawLess t v = Left v & rawFilterByValue (raw LESS) t

rawLess' :: RawFilterByValue t f v (RawSqlPiece f)
rawLess' t v = Right v & rawFilterByValue (raw LESS) t

rawLessField :: RawFilterByField t1 t2 f v
rawLessField = rawFilterByField (raw LESS)


rawLessOrEqual :: RawFilterByValue t f v v
rawLessOrEqual t v = Left v & rawFilterByValue (raw LESS_OR_EQUAL) t

rawLessOrEqual' :: RawFilterByValue t f v (RawSqlPiece f)
rawLessOrEqual' t v = Right v & rawFilterByValue (raw LESS_OR_EQUAL) t

rawLessOrEqualField :: RawFilterByField t1 t2 f v
rawLessOrEqualField = rawFilterByField (raw LESS_OR_EQUAL)


type RawFilterByNullability f t v x =
   ( RawPieceConstraint f
   , RawFieldConstructor (t v)
   , RawValueConstraint x
   )

rawFilterByNullability
  :: (RawFilterByNullability f t v x)
  => Proxy x
  -> Bool
  -> t v
  -> RawSqlPiece f

rawFilterByNullability Proxy isNull field = go where
  go = RawWrap $ rawFieldConstructor field <| raw IS <| f (pure $ raw NULL)
  f = if isNull then id else (raw NOT <|)


rawIsNull
  :: forall f t v x. (RawFilterByNullability f t v x, v ~ Maybe x)
  => t v
  -> RawSqlPiece f

rawIsNull = rawFilterByNullability (Proxy @(Maybe x)) True


-- | "rawIsNull" without constraint of a field optionality.
rawIsNull'
  :: forall f t v. RawFilterByNullability f t v v
  => t v
  -> RawSqlPiece f

rawIsNull' = rawFilterByNullability (Proxy @v) True


rawIsNotNull
  :: forall f t v x. (RawFilterByNullability f t v x, v ~ Maybe x)
  => t v
  -> RawSqlPiece f

rawIsNotNull = rawFilterByNullability (Proxy @(Maybe x)) False


-- | "rawIsNotNull" without constraint of a field optionality.
rawIsNotNull'
  :: forall f t v. RawFilterByNullability f t v v
  => t v
  -> RawSqlPiece f

rawIsNotNull' = rawFilterByNullability (Proxy @v) False


type RawWhetherIn f field
   = (RawPieceConstraint f, RawFieldConstructor field)
  => field
  -> RawSqlPiece f
  -> RawSqlPiece f

rawWhetherIn :: Bool -> RawWhetherIn f field
rawWhetherIn isIn field inWhere = go where
  go = RawWrap $ rawFieldConstructor field <| f (raw IN <| pure x)
  f = if isIn then id else (raw NOT <|)
  x = RawWrap $ pure inWhere


rawIn :: RawWhetherIn f field
rawIn = rawWhetherIn True


rawNotIn :: RawWhetherIn f field
rawNotIn = rawWhetherIn False


type Condition f = RawSqlPiece f
type Result    f = RawSqlPiece f

-- | Generic conditional expression,
--   similar to if/else statements in other programming languages.
--
-- Usual @CASE@-@WHEN@-@THEN@-@ELSE@-@END@ SQL branching.
rawBranching
  :: (RawPieceConstraint f, Cons' f (Condition f, Result f))
  => (Condition f, Result f)
  -- ^ First condition and result (at least one condition is required).
  -> f (Condition f, Result f)
  -- ^ Optional list (allowed to be empty) of pairs of condition and result.
  -> Maybe (Result f)
  -- ^ Optional @ELSE@-clause result.
  -> RawSqlPiece f
  -- ^ End-point result.

rawBranching x xs else' = go where
  go = RawWrap $ raw CASE <| conditions (x <| xs) (elseFn $ pure $ raw END)
  elseFn = maybe id (\y ys -> raw ELSE <| RawWrap (pure y) <| ys) else'
  conditions ys ending = foldr condReducer ending ys

  condReducer (cond, result) ending
     = raw WHEN <| RawWrap (pure cond)
    <| raw THEN <| RawWrap (pure result)
    <| ending


-- | Predefined basic raw SQL function names.
data RawBasicFunction
   = COUNT | COALESCE | NULLIF | CONCAT | LENGTH | CAST | NOW
     deriving (Eq, Show)


-- | Wrapping for a function call (see "RawWrap'").
rawFnWrap :: RawBasicFunction -> (Text, Text)
rawFnWrap fnName = ([qm|\ {fnName}(|], ") ")


rawCount :: RawPieceConstraint f => RawSqlPiece f -> RawSqlPiece f
rawCount = RawWrap' (rawFnWrap COUNT) . pure


rawCoalesce
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawCoalesce = rawFnWrap COALESCE `rawIntersected` raw COMMA


rawNullIf
  :: RawPieceConstraint f
  => RawSqlPiece f
  -> RawSqlPiece f
  -> RawSqlPiece f

rawNullIf arg1 arg2 = RawWrap' (rawFnWrap NULLIF) (arg1 <| pure arg2)


-- | Concat strings function.
rawConcat
  :: (RawPieceConstraint f, Monoid (f (RawSqlPiece f)))
  => f (RawSqlPiece f)
  -> RawSqlPiece f

rawConcat = rawFnWrap CONCAT `rawIntersected` raw COMMA


-- | Length of an SQL string function.
rawLength :: RawPieceConstraint f => RawSqlPiece f -> RawSqlPiece f
rawLength = RawWrap' (rawFnWrap LENGTH) . pure


-- | Extend it when you need it.
--
-- @Maybe Word@ indicates optional size of a type.
--
-- See https://www.postgresql.org/docs/9.3/datatype.html
data RawBasicType
   = CHAR    (Maybe Word)
   | VARCHAR (Maybe Word)
   | TEXT
   | INT
   | REAL
   | BOOL
   | DATE
   | TIME      | TIMETZ      -- ^ "TIME" with time zone
   | TIMESTAMP | TIMESTAMPTZ -- ^ "TIMESTAMP" with time zone
   | ARRAY (Maybe Word) RawBasicType
     deriving (Show, Eq)


toRawSqlType :: RawPieceConstraint f => RawBasicType -> RawSqlPiece f
toRawSqlType = go where
  go             = RawPlain . f

  applySize      = maybe mempty $ \n -> [qm|({n})|] :: Text
  applyArraySize = maybe mempty $ \n -> [qm|[{n}]|] :: Text

  f = \case
    CHAR    size -> [qm|    CHAR{applySize size} |]
    VARCHAR size -> [qm| VARCHAR{applySize size} |]
    TEXT         -> "TEXT"
    INT          -> "INTEGER"
    REAL         -> "REAL"
    BOOL         -> "BOOLEAN"
    DATE         -> "DATE"
    TIME         -> "TIME WITHOUT TIME ZONE"
    TIMETZ       -> "TIME WITH TIME ZONE"
    TIMESTAMP    -> "TIMESTAMP WITHOUT TIME ZONE"
    TIMESTAMPTZ  -> "TIMESTAMP WITH TIME ZONE"
    ARRAY size t -> [qm| {f t} ARRAY{applyArraySize size} |]


-- | "CAST"ing one type to another.
rawCast
  :: RawPieceConstraint f
  => RawBasicType  -- ^ Type to cast to.
  -> RawSqlPiece f -- ^ Value you're casting.
  -> RawSqlPiece f -- ^ Whole "CAST" expression.

rawCast type' value
  = RawWrap' (rawFnWrap CAST)
  $ RawWrap (pure value) <| RawPlain " AS " <| pure (toRawSqlType type')


rawNow :: RawPieceConstraint f => RawSqlPiece f
rawNow = RawPlain [qm|\ {NOW}() \|]


type RawMatchRegex f
   = Bool          -- ^ Indicates whether regex is case-sensitive.
  -> RawSqlPiece f -- ^ A value to test with provided regex.
  -> Text          -- ^ A regular expression to test with.
  -> RawSqlPiece f -- ^ Whole expression wrapped into parenthesis.


-- | Tests whether an SQL value matches provided regular expression.
rawMatchRegex :: RawPieceConstraint f => RawMatchRegex f
rawMatchRegex isCaseSensitive valueToTest regEx =
  rawMatchRegex' isCaseSensitive valueToTest $ RawValue regEx


-- | Negative version of "rawMatchRegex".
rawNotMatchRegex :: RawPieceConstraint f => RawMatchRegex f
rawNotMatchRegex isCaseSensitive valueToTest regEx =
  rawNotMatchRegex' isCaseSensitive valueToTest $ RawValue regEx


type RawMatchRegex' f
   = Bool          -- ^ Indicates whether regex is case-sensitive.
  -> RawSqlPiece f -- ^ A value to test with provided regex.
  -> RawSqlPiece f -- ^ A regular expression to test with.
  -> RawSqlPiece f -- ^ Whole expression wrapped into parenthesis.


-- | First @Bool@ indicates whether a value is supposed to
--   match or to mismatch provided regular expression.
rawWhetherMatchRegex :: RawPieceConstraint f => Bool -> RawMatchRegex' f
rawWhetherMatchRegex isPositive isCaseSensitive valueToTest regEx = go where
  go           = RawWrap $ valueToTest' <| RawPlain operator <| pure regEx'
  valueToTest' = RawWrap $ pure valueToTest
  regEx'       = RawWrap $ pure regEx

  operator = [qm|
    \ {if isPositive      then mempty else "!" :: Text}
     ~{if isCaseSensitive then mempty else "*" :: Text} \
  |]


-- | Version of "rawMatchRegex" that isn't constrained on a string value
--   with a regex but accepts any "RawSqlPiece".
rawMatchRegex' :: RawPieceConstraint f => RawMatchRegex' f
rawMatchRegex' = rawWhetherMatchRegex True


-- | Negative version of "rawMatchRegex'".
rawNotMatchRegex' :: RawPieceConstraint f => RawMatchRegex' f
rawNotMatchRegex' = rawWhetherMatchRegex False
