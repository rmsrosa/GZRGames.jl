# Virtual Pilot - made with GameZero.jl
# by Felipe & Ricardo (rmsrosa@gmail.com)
# sound effects from https://mixkit.co/free-sound-effects/game/?page=3

WD = 1800 # actual sreen width
HT = 1200 # actual screen heigth
WIDTH = div(WD,2) # app width needs half of that - bug?
HEIGHT = div(HT,2) # app height needs half of that - bug?
BACKGROUND = colorant"#202020"

# background stuff

## grass
GRASS_COLOR = colorant"#208020"
grass = rand(1:50, WIDTH)
grass_pos = 1

## blocks
BRICK_COLOR = colorant"#b08070"
num_bricks = 50
brkpos = [1; accumulate(+, rand(20:100, num_bricks))]
brk_max = brkpos[end]
brkht = rand(10:200, num_bricks)
bricks = [Rect(brkpos[n], 1200, brkpos[n+1]-brkpos[n], -brkht[n]) for n in 1:num_bricks]

# Actors

## Space pod
space_pod = Actor("modfighter.png")

## Lasers
mutable struct Laser
    actor::Actor
    frame_fired::Int
end

## Enemies
mutable struct Enemy
    actor::Actor
    xvel::Int
    yvel::Int
    mobility::Int
    health::Int
end

## Info
game_name = TextActor(
    "Piloto Virtual", # text
    "moonhouse", # font
    font_size=96)
    #color=colorant"#b08070")
game_name.pos = (div(WD, 2) - div(WD, 5), div(HT, 10))

win_text = TextActor(
    "voce venceu!!!", # text
    "moonhouse", # font
    font_size=160)
    #color=colorant"#b08070")
win_text.pos = (div(WD, 2) - div(WD, 3), div(HT, 5))

loose_text = TextActor(
    "Voce perdeu...", # text
    "moonhouse", # font
    font_size=160)
    #color=colorant"#b08070")
loose_text.pos = (div(WD, 2) - div(WD, 3), div(HT, 5))

# Spawn game
function spawn_game()
    global space_pod, pod_lasers
    global num_enemies, enemies

    global game_state = :playing
    global frame_num = 0
    global num_lasers = 10

    space_pod.pos = div(HT,20), div(HT,4) # starting x, y position
    pod_lasers = [
        Laser(
            Actor("pod_laser.png"), # image
            0 # frame_fired
        )
        for _ in 1:num_lasers
    ]
    
    enemies = []
    num_enemies = 10
    for n in 1:num_enemies
        enemy = Enemy(
            Actor("enemyfighter1.png"), # image
            rand(-6:-1), # xvel
            rand(-1:1), # yvel
            rand(1:10), # mobility
            5, # health
        )
        enemy.actor.x = div(WD,2) + 200*n
        enemy.actor.y = rand(20:20:900)
        push!(enemies, enemy)
    end
end

spawn_game()

function on_key_down(g::Game, key)
    global pod_lasers, frame_num, game_state
    laser_frames = getfield.(pod_lasers, :frame_fired)
    last_fire = maximum(laser_frames)
    charged = findfirst(iszero, laser_frames)
    if key == Keys.LSHIFT && charged !== nothing && frame_num > last_fire + 3
        pod_lasers[charged].frame_fired = frame_num
        pod_lasers[charged].actor.x = space_pod.x + div(space_pod.w,2)
        pod_lasers[charged].actor.y = space_pod.y + div(3space_pod.h,4)
        # play_sound("eep")
    end
    if game_state != :playing && key == Keys.RETURN
        game_state = :playing
        spawn_game()
    end
    # println(key)
end

function update(g::Game)
    global frame_num, pod_lasers
    global grass_pos, enemies, game_state, brk_max
    if game_state == :playing
        frame_num += 1
        grass_pos += ifelse(grass_pos == 900, -899, 1)
        for n in 1:length(bricks)
            bricks[n].x -= 1
            if bricks[n].x < -100
                bricks[n].x += brk_max
            end
        end
        for enemy in enemies
            if rand(1:100) ≤ enemy.mobility
                enemy.yvel = -enemy.yvel
            end
            enemy.actor.x += enemy.xvel
            enemy.actor.y -= enemy.xvel * enemy.yvel
            if enemy.actor.x < -192
                enemy.actor.x = WD
            end
            enemy.actor.y = max(20, min(div(7*HT,10), enemy.actor.y))

        end
        #space_pod move
        if g.keyboard.DOWN && space_pod.y < 940
            space_pod.y += 4
        elseif g.keyboard.UP && space_pod.y > 20
            space_pod.y -= 4
        end
        if g.keyboard.RIGHT && space_pod.x < 200
            space_pod.x += 2
        elseif g.keyboard.LEFT && space_pod.x > 20
            space_pod.x -= 2
        end
        for pod_laser in pod_lasers
            if pod_laser.frame_fired > 0
                pod_laser.actor.x += 6
                if pod_laser.actor.x > WD
                    pod_laser.frame_fired = 0
                end
            end
        end
        for enemy in filter(x -> x.health > 0, enemies)
            if collide(enemy.actor, space_pod)
                game_state = :loose
            end
            for pod_laser in filter(l -> l.frame_fired > 0, pod_lasers)
                if collide(enemy.actor, pod_laser.actor) == true
                    enemy.health -= 5
                    pod_laser.frame_fired = 0
                end
            end       
        end
        if maximum(getfield.(enemies, :health)) == 0
            game_state = :win
        end
    end
end

function draw(g::Game)
    if frame_num < 50
        draw(game_name)
    end
    for brick in bricks
        draw(brick, BRICK_COLOR, fill=true)
    end
    for n in 0:WIDTH
        np = mod(frame_num + n, WIDTH) + 1
        draw(Rect(2n-1, 1200, 2, -grass[np]), GRASS_COLOR, fill=true)
    end
    draw(space_pod)
    for enemy in enemies
        if enemy.health > 0
            draw(enemy.actor)
        end
    end
    for pod_laser in pod_lasers
        if pod_laser.frame_fired > 0
            draw(pod_laser.actor)
        end
    end
    if game_state == :win
        draw(win_text)
    elseif game_state == :loose
        draw(loose_text)
    end
end
