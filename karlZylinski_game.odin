package game

import rl "vendor:raylib"
import s "core:time"

Animation_Name :: enum {
    Idle,
    Run,
}

Animation :: struct {
    texture: rl.Texture2D,
    num_frames : int,
    frame_timer: f32,
    width : f32,
    height : f32,
    current_frame: int,
    frame_length : f32,
    name: Animation_Name,
}

update_animation :: proc(a: ^Animation) {
    a.frame_timer += rl.GetFrameTime()
    for a.frame_timer > a.frame_length {
        a.current_frame += 1
        a.frame_timer -= a.frame_length
    
        if a.current_frame == a.num_frames {
            a.current_frame = 0
        }
    }
}
draw_animation :: proc(a: Animation, pos: rl.Vector2,flip: bool) {
        player_run_width  := f32(a.texture.width)
        player_run_height := f32(a.texture.height)
        

        source := rl.Rectangle {
            x = f32(a.current_frame) * player_run_width / f32(a.num_frames),
            y = 0,
            width =  player_run_width / f32(a.num_frames),
            height = player_run_height,
        }

        if flip {
            source.width = -source.width
        }

        dest := rl.Rectangle {
            x = pos.x,
            y = pos.y,
            width =  player_run_width  / f32(a.num_frames),
            height = player_run_height,
        }

        rl.ClearBackground({110,184,168,255})
        // rl.DrawRectangleV(pos,{64,64},rl.PINK)
        // rl.DrawTextureRec(player_run_texture, draw_player_source, pos, rl.WHITE)
        rl.DrawTexturePro(a.texture, source, dest, {dest.width/2, dest.height},0, rl.WHITE)
}

PixelWindowHeight :: 180

main :: proc() {
    rl.InitWindow(1280, 720, "Hello world")
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(60)

    player_pos : rl.Vector2 
    player_vel: rl.Vector2
    player_grounded: bool
    player_flip: bool

    // player_running: bool

    player_run := Animation {
        texture = rl.LoadTexture("cat_run.png"),
        num_frames = 4,
        frame_length = 0.1,
        name = .Run,
        // frame_timer: f32,
        // current_frame: int,
    }

    player_idle := Animation {
        texture = rl.LoadTexture("cat_idle.png"),
        num_frames = 2,
        frame_length = 0.5,
        name = .Idle,
    }
    currentAnim := player_idle


    platforms := []rl.Rectangle {
        {-20,20,96,16},
        {90,-10,96,16},
    }
    platform_texture := rl.LoadTexture("platform.png")




    for !rl.WindowShouldClose() {

        if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
            player_vel.x = -100
            player_flip = true
            if currentAnim.name != .Run {
                currentAnim = player_run
            }
            // player_running = true
        } else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
            player_vel.x = 100
            player_flip = false
            if currentAnim.name != .Run {
                currentAnim = player_run
            }
            // player_running = true
        } else {
            player_vel.x = 0
            if currentAnim.name != .Idle {
                currentAnim = player_idle
            }
            // player_running = false
        }

        player_vel.y += 1000 * rl.GetFrameTime()

        if rl.IsKeyPressed(.SPACE) && player_grounded {
            player_vel.y = -300
        }

        player_pos += player_vel*rl.GetFrameTime()

        player_feet_collider := rl.Rectangle {
            player_pos.x -4,
            player_pos.y -4,
            8,
            4,
        }
        player_grounded = false


        for platform in platforms {
            if rl.CheckCollisionRecs(player_feet_collider,platform) && player_vel.y > 0 {
                player_vel.y = 0
                player_pos.y = platform.y
                player_grounded = true
            }

        }


        update_animation(&currentAnim)

        screen_height := f32(rl.GetScreenHeight())

        camera := rl.Camera2D {
            zoom = screen_height/PixelWindowHeight,
            offset = {f32(rl.GetScreenWidth()/2),f32(rl.GetScreenHeight()/2)},
            target = player_pos,
        }


        rl.BeginDrawing()
        if rl.IsKeyDown(.T) {
            s.sleep(1000000000)
        }
        rl.BeginMode2D(camera)
        draw_animation(currentAnim,player_pos,player_flip)
        // rl.DrawRectangleRec(player_feet_collider, {0,255,0,100})
        for platform in platforms {
            rl.DrawTextureV(platform_texture, {platform.x,platform.y}, rl.WHITE)
            // rl.DrawRectangleRec(platform, rl.RED)
        }
        rl.EndMode2D()
        rl.DrawFPS(0,0)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}
