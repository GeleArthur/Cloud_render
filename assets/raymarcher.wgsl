#import bevy_pbr::mesh_types
#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::prepass_utils

struct RayMarchSettings {
    color: vec4<f32>
}

@group(1) @binding(0)
var<uniform> settings: RayMarchSettings;

@fragment
fn fragment(
    @builtin(position) frag_coord: vec4<f32>,
    @builtin(sample_index) sample_index: u32,
    #import bevy_pbr::mesh_vertex_output
) -> @location(0) vec4<f32> {

    let depth = prepass_depth(frag_coord, sample_index);
    return vec4(depth, depth, depth, 1.0);
}
