shader_type canvas_item;

uniform int h_frames  : hint_range(1, 64) = 1;
uniform int v_frames  : hint_range(1, 64) = 1;
uniform int anim_frames = 1;   // frames in this animation (not total sheet frames)
uniform int start_frame = 0;   // first frame index in the full sheet
uniform bool anim_loop = false;
uniform bool flip_h = false;
uniform bool flip_v = false;

void vertex() {
    float fw = 1.0 / float(h_frames);
    float fh = 1.0 / float(v_frames);

    // Scale quad down to a single frame's dimensions
    VERTEX *= vec2(fw, fh);

    // INSTANCE_CUSTOM.x is normalized particle lifetime: 0.0 (birth) → 1.0 (death)
    float lifetime = INSTANCE_CUSTOM.y;
    float pos = lifetime * float(anim_frames);

    int anim_frame;
    if (anim_loop) {
        anim_frame = int(mod(pos, float(anim_frames)));
    } else {
        anim_frame = clamp(int(pos), 0, anim_frames - 1);
    }

    int actual_frame = start_frame + anim_frame;
    int fx = actual_frame % h_frames;
    int fy = actual_frame / h_frames;

    vec2 uv = UV;
    if (flip_h) uv.x = 1.0 - uv.x;
    if (flip_v) uv.y = 1.0 - uv.y;

    UV = vec2(float(fx) * fw + uv.x * fw,
              float(fy) * fh + uv.y * fh);
}