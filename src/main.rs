mod camera_orbit;

use bevy::core_pipeline::prepass::{DepthPrepass, NormalPrepass};
use bevy::diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin};
use bevy::pbr::NotShadowCaster;
use bevy::reflect::TypeUuid;
use bevy::render::extract_component::ExtractComponentPlugin;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};
use bevy::window::{PresentMode, WindowMode};
use bevy::{pbr::PbrPlugin, prelude::*};
use bevy::prelude::shape::UVSphere;
use bevy_editor_pls::default_windows::cameras::EditorCamera;
use bevy_editor_pls::prelude::*;

use camera_orbit::{CameraController, CameraControllerPlugin};

fn main() {
    App::new()
        .add_plugins(
            DefaultPlugins
                .set(PbrPlugin {
                    prepass_enabled: true,
                })
                .set(WindowPlugin {
                    primary_window: Some(Window {
                        position: WindowPosition::Centered(MonitorSelection::Index(1)),
                        mode: WindowMode::Windowed,
                        present_mode: PresentMode::AutoVsync,
                        ..Default::default()
                    }),
                    ..Default::default()
                })
                .set(AssetPlugin {
                    watch_for_changes: true,
                    ..Default::default()
                }),
        )
        .add_plugin(MaterialPlugin::<RayMarchingMaterial>::default())
        .add_plugin(CameraControllerPlugin)
        .add_startup_system(startup)
        .add_system(quad_follow_camera)
        .add_plugin(EditorPlugin)
        //.add_plugin(LogDiagnosticsPlugin::default())
        //.add_plugin(FrameTimeDiagnosticsPlugin::default())
        .run();
}

fn startup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut ray_materials: ResMut<Assets<RayMarchingMaterial>>,
    mut std_materials: ResMut<Assets<StandardMaterial>>,
) {
    // commands.spawn(PbrBundle {
    //     mesh: meshes.add(Mesh::from(shape::Cube { size: 1.0 })),
    //     material: std_materials.add(Color::rgb(0.8, 0.7, 0.6).into()),
    //     transform: Transform::from_xyz(1.0, 0.0, 0.0),
    //     ..default()
    // });

    commands.spawn(PbrBundle {
        mesh: meshes.add(Mesh::from(UVSphere{
            radius: 0.5,
            sectors: 36*3,
            stacks: 18*3,
            ..default()})),
        material: std_materials.add(Color::rgb(0.8, 0.7, 0.6).into()),
        transform: Transform::from_xyz(0.0,0.0,0.0),
        ..default()
    });

    commands.spawn(PointLightBundle {
        transform: Transform::from_xyz(0.0, 3.0, 0.0),
        ..default()
    });

    commands.spawn((
        Camera3dBundle {
            transform: Transform::from_xyz(-2.0, 2.5, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
            projection: Projection::Perspective(PerspectiveProjection {
                // near: 1.0,
                // far: 3.0,
                ..default()
            }),
            ..default()
        },
        CameraController {
            orbit_mode: true,
            orbit_focus: Vec3::new(0.0, 1.0, 0.0),
            ..Default::default()
        },
        DepthPrepass,
        NormalPrepass,
    ));

    commands.spawn((
        MaterialMeshBundle {
            mesh: meshes.add(shape::Quad::new(Vec2::new(0.1, 0.1)).into()),
            material: ray_materials.add(RayMarchingMaterial {
                show_depth: 0,
            }),
            ..default()
        },
        QuadLabel{
            offset: Vec3::new(0.05, 0.0, 0.0),
        },
        NotShadowCaster,
    ));

    commands.spawn((
        MaterialMeshBundle {
            mesh: meshes.add(shape::Quad::new(Vec2::new(0.1, 0.1)).into()),
            material: ray_materials.add(RayMarchingMaterial {
                show_depth: 1,
            }),
            ..default()
        },
        QuadLabel{
            offset: Vec3::new(-0.05, 0.0, 0.0),
        },
        NotShadowCaster,
    ));
}

#[derive(Component)]
struct QuadLabel {
    offset: Vec3,
}

fn quad_follow_camera(
    mut quads: Query<(&mut Transform, &QuadLabel)>,
    camera: Query<&Transform, (With<Camera3d>, Without<EditorCamera>, Without<QuadLabel>)>,
) {
    let camera = camera.single();

    for (mut quad_pos, quad_label) in quads.iter_mut() {
        quad_pos.rotation = camera.rotation;
        quad_pos.translation = (camera.translation + camera.forward() * 0.11) + quad_label.offset.x * camera.right();
    }
}

#[derive(AsBindGroup, TypeUuid, Debug, Clone)]
#[uuid = "83902611-1612-4997-834d-e826f686c4f3"]
struct RayMarchingMaterial {
    #[uniform(0)]
    show_depth: u32,
}

impl Material for RayMarchingMaterial {
    fn fragment_shader() -> ShaderRef {
        "raymarcher.wgsl".into()
    }
    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}
