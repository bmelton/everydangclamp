// parametric snap-fit pipe mount v1.2

/* [Pipe] */
pipe_od = 10; // [5.0:0.5:256.0]
clearance = 0.5; // [0.1:0.05:3.0]

/* [Mount Geometry] */
mount_height = 20.0; // [5.0:1.0:100.0]
snap_angle = 60.0; // [10.0:1.0:75.0]
lip_depth = min(1.5, pipe_od * 0.06); // [0.0:0.1:3.0]

/* [Mounting] */
screw_size = 4; // [3:M3, 4:M4, 5:M5]
base_width_override = 0.0; // [0.0:1.0:80.0]
base_thickness = 2.0; // [1.0:0.1:5.0]

/* [Wall Thickness] */
wall_layers = 0; // [0:Auto, 5:5 layers, 6:6 layers, 7:7 layers, 8:8 layers, 9:9 layers, 10:10 layers]

/* [Label] */
show_label = true; // [true:Show, false:Hide]
label_text = "";

/* [Preview] */
// show_pipe = false; // [true:Show, false:Hide]

/* [Hidden] */
LINE_W  = 0.42;
FN_ARC  = 2564;
FN_HOLE = 32;
EPS     = 0.01;

function auto_layers(od) = od < 30 ? 6 : od < 60 ? 7 : 8;

nl = (wall_layers == 0) ? auto_layers(pipe_od) : wall_layers;
wt = nl * LINE_W;

ir = pipe_od / 2 + clearance;
or = ir + wt;

hole_d = screw_size + 0.4;
base_t = base_thickness;

sd = max(or, ir + base_t);

auto_bw = max(pipe_od / 2, hole_d + 6);
bw = (base_width_override == 0) ? auto_bw : base_width_override;

rti_x = ir * sin(snap_angle);
rti_y = sd + ir * cos(snap_angle);
tip_h = wt * cos(snap_angle);

echo(str("pipe_od: ", pipe_od, " mm"));
echo(str("clearance: ", clearance, " mm"));
echo(str("wall_t: ", wt, " mm"));
echo(str("standoff: ", sd, " mm"));
echo(str("snap_angle: ", snap_angle, "°"));
echo(str("lip_depth: ", lip_depth, " mm"));
echo(str("mount_height: ", mount_height, " mm"));
echo(str("base: ", bw, " x ", base_t, " mm"));

module snap_2d() {
    union() {
        translate([0, sd])
            difference() {
                circle(r = or, $fn = FN_ARC);
                circle(r = ir, $fn = FN_ARC);
                polygon([
                    [0, 0],
                    for (a = [90 - snap_angle : 1 : 90 + snap_angle])
                        [(or + 1) * cos(a), (or + 1) * sin(a)]
                ]);
                translate([-(or + 1), -(sd + or + 1)])
                    square([2 * (or + 1), or + 1]);
            }

        translate([-bw / 2, 0])
            square([bw, base_t]);

        lip_eff  = max(0, lip_depth);
        r_center = ir + (wt / 2) - (lip_eff / 2);
        r_circle = (wt / 2) + (lip_eff / 2);
        
        cx = r_center * sin(snap_angle);
        cy = sd + r_center * cos(snap_angle);
        
        translate([ cx, cy]) circle(r = r_circle, $fn = max(FN_HOLE, $fn));
        translate([-cx, cy]) circle(r = r_circle, $fn = max(FN_HOLE, $fn));
    }
}

module snap_mount_raw() {
    lbl       = (label_text != "") ? label_text : str(pipe_od, "mm");
    font_size = min(mount_height * 0.25, bw * 0.20);
    lbl_depth = min(0.6, base_t * 0.35);

    difference() {
        linear_extrude(height = mount_height)
            snap_2d();

        translate([0, base_t / 2, mount_height / 2])
            rotate([90, 0, 0])
                cylinder(
                    d      = hole_d,
                    h      = base_t + 2,
                    center = true,
                    $fn    = FN_HOLE
                );

        if (show_label) {
            translate([0, lbl_depth + EPS, mount_height / 2])
                rotate([90, 0, 0])
                    linear_extrude(lbl_depth + EPS)
                        text(
                            lbl,
                            size   = font_size,
                            halign = "center",
                            valign = "center",
                            font   = "Liberation Sans:style=Bold"
                        );
        }
    }
}

module snap_mount() {
    translate([0, 0, 0])
        rotate([0, 0, 0])
            snap_mount_raw();
}

module pipe_preview() {
    color("SteelBlue", 0.28)
        translate([0, mount_height / 2, sd])
            rotate([90, 0, 0])
                cylinder(
                    d      = pipe_od,
                    h      = mount_height * 2,
                    center = true,
                    $fn    = FN_ARC
                );
}

snap_mount();

if (show_pipe) pipe_preview();