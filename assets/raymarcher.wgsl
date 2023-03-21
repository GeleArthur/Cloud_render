#import bevy_pbr::mesh_types
#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::prepass_utils
#import bevy_pbr::utils

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

    var uv = (frag_coord.xy) - 0.5 * view.viewport.zw;

    uv /= view.viewport.w;

    //let uv = coords_to_viewport_uv(frag_coord.xy, view.viewport);
    //let uv = (frag_coord.xy - 0.5 * view.viewport.xy) / view.viewport.y;
//    let depth = prepass_depth(frag_coord, sample_index);
//
//    let color = step(depth, 0.02);

    let camera = vec3(0.0,1.0,0.0);
    let ray = normalize(vec3(uv.x, uv.y, 1.0));

    var color = RayMarch(camera, ray);
    color /= 10.0;

//    let background_color = vec3(0.0,1.0,1.0);
//    let sigma_a = 0.1; // absorption coefficient
//    let distance = 10.0;
//    let T = exp(-distance * sigma_a);
//    let color = T * background_color;

    return vec4(color, color, color, 1.0);
}

fn RayMarch(ro: vec3<f32>, rd: vec3<f32>) -> f32{
    let MAX_STEPS = 10;
    let MAX_DIST = 100.0;
    let SURF_DIST = 0.1;
    var distanceMarged = 0.0;

    for (var i:i32 = 0; i< MAX_STEPS; i++){
        let pos = ro + rd * distanceMarged;
        let distanceToScene = GetDist(pos);
        distanceMarged += distanceToScene;
        if(distanceMarged > MAX_DIST || distanceToScene < SURF_DIST) {
            break;
        }
    }

    return distanceMarged;
}

fn GetDist(position: vec3<f32>) -> f32 {
    let criclePosition = vec3(0.0,1.0,6.0);
    let cricleRadius = 1.0;
    let sphereDistance = length(position-criclePosition) - cricleRadius;

    let planeDist = position.y;

    let dist = min(planeDist, sphereDistance);

    return dist;
}

