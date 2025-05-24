#+feature dynamic-literals
package game

import rl "vendor:raylib"
import s "core:time"
import "core:mem"
import "core:fmt"
import "core:encoding/json"
import "core:os"

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

Level :: struct {
    platforms: [dynamic]rl.Vector2,
}

platform_collider :: proc(pos: rl.Vector2) -> rl.Rectangle {
    return {
        pos.x, pos.y,
        96,16
    }
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for _, entry in track.allocation_map {
            fmt.eprintf("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }


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


    level: Level
    //     platforms = {
    //         {-20,20},
    //         {90,-10},
    //         {90,-50},
    //     },
    // }
    if level_data, ok := os.read_entire_file("level.json",context.temp_allocator); ok {
        if json.unmarshal(level_data, &level) != nil {
            append(&level.platforms,rl.Vector2 {-20,20})
        }
    }

    platform_texture := rl.LoadTexture("platform.png")

    editing := false




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


        for platform in level.platforms {
            if rl.CheckCollisionRecs(player_feet_collider,platform_collider(platform)) && player_vel.y > 0 {
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
        for platform in level.platforms {
            rl.DrawTextureV(platform_texture, platform, rl.WHITE)
            // rl.DrawRectangleRec(platform, rl.RED)
        }

        if rl.IsKeyPressed(.ONE) {
            editing = !editing
        }

        if editing {
            mp := rl.GetScreenToWorld2D(rl.GetMousePosition(),camera)

            rl.DrawTextureV(platform_texture, mp, rl.WHITE)

            if rl.IsMouseButtonPressed(.LEFT) {
                append(&level.platforms, mp)
            }
            if rl.IsMouseButtonPressed(.RIGHT) {
                for p, idx in level.platforms {
                    if rl.CheckCollisionPointRec(mp, platform_collider(p) ) {
                        unordered_remove(&level.platforms, idx)
                        break
                    }
                }
            }
        }
        

        rl.EndMode2D()
        rl.DrawFPS(0,0)
        rl.EndDrawing()
    }
    rl.CloseWindow()

    if level_data, err := json.marshal(level,allocator = context.temp_allocator); err == nil {
        os.write_entire_file("level.json",level_data)
    }
    free_all(context.temp_allocator)

    delete(level.platforms)
}
