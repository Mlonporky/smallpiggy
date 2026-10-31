extends RefCounted
## Deterministic beat sampling: save/resume/skip reconstruct exactly the same pose.
## Each arm is a rigid segment. Only shoulder angles and walking roots change.
const APPROACH_SECONDS := 2.0
const REACH_SECONDS := 1.2
const RESPONSE_PAUSE := 0.8
const RESPONSE_SECONDS := 1.0
const HOLD_SECONDS := 2.4
const PIG_START := Vector2(630,616)
const CABBAGE_START := Vector2(810,616)

static func sample(pig: Node2D, cabbage: Node2D, id: String, seconds: float) -> Dictionary:
 pig.facing=1
 cabbage.facing=-1
 pig.position=PIG_START
 cabbage.position=CABBAGE_START
 pig.clear_hand()
 cabbage.clear_hand()
 pig.pose(false)
 cabbage.pose(false)
 var a: Vector2=pig.shoulder_world()
 var b: Vector2=cabbage.shoulder_world()
 var r1: float=a.distance_to(pig.hand_world())
 var r2: float=b.distance_to(cabbage.hand_world())
 # Choose a reachable spacing with a gentle downward bend at the joined hands.
 var gap:=sqrt(maxf(0,pow((r1+r2)*0.94,2)-pow(b.y-a.y,2)))
 # Stage is uniformly scaled. Convert world distances back to stage coordinates.
 var final_position: Vector2=cabbage.position+Vector2((a.x+gap-b.x)/pig.get_parent().global_scale.x,0)
 var u:=clampf(seconds/APPROACH_SECONDS,0,1) if id=="step_forward" else 1.0
 var approach:=smoothstep(0,1,u)
 cabbage.position=CABBAGE_START.lerp(final_position,approach)
 cabbage.distance=(CABBAGE_START.x-cabbage.position.x)
 cabbage.pose(id=="step_forward" and u<1, sin(u*PI))
 if id=="step_forward":
  return {"contact":false,"point":Vector2.ZERO,"response":0.0}
 # Both are now settled. Solve the two hand-radius circles once per sample.
 a=pig.shoulder_world()
 b=cabbage.shoulder_world()
 var ab:=b-a
 var length:=ab.length()
 var along: float=(r1*r1-r2*r2+length*length)/(2.0*length)
 var h:=sqrt(maxf(0,r1*r1-along*along))
 var axis:=ab/length
 var target:=a+axis*along+Vector2(-axis.y,axis.x)*h
 var reach:=smoothstep(0,1,clampf(seconds/REACH_SECONDS,0,1)) if id=="reach_hand" else 1.0
 var response:=smoothstep(0,1,clampf((seconds-RESPONSE_PAUSE)/RESPONSE_SECONDS,0,1)) if id=="hold_hands" else (0.0 if id=="reach_hand" else 1.0)
 cabbage.aim_hand(target,reach)
 pig.aim_hand(target,response)
 return {"contact":response>=1.0,"point":target,"response":response}
