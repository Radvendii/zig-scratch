pub const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_opengl.h");
});

const InitParams = packed struct(u32) {
    timer: bool = false,
    audio: bool = false,
    video: bool = false,
    joystick: bool = false,
    haptic: bool = false,
    gamecontroller: bool = false,
    events: bool = false,
    sensor: bool = false,
    _padding: u24 = 0,
};

pub fn init(args: InitParams) !void {
    if (c.SDL_Init(@bitCast(args)) < 0) {
        return error.SDLInitFailed;
    }
}

// SEE: https://wiki.libsdl.org/SDL2/SDL_WindowFlags
const WindowFlags = packed struct(u32) {
    fullscreen: bool = false,
    opengl: bool = false,
    shown: bool = false,
    hidden: bool = false,
    borderless: bool = false,
    resizable: bool = false,
    minimized: bool = false,
    maximized: bool = false,
    mouse_grabbed: bool = false,
    input_focus: bool = false,
    mouse_focus: bool = false,
    foreign: bool = false,
    // Don't set this without also setting fullscreen
    desktop: bool = false,
    allow_highdpi: bool = false,
    mouse_capture: bool = false,
    always_on_top: bool = false,
    skip_taskbar: bool = false,
    utility: bool = false,
    tooltip: bool = false,
    popup_menu: bool = false,
    keyboard_grabbed: bool = false,
    _padding: u7 = 0,
    vulkan: bool = false,
    metal: bool = false,
    _padding2: u2 = 0,
};

var CONTEXT_ID: i32 = 0;

pub const Window = struct {
    handle: *c.SDL_Window,
    pub fn glSwap(self: Window) void {
        c.SDL_GL_SwapWindow(self.handle);
    }
    pub fn glCreateContext(self: Window) Context {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_SHARE_WITH_CURRENT_CONTEXT, CONTEXT_ID);
        CONTEXT_ID += 1;
        return .{
            .handle = c.SDL_GL_CreateContext(self.handle),
            .window = self,
        };
    }
};

pub const Context = struct {
    handle: c.SDL_GLContext,
    window: Window,

    pub fn makeCurrent(self: Context) void {
        _ = c.SDL_GL_MakeCurrent(self.window.handle, self.handle);
    }
};

pub const UNDEFINED_POS: i32 = c.SDL_WINDOWPOS_UNDEFINED_MASK;

pub fn createWindow(title: [*:0]const u8, x: i32, y: i32, w: i32, h: i32, flags: WindowFlags) !Window {
    const handle = c.SDL_CreateWindow(title, x, y, w, h, @bitCast(flags)) orelse return error.CreateWindowFailed;
    return .{ .handle = handle };
}

pub fn sleep(ms: u32) void {
    c.SDL_Delay(ms);
}

pub const RendererFlags = packed struct(u32) {
    software: bool = false,
    accelerated: bool = false,
    presentvsync: bool = false,
    targettexture: bool = false,
    _padding: u28 = 0,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Renderer = struct {
    handle: *c.SDL_Renderer,
    pub fn setDrawColor(self: Renderer, color: Color) void {
        _ = c.SDL_SetRenderDrawColor(
            self.handle,
            color.r,
            color.g,
            color.b,
            color.a,
        );
    }
    pub fn clear(self: Renderer) void {
        _ = c.SDL_RenderClear(self.handle);
    }
    pub fn present(self: Renderer) void {
        _ = c.SDL_RenderPresent(self.handle);
    }
};

pub fn createRenderer(window: ?*Window, index: c_int, flags: RendererFlags) !Renderer {
    const handle = c.SDL_CreateRenderer(window, index, @bitCast(flags)) orelse return error.SDLCreateRendererFailed;

    return .{ .handle = handle };
}
