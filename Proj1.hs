--  File        : Proj1.hs
--  Author      : Renjie Meng <renjiem@student.unimelb.edu.au>
--  Student ID  : 877396
--  Purpose     : An implemetation for the auto card guessor
--  Date        : 2019/08/27 - 2019/08/31

-- | This code implements a auto card guessor, including generating initial 
-- guess, the answerer give guessor feedback as well as generating next guess. 
-- For feedback, it provide 5 integer to guessor, detail is in the spec.
-- For initial guess, it generate initial guess depends on number of cards to
-- guess. 
-- For next guess, it follow a strategy that generating all the possible 
-- answer space, and then remove inconsistent possible answer. After that,
-- choose a best guess depends the expected possible answer space for each
-- consistent guess. In addition, there would be slightly difference depends
-- on the number of cards to guess as well as number of guess has tried. 
-- Assumption: There would be strictly 1 - 4 cards in the answer.

module Proj1 (feedback, initialGuess, nextGuess, GameState) where

--　Used Modules
import Card
import Data.List
import Data.Ord

-- Main function prototypes.
feedback :: [Card] -> [Card] -> (Int,Int,Int,Int,Int)
initialGuess :: Int -> ([Card],GameState)
nextGuess :: ([Card],GameState) -> (Int,Int,Int,Int,Int) -> ([Card],GameState)

-- This is the customized GameState Type, 
--      [[Card]] ==> a list of possible answers 
--      Int      -> how many guess has tried
data GameState = GuessSapce [[Card]] Int 
    deriving Show

-- ********************************initialGuess********************************
-- This function is responsible for generating initial guess depneds on number.
-- of card specified by the user.
--    n       ==>  number of cards in the answer
initialGuess n 
    | n <= 0 = error "Please Enter Card Number Between 1 to 52"
    | otherwise = (guess, new_game_state)
        where suits = take n [Club ..]
              ranks = take n (every (13 `div` (n+1)) [R2 ..])
              guess = zipWith Card suits ranks
              full_deck_1_dim = [[Card s r] | s <- [Club ..], r <- [R2 ..]]
              full_answer_space = generateFullAnswerSapce n full_deck_1_dim
              new_game_state =  GuessSapce full_answer_space 1

-- This function takes every nth elem from a list and return them as a new list
every :: Int -> [a] -> [a]
every n list 
    | (n-1) > length list = []
    | otherwise = x : every n xs
        where (x:xs) = drop (n-1) list

-- This function is responsible for generating all possible answer of n cards.
-- Assume that the dim_required > 0
-- hyperPlane ==> the answer spafe which is 1-dim less than the one
--                going to construct    
generateFullAnswerSapce :: Int -> [[Card]] -> [[Card]]
generateFullAnswerSapce dim_required hyperPlane
    | dim_required == 1 = hyperPlane
    | otherwise = generateFullAnswerSapce (dim_required-1) answer_space
        where
            full_deck_1_dim = [[Card s r]| s <- [Club ..], r <- [R2 ..]]
            answer_space = 
                [x++y|x<-full_deck_1_dim,y<-hyperPlane,not (elem (x!!0) y)]


-- **********************************feedback**********************************
-- This function is responsible for giving feedback for the player's guess.
-- Return:
--          num_correct_card  -> The number of cards player guessed correctly
--          num_lower_rank    -> The number of cards in the answer which has 
--                                lower rank than the lowest rank in the guess
--          num_correct_rank  -> The number of cards in the answer has same
--                                  rank in the guess
--          num_higher_rank   -> The number of cards in the answer which has 
--                              higher rank than the highest rank in the guess
--          num_correct_suit  -> The number of cards in the answer has same
--                                  suit in the guess
-- For more information, please read the project specification
feedback target guess 
    | (length target) /= (length guess) = 
        error "Guess and Target do not have the same length"
    | otherwise = 
        (num_correct_card, num_lower_rank, num_correct_rank, 
        num_higher_rank, num_correct_suit)
    where 
          num_correct_card = fb_num_card_matched target guess
          num_lower_rank = fb_num_rank_lower target guess
          num_correct_rank = fb_num_rank_matched target guess
          num_higher_rank = fb_num_rank_higher target guess
          num_correct_suit = fb_num_suit_matched target guess
            
-- This function returns #Card in target has lower rank than lowest in guess
--                   target -> guess  -> num_rank_lower 
fb_num_rank_lower :: [Card] -> [Card] -> Int 
fb_num_rank_lower target guess = 
    length (filter (<lowest_rank_guess) (map getRank target))
    where lowest_rank_guess = getExtremeRank minimum guess

-- This function returns #Card in target has higher rank than highest in guess
--                   target -> guess  -> num_rank_higher
fb_num_rank_higher :: [Card] -> [Card] -> Int 
fb_num_rank_higher target guess = 
    length (filter (>highest_rank_guess) (map getRank target))
    where highest_rank_guess =  getExtremeRank maximum guess

-- This function returns #Card both in target an guess
--                   target -> guess  -> num_card_matched 
fb_num_card_matched :: [Card] -> [Card] -> Int 
fb_num_card_matched target guess = length (target `intersect` guess)

-- This function returns #Suit matched in botn target and guess
--                   target -> guess  -> num_suit_matched 
fb_num_suit_matched :: [Card] -> [Card] -> Int 
fb_num_suit_matched target guess = 
    numElementsInBothList (map getSuit target) (map getSuit guess) 

-- This function returns #Rank matched in botn target and guess
--                   target -> guess  -> num_rank_matched 
fb_num_rank_matched :: [Card] -> [Card] -> Int 
fb_num_rank_matched target guess = 
    numElementsInBothList (map getRank target) (map getRank guess)

-- extract Rank from a Card
getRank :: Card -> Rank
getRank (Card suit rank) = rank

-- extract Suit from a Card
getSuit :: Card -> Suit
getSuit (Card suit rank) = suit

-- extract the extreme(highest/lowest) rank from a list of Cards.
getExtremeRank :: ([Rank] -> Rank) -> [Card] -> Rank
getExtremeRank _ [] = error "Empty card deck has no extreme rank"
getExtremeRank f cards = f (map getRank cards)

-- This function calculates how many elements of lists 1 are in list 2
-- Assume that both list has same length
numElementsInBothList :: Eq a => [a] -> [a] -> Int
numElementsInBothList [] _ = 0
numElementsInBothList _ [] = 0
numElementsInBothList (x:target) guess 
    | elem x guess = 1 + numElementsInBothList target (delete x guess)
    | otherwise = numElementsInBothList target guess

-- *********************************nextGuess**********************************
-- This function is responsible for giving the next guess and GameState depends
-- on the last guess, last feed back and last GameState
nextGuess (last_guess, GuessSapce last_guess_space count) last_feedback =
    (next_guess, next_GameState)
        where 
            number_of_cards = length last_guess
            reduced_guess_space = 
                [x |x<-last_guess_space,feedback x last_guess == last_feedback]
            next_guess = 
                pickBestGuess reduced_guess_space count number_of_cards
            next_GameState = 
                GuessSapce (delete next_guess reduced_guess_space) (count+1)

-- This function is responsible for pick best guess candidate. There are two 
-- strategy pick the head or pick the one with min expected answer space size.
-- Depending on the number of cards in the guess and number of guess tried, it
-- would select one strategy from these two, in order to make program finish 
-- within time limited and use as less as possibile guess.
pickBestGuess :: [[Card]] -> Int -> Int -> [Card]
pickBestGuess [] _ _ = []
pickBestGuess answer_space count number_of_cards
    | number_of_cards == 3 && count < 2 = head answer_space
    | number_of_cards == 4 && count < 3 = head answer_space
    | otherwise= answer_space!!minElemIndex
    where 
        allExpectedGuessSpaceSize =  
            [generateAnswerSapceSize x answer_space | x <- answer_space]
        minElemIndex = getMinElemIndex allExpectedGuessSpaceSize

-- get the index of the element with minimum value in a list
getMinElemIndex :: Ord a => [a] -> Int
getMinElemIndex [] = error "There is no min elements in an empty list"
getMinElemIndex list = minIndex
    where
        minElem = minimum list
        (Just minIndex) = findIndex (==minElem) list

-- This function is responsible for calculate a expectedGuessSpaceSize for
-- a possible answer. Since all the sum of square would divide by same sum, 
-- thus it would be enought to only record for sum of square for finding min
-- in the pickBestGuess.  
generateAnswerSapceSize :: [Card] -> [[Card]] -> Int
generateAnswerSapceSize _ [] = 0
generateAnswerSapceSize guess possibleAnswer =  expectedSize
    where allPossibleFeedback = [feedback x guess| x<-possibleAnswer]
          guessSpaceSizeDistribution = 
            map length (group (sort allPossibleFeedback))
          expectedSize = sum (map (^2) guessSpaceSizeDistribution)