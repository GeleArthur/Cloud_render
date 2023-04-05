#import bevy_pbr::mesh_types
#import bevy_pbr::mesh_view_bindings
#import bevy_pbr::prepass_utils
#import bevy_pbr::utils
//#import bevy_render::globals

#import bevy_core_pipeline::fullscreen_vertex_shader

const MAX_STEPS = 100;
const MAX_DIST = 100.0;
const SURF_DIST = 0.01;

@group(1) @binding(0)
var<uniform> show_depth: u32;

@fragment
fn fragment(
    @builtin(position) frag_coord: vec4<f32>,
    @builtin(sample_index) sample_index: u32,
    #import bevy_pbr::mesh_vertex_output
) -> @location(0) vec4<f32> {
    let uv = (frag_coord.xy - 0.5 * view.viewport.xy) / view.viewport.y;

    let camera = vec3(view.world_position.x, view.world_position.y, view.world_position.z);
    let ray = normalize(world_position.xyz - camera);

//    let depth = prepass_depth(frag_coord, sample_index);
    var distance = RayMarch(camera, ray);

//    distance =  (distance / 2.0);

//    if(show_depth == 1u){
//        return vec4(vec3(distance),1.0);
//    }else{
//        return vec4(vec3(frag_coord.z - depth),1.0);
//    }

//    var intersection = 1.0 - ((depth) * 100.0);
//    intersection = smoothstep(0.0, 1.0, intersection);


//    if(distance > depth) {
//        discard;
//    }

    let pointOnScene = camera + ray * distance;

    let diffuseLight = GetLight(pointOnScene);

//    let color = GetNormal(pointOnScene);
    let color = diffuseLight;
    //color = step(color, 8.0);
    //color /= 10.0;


    return vec4(vec3(color),1.0);
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
    var dist = MAX_DIST;
//    dist = min(dist, sdSphere(position - vec3(5.0,1.0,0.0), 1.0));
//    let capsule = sdCapsule(position, vec3(0.0, 1.0, 0.0), vec3(0.0, 5.0, 0.0), 0.5);
    dist = min(dist, position.y);
//    let torus = min(dist, sdTorus(position - vec3(0.0,1.0,0.0), vec2(1.5, 0.5)));
//    var cubeRotation = position - vec3(0.0,1.0,0.0);
//    let rot = rotate(f32(globals.frame_count)/100.0);
//    let cuberot2 = vec3(rot.x, cubeRotation.y, rot.y);
//
//    let cube = sdBox(position - vec3(0.0,1.0,0.0), vec3(1.0, 1.0, 1.0));

    var cloudDistance = 100.;

    let sphere1 = sdSphere(position - vec3(-1.0 + smoothSin(100.0),1.0,0.0), 1.0);
    cloudDistance = smin(cloudDistance, sphere1, 0.9);
    let sphere2 = sdSphere(position - vec3(1.0 + smoothSin(120.0),1.0,0.0), 1.0);
    cloudDistance = smin(cloudDistance, sphere2, 0.9);
    let sphere3 = sdSphere(position - vec3(0.0 + smoothSin(500.0),2.0,0.0), 1.0);
    cloudDistance = smin(cloudDistance, sphere3, 0.9);
    let sphere4 = sdSphere(position - vec3(0.3 + smoothSin(300.0),1.0,1.0), 1.0);
    cloudDistance = smin(cloudDistance, sphere4, 0.9);
    let sphere5 = sdSphere(position - vec3(2.0 + smoothSin(50.0),1.0,1.0), 1.0);
    cloudDistance = smin(cloudDistance, sphere5, 0.9);
    let sphere6 = sdSphere(position - vec3(1.5 + smoothSin(100.0),2.0,0.0), 1.0);
    cloudDistance = smin(cloudDistance, sphere6, 0.9);

//    let sphere3 = sdSphere(position - vec3(-1.0,1.0,0.0), 2.0);
//    let sphere4 = sdSphere(position - vec3(1.0,1.0,0.0), 2.0);
//    let sphere5 = sdSphere(position - vec3(-1.0,1.0,0.0), 2.0);
//    let sphere6 = sdSphere(position - vec3(1.0,1.0,0.0), 2.0);



//    var sphereDistance = smin(sphere2, sphere1, sin(f32(globals.frame_count)/100.0+1.0));
//    sphereDistance = smin(capsule, sphereDistance, sin(f32(globals.frame_count)/100.0)+1.0);
    dist = min(dist, cloudDistance);


    return dist;
}

fn GetLight(pointOnScene:vec3<f32>) -> f32 {
    let lightOffest = vec2<f32>(sin(f32(globals.frame_count)/500.0)*2.0, cos(f32(globals.frame_count)/500.0)*2.);

    let lightPos = vec3(0.0 , 3.0, 3.0 );
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

fn rotate(a:f32) -> mat2x2<f32> {
    let s = sin(a);
    let c = cos(a);
    return mat2x2<f32>(c, -s, s, c);
}

fn smin(a: f32, b: f32, k: f32) -> f32 {
    let h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

fn sdCapsule(cameraPoint: vec3<f32>, startAPoint: vec3<f32>, startBPoint:vec3<f32>, radius: f32) -> f32 {
    let pa = cameraPoint - startAPoint;
    let ba = startBPoint - startAPoint;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - radius;
}

fn sdTorus(cameraPoint: vec3<f32>, radius: vec2<f32>) -> f32 {
    let x = length(cameraPoint.xz) - radius.x;
    return length(vec2(x, cameraPoint.y)) - radius.y;
}

fn sdSphere(cameraPoint: vec3<f32>, radius: f32) -> f32 {
    return length(cameraPoint) - radius;
}

fn sdBox(cameraPoint: vec3<f32>, size: vec3<f32>) -> f32 {
    return length(max(abs(cameraPoint) - size, vec3(0.0)));
}

fn smoothSin(offset:f32) -> f32 {
    return sin((f32(globals.frame_count) + offset)/100.0);
}