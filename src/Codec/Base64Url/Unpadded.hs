{-# LANGUAGE CPP                   #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- | This module provides access to the /unpadded/ \"base64url\" binary-to-text encoding as defined by [RFC 4648](https://tools.ietf.org/html/rfc4648). See also "Codec.Base64Url" for the /padded/ encoding variant.
--
-- This module is intended to be imported @qualified@, e.g.
--
-- > import qualified Codec.Base64Url.Unpadded as B64
--
-- If you want to explictly specify which 'Encode' and 'Decode' typeclass instance is used, you can use plain Haskell2010 type-signature annotations, e.g.
--
-- >>> (B64.encode :: ByteString -> Text) "\x00\x00"
-- "AAA"
--
-- >>> (B64.decode :: Text -> Either String ShortByteString) "NDoyMA"
-- Right "4:20"
--
-- Alternatively, starting with GHC 8.0.1, you can also use the [TypeApplications language extension](https://downloads.haskell.org/~ghc/8.4.1/docs/html/users_guide/glasgow_exts.html#ghc-flag--XTypeApplications):
--
-- >>> B64.encode @ShortByteString @Text "\xFF\239"
-- "_-8"
--
-- >>> B64.decode @Text @ShortByteString "_-8"
-- Right "\255\239"
--
-- @since 0.2.0.0
module Codec.Base64Url.Unpadded
    ( Encode(encode)
    , Decode(decode)
    ) where

import qualified Data.ByteString.Base64.URL      as B64
import qualified Data.ByteString.Base64.URL.Lazy as B64.L

import qualified Data.ByteString                 as BS
#if MIN_VERSION_bytestring(0,10,2)
import qualified Data.ByteString.Builder         as BB
#elif MIN_VERSION_bytestring(0,10,0)
import qualified Data.ByteString.Lazy.Builder    as BB
#endif
import qualified Data.ByteString.Lazy            as BS.L
#if MIN_VERSION_bytestring(0,10,4)
import qualified Data.ByteString.Short           as SBS
#endif

import qualified Data.Text                       as T (Text)
import qualified Data.Text.Encoding              as T (decodeLatin1, encodeUtf8)
import qualified Data.Text.Lazy                  as T.L (Text, fromStrict)
import qualified Data.Text.Lazy.Builder          as TB (Builder, fromLazyText,
                                                        fromText, toLazyText)
import qualified Data.Text.Lazy.Encoding         as T.L (decodeLatin1,
                                                         encodeUtf8)

import           Internal

-- primitives

decodeBs2Bs :: BS.ByteString -> Either String BS.ByteString
decodeBs2Bs = B64.decodeUnpadded

decodeBsL2BsL :: BS.L.ByteString -> Either String BS.L.ByteString
decodeBsL2BsL = B64.L.decodeUnpadded

encodeBs2Bs :: BS.ByteString -> BS.ByteString
encodeBs2Bs = B64.encodeUnpadded

encodeBsL2BsL :: BS.L.ByteString -> BS.L.ByteString
encodeBsL2BsL = B64.L.encodeUnpadded

----------------------------------------------------------------------------
-- exposed API

-- | Typeclass representing types for which a binary-to-text /unpadded/ @base64url@ encoding is defined
--
-- @since 0.2.0.0
class Encode bin txt where
  -- | Encode binary data using /unpadded/ @base64url@ text encoding
  --
  -- @since 0.2.0.0
  encode :: bin -> txt

-- | Typeclass representing types for which a text-to-binary /unpadded/ @base64url@ decoding is defined
--
-- @since 0.2.0.0
class Decode txt bin where
  -- | Decode binary data encoded textually as /unpadded/ @base64url@
  --
  -- @since 0.2.0.0
  decode :: txt -> Either String bin

----------------------------------------------------------------------------
-- instance matrix

---- lazy BS -> *

-- PRIMITIVE
instance Encode BS.L.ByteString BS.L.ByteString where
  encode = encodeBsL2BsL

instance Encode BS.L.ByteString BS.ByteString where
  encode = bsToStrict . encode

#if MIN_VERSION_bytestring(0,10,0)
instance Encode BS.L.ByteString BB.Builder where
  encode = BB.lazyByteString . encode
#endif

#if MIN_VERSION_bytestring(0,10,4)
instance Encode BS.L.ByteString SBS.ShortByteString where
  encode = SBS.toShort . encode
#endif

instance Encode BS.L.ByteString T.Text where
  encode = T.decodeLatin1 . encode

instance Encode BS.L.ByteString T.L.Text where
  encode = T.L.decodeLatin1 . encode

instance Encode BS.L.ByteString TB.Builder where
  encode = TB.fromLazyText . encode

---- strict BS  -> *

-- PRIMITIVE
instance Encode BS.ByteString BS.ByteString where
  encode = encodeBs2Bs

instance Encode BS.ByteString BS.L.ByteString where
  encode = bsFromStrict . encode

#if MIN_VERSION_bytestring(0,10,0)
instance Encode BS.ByteString BB.Builder where
  encode = BB.byteString . encode
#endif

#if MIN_VERSION_bytestring(0,10,4)
instance Encode BS.ByteString SBS.ShortByteString where
  encode = SBS.toShort . encode
#endif

instance Encode BS.ByteString T.Text where
  encode = T.decodeLatin1 . encode

instance Encode BS.ByteString T.L.Text where
  encode = T.L.fromStrict . T.decodeLatin1 . encode

instance Encode BS.ByteString TB.Builder where
  encode = TB.fromText . encode

---- short BS  -> *

#if MIN_VERSION_bytestring(0,10,4)
instance Encode SBS.ShortByteString SBS.ShortByteString where
  encode = SBS.toShort . encode . SBS.fromShort

instance Encode SBS.ShortByteString BS.ByteString where
  encode = encode . SBS.fromShort

instance Encode SBS.ShortByteString BS.L.ByteString where
  encode = encode . SBS.fromShort

instance Encode SBS.ShortByteString BB.Builder where
  encode = encode . SBS.fromShort

instance Encode SBS.ShortByteString T.Text where
  encode = T.decodeLatin1 . encode

instance Encode SBS.ShortByteString T.L.Text where
  encode = T.L.fromStrict . T.decodeLatin1 . encode

instance Encode SBS.ShortByteString TB.Builder where
  encode = TB.fromText . encode
#endif

---- BB  -> *

#if MIN_VERSION_bytestring(0,10,4)
instance Encode BB.Builder SBS.ShortByteString where
  encode = encode . BB.toLazyByteString
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Encode BB.Builder BB.Builder where
  encode = encode . BB.toLazyByteString

instance Encode BB.Builder BS.ByteString where
  encode = encode . BB.toLazyByteString

instance Encode BB.Builder BS.L.ByteString where
  encode = encode . BB.toLazyByteString

instance Encode BB.Builder T.Text where
  encode = T.decodeLatin1 . encode

instance Encode BB.Builder T.L.Text where
  encode = T.L.decodeLatin1 . encode

instance Encode BB.Builder TB.Builder where
  encode = TB.fromLazyText . encode
#endif

------------------------------------------------------------------------------

-- PRIMITIVE
instance Decode BS.ByteString BS.ByteString where
  decode = decodeBs2Bs

instance Decode BS.ByteString BS.L.ByteString where
  decode = fmap bsFromStrict . decode

#if MIN_VERSION_bytestring(0,10,4)
instance Decode BS.ByteString SBS.ShortByteString where
  decode = fmap SBS.toShort . decode
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Decode BS.ByteString BB.Builder where
  decode = fmap BB.byteString . decode
#endif

----

-- PRIMITIVE
instance Decode BS.L.ByteString BS.L.ByteString where
  decode = decodeBsL2BsL

instance Decode BS.L.ByteString BS.ByteString where
  decode = fmap bsToStrict . decode

#if MIN_VERSION_bytestring(0,10,4)
instance Decode BS.L.ByteString SBS.ShortByteString where
  decode = fmap SBS.toShort . decode
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Decode BS.L.ByteString BB.Builder where
  decode = fmap BB.byteString . decode
#endif

----

#if MIN_VERSION_bytestring(0,10,4)
instance Decode SBS.ShortByteString SBS.ShortByteString where
  decode = fmap SBS.toShort . decode . SBS.fromShort

instance Decode SBS.ShortByteString BS.ByteString where
  decode = decode . SBS.fromShort

instance Decode SBS.ShortByteString BS.L.ByteString where
  decode = decode . SBS.fromShort

instance Decode SBS.ShortByteString BB.Builder where
  decode = decode . SBS.fromShort
#endif

----

#if MIN_VERSION_bytestring(0,10,4)
instance Decode BB.Builder SBS.ShortByteString where
  decode = decode . BB.toLazyByteString
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Decode BB.Builder BS.L.ByteString where
  decode = decode . BB.toLazyByteString

instance Decode BB.Builder BS.ByteString where
  decode = decode . BB.toLazyByteString

instance Decode BB.Builder BB.Builder where
  decode = decode . BB.toLazyByteString
#endif

----

instance Decode T.Text BS.ByteString where
  decode = decode . T.encodeUtf8

instance Decode T.Text BS.L.ByteString where
  decode = decode . T.encodeUtf8

#if MIN_VERSION_bytestring(0,10,4)
instance Decode T.Text SBS.ShortByteString where
  decode = decode . T.encodeUtf8
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Decode T.Text BB.Builder where
  decode = decode . T.encodeUtf8
#endif

----

instance Decode T.L.Text BS.ByteString where
  decode = decode . T.L.encodeUtf8

instance Decode T.L.Text BS.L.ByteString where
  decode = decode . T.L.encodeUtf8

#if MIN_VERSION_bytestring(0,10,4)
instance Decode T.L.Text SBS.ShortByteString where
  decode = decode . T.L.encodeUtf8
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Decode T.L.Text BB.Builder where
  decode = decode . T.L.encodeUtf8
#endif

----

instance Decode TB.Builder BS.ByteString where
  decode = decode . TB.toLazyText

instance Decode TB.Builder BS.L.ByteString where
  decode = decode . TB.toLazyText

#if MIN_VERSION_bytestring(0,10,4)
instance Decode TB.Builder SBS.ShortByteString where
  decode = decode . TB.toLazyText
#endif

#if MIN_VERSION_bytestring(0,10,0)
instance Decode TB.Builder BB.Builder where
  decode = decode . TB.toLazyText
#endif
