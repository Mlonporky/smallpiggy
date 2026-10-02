extends RefCounted
## Eight tiles and one empty cell. Every shuffle is a walk from the solved board.
const GOAL := [0,1,2,3,4,5,6,7,8]
const EMPTY := 8

static func neighbors(cell: int) -> Array[int]:
 var result: Array[int] = []
 for other in 9:
  if absi(cell % 3-other % 3)+absi(cell / 3-other / 3) == 1: result.append(other)
 return result

static func valid(value: Variant) -> bool:
 if not value is Array or value.size() != 9: return false
 var seen := {}
 var inversions := 0
 for i in 9:
  if not (value[i] is int or value[i] is float): return false
  var tile := int(value[i])
  if value[i] != tile or tile < 0 or tile > 8 or seen.has(tile): return false
  seen[tile] = true
  if tile == EMPTY: continue
  for j in range(i):
   if int(value[j]) != EMPTY and int(value[j]) > tile: inversions += 1
 return inversions % 2 == 0

static func distance(board: Array) -> int:
 var total := 0
 for i in 9:
  var tile := int(board[i])
  if tile != EMPTY: total += absi(i % 3-tile % 3)+absi(i / 3-tile / 3)
 return total

static func shuffle(rng: RandomNumberGenerator) -> Array:
 var board := GOAL.duplicate()
 var empty := EMPTY
 var previous := -1
 for step in 32:
  var choices := neighbors(empty)
  choices.erase(previous)
  var next := choices[rng.randi_range(0,choices.size()-1)]
  board[empty] = board[next]
  board[next] = EMPTY
  previous = empty
  empty = next
 # Avoid an almost finished start, still using only legal moves.
 while distance(board) < 8:
  var choices := neighbors(empty)
  choices.erase(previous)
  var next := choices[rng.randi_range(0,choices.size()-1)]
  board[empty] = board[next]
  board[next] = EMPTY
  previous = empty
  empty = next
 return board
