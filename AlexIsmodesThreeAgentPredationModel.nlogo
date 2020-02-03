globals
[
  max-humans ;
  max-wolves
  max-rabbits

  rabbit-sensing-radius
  wolf-sensing-radius
  human-sensing-radius
]
; Humans, wolves, and rabbits are the three different breeds of turtles
breed [ humans human ]
breed [ wolves wolf ]
breed [ rabbits rabbit ]
turtles-own [ energy gender age birth-tick lifetime hmyclosest hmynext wmyclosest wmynext rmyclosest rmynext]
patches-own [ countdown ]


to setup
  clear-all

  ; Check model-version switch
  ; if we're not modeling grass, then the sheep don't need to eat to survive
  ; otherwise the grass's state of growth and growing logic need to be set up
  ifelse model-version = "sheep-wolves-grass" [
    ask patches [
      set pcolor one-of [ green brown ]
      ifelse pcolor = green
        [ set countdown grass-regrowth-time ]
      [ set countdown random grass-regrowth-time ] ; initialize grass regrowth clocks randomly for brown patches
    ]
  ]
  [
    ask patches [ set pcolor green ]
  ]

  create-rabbits initial-number-rabbits  ; create the rabbits, then initialize their variables
  [
    set rmyclosest 0
    set shape  "rabbit"
    set color white
    set size 1.5
    set label-color blue - 2
    set lifetime rabbit-lifetime
    set age 0
    set rabbit-sensing-radius rabbit-mate-distance
    set energy random (2 * rabbit-gain-from-food)
    setxy random-xcor random-ycor
    ifelse random 2 = 1
    [ set gender "male" ]
    [ set gender "female" ]
  ]

  create-wolves initial-number-wolves  ; create the wolves, then initialize their variables
  [

    set wmyclosest 0
    set shape "wolf"
    set color 3.5
    set size 2
    set lifetime 15
    set age 0
    set wolf-sensing-radius wolf-mate-distance
    set energy random (2 * wolf-gain-from-food)
    setxy random-xcor random-ycor
    ifelse random 2 = 1
    [ set gender "male" ]
    [ set gender "female" ]
  ]

   create-humans initial-number-humans  ; create the humans, then initialize their variables
  [

    set hmyclosest 0
    set shape  "person"
    set color black
    set lifetime 70
    set age 0
    set human-sensing-radius human-mate-distance
    set size 2.5  ; easier to see
    set energy random (2 * human-gain-from-food)
    setxy random-xcor random-ycor
    ifelse random 2 = 1
    [ set gender "male" ]
    [ set gender "female" ]
  ]
  display-labels
  reset-ticks
end

to r-choose-neighbors
  ;if not any? rabbits and count humans > max-humans
  if count rabbits >= 2
      [
      ask rabbits
        [
          set rmynext min-one-of other rabbits [distance myself]  ;; choose my nearest neighbor based on distance
          set rmyclosest distance rmynext
        ]
  ]
end


to w-choose-neighbors
  ;if not any? rabbits and count humans > max-humans
  if count wolves >= 2
      [
      ask wolves
        [
          set wmynext min-one-of other wolves [distance myself]  ;; choose my nearest neighbor based on distance
          set wmyclosest distance wmynext
        ]
  ]
end


to h-choose-neighbors
  ;if not any? rabbits and count humans > max-humans
  if count humans >= 2
      [
      ask humans
        [
          set hmynext min-one-of other humans [distance myself]  ;; choose my nearest neighbor based on distance
          set hmyclosest distance hmynext
        ]
  ]
end


to aging
 set age age + 1
end

;testing!

to go
  ; stop the simulation of no humans, wolves or rabbits
  if not any? turtles [ stop ]
  ; stop the model if there are no humans or no wolves or no rabbits and stop if the number of humans or wolves or rabbits gets too large

  ;if not any? rabbits and if not any? wolves
  ;[ user-message "The humans have inherited the earth" stop ]

  if count rabbits = 0 and count wolves = 0 [ user-message "The humans have inherited the earth" stop ]
  if count rabbits = 0 and count humans = 0 [ user-message "The wolves have inherited the earth" stop ]
  if count wolves = 0 and count humans = 0 [ user-message "The rabbits have inherited the earth" stop ]

  ;if not any? rabbits and if not any? humans
  ;[ user-message "The wolves have inherited the earth" stop ]

  ;if not any? wolves and if not any? humans
  ;[ user-message "The rabbits have inherited the earth" stop ]


  ;if not any? wolves and count rabbits > max-rabbits [ user-message "The rabbits have inherited the earth" stop ]


  r-choose-neighbors
  w-choose-neighbors
  h-choose-neighbors



  ask rabbits [
    move-rabbit
    if model-version = "rabbits-wolves-humans" [
      set energy energy - 1  ; deduct energy for rabbits only if running rabbits-wolves-humans model version
      eat-grass  ; rabbits eat grass only if running rabbits-wolves-humans model version
      death ; rabbits die if out of energy
    ]
    reproduce-rabbits  ; sheep reproduce at random rate governed by slider
  ]

  ask wolves [
    move
    set energy energy - 1  ; wolves lose energy as they move
    w-eat-rabbits ; wolves eat a rabbit on their patch
    death ; wolves die if out of energy
    reproduce-wolves ; wolves reproduce at random rate governed by slider
  ]

  ask humans [
    move
    set energy energy - 1  ; humans lose energy as they move
    repeat 5 [ shoot-eat-rabbits ]
    shoot-wolves ; wolves eat a sheep on their patch
    death ; humans die if out of energy
    reproduce-humans ; wolves reproduce at random rate governed by slider
  ]

  if model-version = "sheep-wolves-grass" [ ask patches [ grow-grass ] ]
  ; set grass count patches with [pcolor = green]
  display-labels

  ask turtles [aging]
  ask patches [  grow-grass ]

  tick

end

to move  ; turtle procedure
  rt random 50
  lt random 50
  fd 1
end

to move-rabbit
  let target one-of patches with [  pcolor = green ]
  if is-patch? target [ move-to target ]
end

to eat-grass  ; sheep procedure
  ; sheep eat grass, turn the patch brown
  if pcolor = green [
    set pcolor brown
    set energy energy + rabbit-gain-from-food  ; sheep gain energy by eating
  ]
end

to-report potential-mate-rabbit
  ; this is a reporter that gets called in the
  ; context of a rabbit looking for potential mates
  let prospects other rabbits in-radius rabbit-sensing-radius ; rabbit-sensing-radius

  ; - if potential mate already has another mate
  ; - how recently it has reproduced ...
  ; - think about sex: have a turtles-own variable for sex that indicates
  ; male vs. female so mates must be opposite

  ; narrow down prospects to only include those of the opposite gender to the current rabbit (myself).
  set prospects prospects with [ gender != [gender] of myself ] ; select only prospects with the opposite gender
  ; select for other attributes, such as not having a mate and whether it's reproduced recently ...
  ; once you've narrowed this down, we can report one of the remaining prospects:
  report one-of prospects ; if there are no prospects, this will report nobody

end


to-report potential-mate-wolf
  ; this is a reporter that gets called in the
  ; context of a wolf looking for potential mates
 let prospects other wolves in-radius wolf-sensing-radius ; wolf-sensing-radius

  ; - if potential mate already has another mate
  ; - how recently it has reproduced ...
  ; - think about sex: have a turtles-own variable for sex that indicates
  ; male vs. female so mates must be opposite

  ; narrow down prospects to only include those of the opposite gender to the current wolf (myself).
  set prospects prospects with [ gender != [gender] of myself ] ; select only prospects with the opposite gender
  ; select for other attributes, such as not having a mate and whether it's reproduced recently ...
  ; once you've narrowed this down, we can report one of the remaining prospects:
  report one-of prospects ; if there are no prospects, this will report nobody

end


to-report potential-mate-human
  ; this is a reporter that gets called in the
  ; context of a human looking for potential mates
 let prospects other humans in-radius human-sensing-radius ; human-sensing-radius

  ; - if potential mate already has another mate
  ; - how recently it has reproduced ...
  ; - think about sex: have a turtles-own variable for sex that indicates
  ; male vs. female so mates must be opposite

  ; narrow down prospects to only include those of the opposite gender to the current wolf (myself).
  set prospects prospects with [ gender != [gender] of myself ] ; select only prospects with the opposite gender
  ; select for other attributes, such as not having a mate and whether it's reproduced recently ...
  ; once you've narrowed this down, we can report one of the remaining prospects:
  report one-of prospects ; if there are no prospects, this will report nobody

end


to reproduce-rabbits  ; rabbit procedure
  let mate potential-mate-rabbit

  if mate != nobody and random-float 100 < rabbit-reproduce
  [
    move-to [patch-here] of mate
    set energy energy * 0.75
    ask mate [ set energy energy * 0.75 ]
    hatch 1 [
      set energy 0.25 * ([ energy ] of myself + [energy] of mate)
      set age 0
      ifelse random 2 = 1
      [ set gender "male"]
      [ set gender "female" ]
      rt random-float 360
      fd 1
    ]
  ]
end

to reproduce-wolves  ; wolf procedure
  let mate potential-mate-wolf

  if mate != nobody and random-float 100 < wolf-reproduce
  [
    move-to [patch-here] of mate
    set energy energy * 0.75
    ask mate [ set energy energy * 0.75 ]
    hatch 1 [
      set age 0
      set energy 0.25 * ([ energy ] of myself + [energy] of mate)
      ifelse random 2 = 1
      [ set gender "male"]
      [ set gender "female" ]
      rt random-float 360
      fd 1
    ]
  ]
end

to reproduce-humans  ; human procedure
  let mate potential-mate-human

  if mate != nobody and random-float 100 < human-reproduce
  [
    move-to [patch-here] of mate
    set energy energy * 0.75
    ask mate [ set energy energy * 0.75 ]
    hatch 1 [
      set age 0
      set energy 0.25 * ([ energy ] of myself + [energy] of mate)
      ifelse random 2 = 1
      [ set gender "male"]
      [ set gender "female" ]
      rt random-float 360
      fd 1
    ]
  ]
end

to w-eat-rabbits  ; WOLF KILL/EAT RABBIT
  let preyisrabbit one-of rabbits in-radius wolf-hunt-distance
  if preyisrabbit != nobody  [                          ; did we get one?  if so,
    ask preyisrabbit [ die ]                            ; kill it, and...
    set energy energy + wolf-gain-from-food     ; get energy from eating
  ]
end

to w-eat-humans  ; WOLF KILL/EAT HUMAN
  let preyishuman one-of humans-here
  if preyishuman != nobody  [                          ; did we get one?  if so,
    ask preyishuman [ die ]                            ; kill it, and...
    set energy energy + wolf-gain-from-food     ; get energy from eating
  ]
end

to-report potential-shot-rabbit ; HUMAN IDENTIFY POTENTIAL SHOT RABBIT
  ; this is a reporter that gets called in the
  ; context of a human shooting a nearby wolf
  let prospects rabbits in-radius 10 ;human-sensing-radius
  ; this is just a place-holder and you should replace it with yur
  ; code for finding a potential mate
  ; You might consider whether the potential mate already has another
  ; mate or how recently it has reproduced ...
  ; also think about sex: have a turtles-own variable for sex that indicates
  ; male vs. female so mates must be opposite

    report one-of prospects

end

to shoot-eat-rabbits  ; HUMAN KILL/EAT RABBIT
  let preyisrabbit potential-shot-rabbit
  if preyisrabbit != nobody and shooting-accuracy > random-float 100 [
    ask preyisrabbit [ die ]                            ; kill it, and...
    set energy energy + human-gain-from-food     ; get energy from eating
  ]
end

to-report potential-shot-wolf ; HUMAN IDENTIFY POTENTIAL SHOT WOLF
  ; this is a reporter that gets called in the
  ; context of a human shooting a nearby wolf
  let prospects other wolves in-radius 5 ;human-sensing-radius
  ; this is just a place-holder and you should replace it with yur
  ; code for finding a potential mate
  ; You might consider whether the potential mate already has another
  ; mate or how recently it has reproduced ...
  ; also think about sex: have a turtles-own variable for sex that indicates
  ; male vs. female so mates must be opposite

   report one-of prospects

end

to shoot-wolves ; HUMAN KILL WOLF
 let preyiswolf potential-shot-wolf

  if preyiswolf != nobody and shooting-accuracy > random-float 100 [
  ask preyiswolf [die]
  ]
end

to death  ; turtle procedure (i.e. both wolf nd sheep procedure)
  ; when energy dips below zero, die
  if energy < 0 [ die ]
  if random-float 1.0 < (0.75 * (age / lifetime) ^ 4)
  [ die ]
end

to grow-grass  ; patch procedure
  ; countdown on brown patches: if reach 0, grow some grass
  if pcolor = brown [
    ifelse countdown <= 0
      [ set pcolor green
        set countdown grass-regrowth-time ]
      [ set countdown countdown - 1 ]
  ]
end

to-report grass
  ifelse model-version = "rabbits-wolves-humans" [
    report patches with [pcolor = green]
  ]
  [ report 0 ]
end


to display-labels
  ask turtles [ set label "" ]
  if show-energy? [
    ask wolves [ set label round energy ]
    if model-version = "rabbits-wolves-humans" [ ask rabbits [ set label round energy ] ]
  ]
end

to-report survivors
  ifelse any? humans
  [
    report "humans"
  ]
  [
    ifelse any? wolves
    [ report "wolves" ]
    [ report "rabbits" ]
  ]
end


; Modified Uri Wilensky's Wolf-Sheep Predation Model (1997)
; Modification called "Three-Agent Predation Model" by Alex Ismodes (2019)
@#$#@#$#@
GRAPHICS-WINDOW
685
10
1193
519
-1
-1
9.804
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
515
40
680
73
initial-number-humans
initial-number-humans
0
250
15.0
1
1
NIL
HORIZONTAL

SLIDER
175
80
330
113
rabbit-gain-from-food
rabbit-gain-from-food
0.0
50.0
17.0
1.0
1
NIL
HORIZONTAL

SLIDER
175
120
330
153
rabbit-reproduce
rabbit-reproduce
0
100
25.0
1.0
1
%
HORIZONTAL

SLIDER
340
40
505
73
initial-number-wolves
initial-number-wolves
0
250
25.0
1
1
NIL
HORIZONTAL

SLIDER
340
80
505
113
wolf-gain-from-food
wolf-gain-from-food
0.0
100.0
33.0
1.0
1
NIL
HORIZONTAL

SLIDER
340
120
505
153
wolf-reproduce
wolf-reproduce
0.0
100
11.0
1.0
1
%
HORIZONTAL

SLIDER
180
260
330
293
grass-regrowth-time
grass-regrowth-time
0
100
4.0
1
1
NIL
HORIZONTAL

BUTTON
5
170
85
203
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
85
170
170
203
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
5
525
320
695
Populations
time
pop.
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"rabbits / 100" 1.0 0 -1264960 true "" "plot count rabbits / 400"
"wolves" 1.0 0 -13791810 true "" "plot count wolves"
"grass / 4" 1.0 0 -10899396 true "" "if model-version = \"sheep-wolves-grass\" [ plot count grass / 4 ]"
"humans" 1.0 0 -2674135 true "" "plot count humans"

MONITOR
5
475
80
520
rabbits
count rabbits
3
1
11

MONITOR
85
475
160
520
wolves
count wolves
3
1
11

MONITOR
245
475
320
520
grass
count grass / 4
0
1
11

TEXTBOX
200
15
305
33
Rabbit settings
14
0.0
0

TEXTBOX
375
15
465
33
Wolf settings
14
0.0
0

SWITCH
5
250
170
283
show-energy?
show-energy?
1
1
-1000

CHOOSER
5
40
170
85
model-version
model-version
"sheep-wolves" "rabbits-wolves-humans"
1

SLIDER
175
40
330
73
initial-number-rabbits
initial-number-rabbits
0
250
73.0
1
1
NIL
HORIZONTAL

SLIDER
515
80
680
113
human-gain-from-food
human-gain-from-food
0
100
13.0
1
1
NIL
HORIZONTAL

SLIDER
515
120
680
153
human-reproduce
human-reproduce
0
100
7.0
1
1
%
HORIZONTAL

MONITOR
165
475
240
520
humans
count humans
3
1
11

TEXTBOX
540
15
650
33
Human settings
14
0.0
1

BUTTON
85
210
170
243
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
515
240
680
273
shooting-accuracy
shooting-accuracy
0
100
6.0
1
1
%
HORIZONTAL

PLOT
325
525
640
695
Avg Age
time
mean age
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"turtles" 1.0 0 -16777216 true "" "plot mean [ age ] of turtles"
"humans" 1.0 0 -2674135 true "" "plot mean [age] of humans"
"wolves" 1.0 0 -13791810 true "" "plot mean [age] of wolves"
"rabbits" 1.0 0 -1264960 true "" "plot mean [age] of rabbits"

PLOT
645
525
960
695
Avg Energy
tick
mean energy
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"rabbits" 1.0 0 -1264960 true "" "plot mean [ energy ] of rabbits"
"wolves" 1.0 0 -13791810 true "" "plot mean [ energy ] of wolves"
"humans" 1.0 0 -2674135 true "" "plot mean [ energy ] of humans"
"turtles" 1.0 0 -16777216 true "" "plot mean [ energy ] of turtles"

SLIDER
175
160
330
193
rabbit-lifetime
rabbit-lifetime
0
10
8.0
1
1
ticks
HORIZONTAL

SLIDER
340
160
505
193
wolf-lifetime
wolf-lifetime
0
30
10.0
1
1
ticks
HORIZONTAL

SLIDER
175
200
330
233
rabbit-mate-distance
rabbit-mate-distance
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
340
200
505
233
wolf-mate-distance
wolf-mate-distance
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
340
240
505
273
wolf-hunt-distance
wolf-hunt-distance
0
10
2.0
0.5
1
NIL
HORIZONTAL

BUTTON
5
90
170
123
Save the values
export-world user-new-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
5
130
170
163
Load values
import-world user-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
200
240
315
271
Grass settings\n
14
0.0
1

SLIDER
515
160
680
193
human-lifetime
human-lifetime
0
70
50.0
1
1
ticks
HORIZONTAL

SLIDER
515
200
680
233
human-mate-distance
human-mate-distance
0
15
2.0
1
1
NIL
HORIZONTAL

PLOT
5
300
320
470
Avg Distance Same-Breed Neighbor
ticks
mean-rdist
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"humans" 1.0 0 -2674135 true "" "plot mean [hmyclosest] of humans"
"wolves" 1.0 0 -13791810 true "" "plot mean [wmyclosest] of wolves"
"rabbits" 1.0 0 -1664597 true "" "plot mean [rmyclosest] of rabbits"

TEXTBOX
345
295
640
501
Three-Agent Predation Model: Humans, Wolves, and Rabbits \nby Alex Ismodes
35
17.0
0

@#$#@#$#@
## Overview
●Purpose and Patterns
○ The purpose of this extended wolf sheep predation model is to simulate a
simplified but realistic ecosystem and study the dynamic between its three agents which each have their respective real world movement characteristics and interactions. The original wolf sheep predation model only had two agents, each of which had characteristics which were unrealistic. For example, their movement patterns were set to random. This does not model real world sheep or wolves since they move according to stimulus, such as if they see a predator or prey. Also, their reproduction submodels were somewhat faulty since they . Additionally, the model would not function accurately with low agent set amounts (such as with only one of either or both agent sets) since the reproduction function would contribute to their unrealistic population growth. In an ecosystem, these modeled animals do not have the ability to reproduce asexually, so it does not model their interaction accurately. The model will reach an accurate level once it portrays the cyclical nature of population and energy due to predation interaction, which directly include the general measures of population number and energy.

● Entities, state variables, and scales
○ The agents that the model will have are humans, rabbits, and wolves. The
global environment will be a simplified forest. Their interactions will occur throughout the domain. The three agents’ state variables will be energy, sex, and age. Lastly, the time step will be weekly.

● Process Overview and Scheduling 
○ Foraging
-- This process essentially makes the agents search for food sources. Humans look for wolves in order to have the rabbits for themselves. The wolves look for rabbits in order to eat them. Rabbits eat the grass that is grown on the patches.
○ Predation
-- Humans and wolves kill all the other agents in a direct sense while rabbits only destroy the grass. This allows one to analyze the dynamic of competition for a common resource (rabbits) within a simulated ecosystem.

○ Reproduction
-- All three agents have the ability to reproduce as long as they are at
an equal, fixed minimum energy level or above. This process is continuous and results in being able to analyze the dynamic through changing population amounts.

## Design Concepts
● Basic Principles
○ A general concept that underlies the model’s design is that the direct and
indirect interaction among the three agents will be fair and representative of their real world interaction (in a simplified sense). The model illustrates various dynamics and patterns that result from the dynamic of humans, wolves, and rabbits in an ecosystem.

● Emergence
○ The model’s most important results and outputs are the ​population
numbers​ themselves and the ​change and patterns of the population
numbers and agents' average age​. 

● Adaptation
○ I have not thought of a way to include adaptation into the model, but I am thinking about ways in which I can include this form of behavior to all three agents

● Objectives
○ In this model, an agent’s “fitness,” that is its ability to survive and
reproduce, is used to rate decision alternatives. This ability leads the agents to make an effective survival decision, such as foraging, and it aligns with the survival concept with relation to its own spatial location and its location with regards to other variables and agents. 

● Learning
 ○ As of now, agents do not make adaptive decisions over time due to their experiences.

● Prediction
○ I am not sure how to include prediction into this model’s dynamic among
its agents. 

● Sensing
○ Agents are able to sense the proximity and agent type of nearby agents and as such will react accordingly to the stimuli with their respective characteristics. For example, if a humans senses a nearby wolf within its sensing radius then it will proceed to fire his or her gun at the wolf.

● Interaction
○ The model’s agents interact directly and indirectly. Humans and wolves
attack directly at each other and at rabbits, who only eat the grass. All agents interact with each other either through killing (not including its own agent type) or through reproduction (including its agent type).

● Stochasticity
○ I believe that the Poisson Distribution can be incorporated in the
probability of effective reproduction. This way the probability is random since there is no fixed reproduction rate. Further, there is no average reproduction rate documented for wolves and rabbit, so a random reproduction rate might be necessary instead.

● Observation
○ The ​population number,​ average age, and ​average energy by agent type​ are three outputs
that are necessary to effectively evaluate and analyze the dynamic between humans, wolves, and rabbit in this simulated ecosystem.

## Details
● Initialization
○ I will create a starting amount of 40 agents for each of the three types:
humans, wolves, and rabbit. I decided upon this amount because it is not low enough to accidentally cause premature extinction of an agent type due to variability and at the same time it is small enough to leave room for population growth.

● Input Data
○ I do not think I will have an input data in this model, but if I can properly
build it, I will attempt to add temperature/seasons to it. 

● Submodels
○ reproduce
-- This submodel is in charge of the reproduction of all the species. This submodel is effective as long as two agents are each at an equal, fixed minimum energy level or above. Further, I will attempt to incorporate the Poisson Distribution in order to simulate a random probability of reproduction. A fixed reproduction probability would be arbitrary since there is no documentation of the average rate of reproduction among wolves and rabbit.

○ kill
-- This submodel handles the different methods of killing that each
agent has, taking into account their characteristics and nature as represented by the real world. For example, humans kill using guns within a certain radius while wolves kill rabbit from up close. Essentially, the agents do not use the same kill submodel since their natural real world characteristics cause them to kill differently.

○ eat
-- This submodel handles decreasing the energy amount by an equal
fixed amount for all agent sets. It is connected to the agent’s
individual energy levels. 

○ energy
-- This submodel continuously increases the energy of all agent types since it models how one’s energy is continuously increasing (eating decreases this continuous effect).

○ hunt
-- This submodel essentially is the opposite of the flee submodel and
handles foraging. The agents use this to move towards their prey to fulfill the objective of eating it and both decreasing their energy and surviving to eventually reproduce.

○ flee
-- I’m still developing how this submodel will work, but a possibility is
to cause the agents to flee if a predator is nearby. This may also lead me to include a degree of vision for the agents to simulate how in real life one cannot see what is behind.

## CREDITS AND REFERENCES

Wilensky, U. & Reisman, K. (1998). Connected Science: Learning Biology through Constructing and Testing Computational Theories -- an Embodied Modeling Approach. International Journal of Complex Systems, M. 234, pp. 1 - 12. (The Wolf-Sheep-Predation model is a slightly extended version of the model described in the paper.)

Wilensky, U. & Reisman, K. (2006). Thinking like a Wolf, a Sheep or a Firefly: Learning Biology through Constructing and Testing Computational Theories -- an Embodied Modeling Approach. Cognition & Instruction, 24(2), pp. 171-209. http://ccl.northwestern.edu/papers/wolfsheep.pdf .

Wilensky, U., & Rand, W. (2015). An introduction to agent-based modeling: Modeling natural, social and engineered complex systems with NetLogo. Cambridge, MA: MIT Press.

Lotka, A. J. (1925). Elements of physical biology. New York: Dover.

Volterra, V. (1926, October 16). Fluctuations in the abundance of a species considered mathematically. Nature, 118, 558–560.

Gause, G. F. (1934). The struggle for existence. Baltimore: Williams & Wilkins.


<!-- 1997 2000 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
set model-version "sheep-wolves-grass"
set show-energy? false
setup
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count rabbits</metric>
    <metric>count humans</metric>
    <metric>count wolves</metric>
    <metric>survivors</metric>
    <enumeratedValueSet variable="wolf-gain-from-food">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-energy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-wolves">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-hunt-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wolf-reproduce" first="5" step="2" last="15"/>
    <enumeratedValueSet variable="human-gain-from-food">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-rabbits">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rabbit-lifetime">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model-version">
      <value value="&quot;rabbits-wolves-humans&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rabbit-mate-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-humans">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grass-regrowth-time">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="wolf-lifetime" first="5" step="5" last="15"/>
    <enumeratedValueSet variable="rabbit-gain-from-food">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="human-reproduce">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rabbit-reproduce">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wolf-mate-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shooting-accuracy">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
