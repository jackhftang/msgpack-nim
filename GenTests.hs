import Data.List
import Test.QuickCheck
import Control.Monad
import Data.Bits
import Data.Word

data Msg =
    MsgNil
  | MsgFalse
  | MsgTrue
  | MsgFixArray [Msg]
  | MsgArray16 [Msg]
  | MsgArray32 [Msg]
  | MsgPFixNum Int
  | MsgNFixNum Int
  | MsgU8 Int
  | MsgU16 Int
  | MsgU32 Int
  | MsgU64 Word
  | MsgFixStr String
  | MsgStr8 String
  | MsgStr16 String
  | MsgStr32 String
  | MsgFixMap [(Msg, Msg)]
  | MsgMap16 [(Msg, Msg)]
  | MsgMap32 [(Msg, Msg)]
  | MsgFloat32 Float
  | MsgFloat64 Double
  | MsgBin8 [Int]
  | MsgBin16 [Int]
  | MsgBin32 [Int]

arrayShow :: [Msg] -> String
arrayShow xs = intercalate "," $ map msgShow xs

mapShow :: [(Msg, Msg)] -> String
mapShow xs = intercalate "," $ map (\(k, v) -> "(" ++ msgShow k ++ "," ++  msgShow v ++ ")") xs

msgShow :: Msg -> String
msgShow MsgNil = "Nil"
msgShow MsgFalse = "False"
msgShow MsgTrue = "True"
msgShow (MsgFixArray xs) = "FixArray(toIterable(@[" ++ arrayShow xs ++ "]))"
msgShow (MsgArray16 xs) = "Array16(toIterable(@[" ++ arrayShow xs ++ "]))"
msgShow (MsgArray32 xs) = "Array32(toIterable(@[" ++ arrayShow xs ++ "]))"
msgShow (MsgPFixNum n) = "PFixNum(" ++ show n ++ "'u8)"
msgShow (MsgNFixNum n) = "NFixNum(" ++ show n ++ "'u8)"
msgShow (MsgU8 n) = "U8(" ++ show n ++ "'u8)"
msgShow (MsgU16 n) = "U16(" ++ show n ++ "'u16)"
msgShow (MsgU32 n) = "U32(" ++ show n ++ "'u32)"
msgShow (MsgU64 n) = "U64(" ++ show n ++ "'u64)"
msgShow (MsgFixStr s) = "FixStr(" ++ show s ++ ")"
msgShow (MsgStr8 s) = "Str8(" ++ show s ++ ")"
msgShow (MsgStr16 s) = "Str16(" ++ show s ++ ")"
msgShow (MsgStr32 s) = "Str32(" ++ show s ++ ")"
msgShow (MsgFixMap xs) = "FixMap(toIterable(@[" ++ mapShow xs ++ "]))"
msgShow (MsgMap16 xs) = "Map16(toIterable(@[" ++ mapShow xs ++ "]))"
msgShow (MsgMap32 xs) = "Map32(toIterable(@[" ++ mapShow xs ++ "]))"
msgShow (MsgFloat32 n) = "Float32(" ++ show n ++ ")"
msgShow (MsgFloat64 n) = "Float64(" ++ show n ++ ")"
msgShow (MsgBin8 xs) = "Bin8(@[" ++ (intercalate "," $ map (\x -> "cast[byte](" ++ show x ++ ")") xs) ++ "])"
msgShow (MsgBin16 xs) = "Bin16(@[" ++ (intercalate "," $ map (\x -> "cast[byte](" ++ show x ++ ")") xs) ++ "])"
msgShow (MsgBin32 xs) = "Bin32(@[" ++ (intercalate "," $ map (\x -> "cast[byte](" ++ show x ++ ")") xs) ++ "])"

instance Show Msg where
  show = msgShow

randStr :: Int -> Gen String
randStr n = sequence [choose ('a', 'Z') | _ <- [1..n]]

randBinSeq :: Int -> Gen [Int]
randBinSeq n = sequence [choose (0, 255) | _ <- [1..n]]

randMsg :: Int -> Gen [Msg]
randMsg n = sequence [arbitrary | _ <- [1..n]]

randMap :: Int -> Gen [(Msg, Msg)]
randMap n = do
    xs <- randMsg n
    ys <- randMsg n
    return $ zip xs ys

-- array weight
aw = 1

-- map weight
mw = 1

-- value weight
vw = 3

-- max signed
maxS n = (1 `shiftL` (n - 1)) - 1

-- max unsigned
maxUS n = (1 `shiftL` n) - 1

instance Arbitrary Msg where 
  arbitrary = do
    frequency [
        (vw, return MsgNil)
      , (vw, return MsgFalse)
      , (vw, return MsgTrue)
      , (aw, liftM MsgFixArray $ choose (1, 7) >>= randMsg)
      , (aw, liftM MsgArray16 $ choose (1, 10) >>= randMsg)
      , (aw, liftM MsgArray32 $ choose (1, 10) >>= randMsg)
      , (mw, liftM MsgFixMap $ choose (1, 5) >>= randMap)
      , (mw, liftM MsgMap16 $ choose (1, 10) >>= randMap)
      , (mw, liftM MsgMap32 $ choose (1, 10) >>= randMap)
      , (vw, liftM MsgPFixNum $ choose (0, maxUS 7))
      , (vw, liftM MsgNFixNum $ choose (0, maxUS 5))
      , (vw, liftM MsgU8 $ choose (0, maxUS 8))
      , (vw, liftM MsgU16 $ choose (0, maxUS 16))
      , (vw, liftM MsgU32 $ choose (0, maxUS 32))
      , (vw, liftM MsgU64 $ choose (0, maxUS 63))
      , (vw, liftM MsgFixStr $ choose (0, 31) >>= randStr)
      , (vw, liftM MsgStr8 $ choose (0, 31) >>= randStr)
      , (vw, liftM MsgStr16 $ choose (0, 31) >>= randStr)
      , (vw, liftM MsgStr32 $ choose (0, 31) >>= randStr)
      , (vw, liftM MsgFloat32 $ arbitrary)
      , (vw, liftM MsgFloat64 $ arbitrary)
      , (vw, liftM MsgBin8 $ choose (0, 10) >>= randBinSeq)
      , (vw, liftM MsgBin16 $ choose (0, 10) >>= randBinSeq)
      , (vw, liftM MsgBin32 $ choose (0, 10) >>= randBinSeq)
      ]

main = do
  msges <- sequence $ [generate (arbitrary :: Gen Msg) | _ <- [1..1000]] :: IO [Msg]
  forM_ msges (\msg -> print $ msg)
