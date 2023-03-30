#import bevy_pbr::mesh_types
#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::prepass_utils
#import bevy_pbr::utils
//#import bevy_render::globals

#import bevy_core_pipeline::fullscreen_vertex_shader

const MAX_STEPS = 100;
const MAX_DIST = 100.0;
const SURF_DIST = 0.01;

struct RayMarchSettings {
    position: vec3<f32>,
    radius: f32,
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
    uv.y = -uv.y;

    //let uv = coords_to_viewport_uv(frag_coord.xy, view.viewport);
    //let uv = (frag_coord.xy - 0.5 * view.viewport.xy) / view.viewport.y;
    //let depth = prepass_depth(frag_coord, sample_index);
    //let color = step(depth, 0.02);

//    let x = ;

    let camera = vec3(view.world_position.x, view.world_position.y, view.world_position.z);
    let ray = normalize(world_position.xyz - camera);
    //let ray = normalize(vec3(uv.x, uv.y, 1.0));

    var distance = RayMarch(camera, ray);

    let pointOnScene = camera + ray * distance;

    let diffuseLight = GetLight(pointOnScene);

    if(diffuseLight < 0.1) {
        discard;
    }

    let color = vec3(diffuseLight);

    //let color = GetNormal(pointOnScene);

    //color = step(color, 8.0);
    //color /= 10.0;



    return vec4(color, 1.0);
}

fn RayMarch(ro: vec3<f32>, rd: vec3<f32>) -> f32{

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
    let criclePosition = vec3(0.0,0.0,0.0);
    let cricleRadius = 1.0;
    let sphereDistance = length(position-criclePosition) - cricleRadius;

    let planeDist = position.y;

    var dist = min(planeDist, sphereDistance);

    return sphereDistance;
}

fn GetLight(pointOnScene:vec3<f32>) -> f32 {
    let lightOffest = vec2<f32>(sin(f32(globals.frame_count)/30.0)*2.0, cos(f32(globals.frame_count)/30.0)*2.);


    let lightPos = vec3(0.0 + lightOffest.x, 5.0, 6.0 + lightOffest.y);
    let lightVector = normalize(lightPos - pointOnScene);

    let normalOfSurface = GetNormal(pointOnScene);

    var diffuse = clamp(dot(normalOfSurface, lightVector), 0.0, 1.0);

    let shadowDist = RayMarch(pointOnScene + normalOfSurface * 0.02, lightVector);
    if(shadowDist < length(lightPos - pointOnScene)) {
        diffuse *= .1;
    }

    return diffuse;
}

fn GetNormal(pointOnScene: vec3<f32>) -> vec3<f32>{
    let d = GetDist(pointOnScene);
    let offset = vec2<f32>(0.01, 0.0);

    let n = d - vec3(
        GetDist(pointOnScene - offset.xyy),
        GetDist(pointOnScene - offset.yxy),
        GetDist(pointOnScene - offset.yyx)
    );

    return normalize(n);
}
