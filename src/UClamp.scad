// universal pipe u-clamp v0.1

/* [Custom OD] */
pipe_od_input = 25.4; // [1.0:0.1:200.0]
clearance = 0.5; // [0.1:0.05:3.0]

/* [Clamp Geometry] */
saddle_width_input = 30.0; // [5.0:1.0:200.0]
standoff_override = 0.0; // [0.0:0.5:200.0]

/* [Mounting Tabs] */
tab_len_input = 14.0; // [6.0:0.5:50.0]
hole_d = 5.0; // [3.0:0.5:10.0]
tab_corner_r = 3.0; // [0.0:0.5:20.0]

/* [Wall Thickness] */
wall_layers = 0; // [0:Auto, 5:5 layers, 6:6 layers, 7:7 layers, 8:8 layers, 9:9 layers, 10:10 layers]

/* [Preview] */
show_pipe = false; // [true:Show, false:Hide]

/* [Hidden] */
LINE_W   = 0.42;
WALL_GAP = 3.0;
FN_ARC   = 256;
FN_HOLE  = 32;
FN_TAB   = 32;

pipe_od = pipe_od_input;
sw      = saddle_width_input;
tl      = tab_len_input;

function auto_layers(od) = od < 30 ? 6 : od < 60 ? 7 : 8;
nl = (wall_layers == 0) ? auto_layers(pipe_od) : wall_layers;
wt = nl * LINE_W;

ir = pipe_od / 2 + clearance;
or = ir + wt;

sd_auto = or + WALL_GAP;
sd = (standoff_override == 0) ? sd_auto : standoff_override;

tab_r = min(tab_corner_r, tl / 2, sw / 2);

echo(str("pipe_od: ", pipe_od, " mm"));
echo(str("clearance: ", clearance, " mm"));
echo(str("bore_ir: ", ir, " mm"));
echo(str("wall_t: ", wt, " mm"));
echo(str("clamp_or: ", or, " mm"));
echo(str("standoff: ", sd, " mm"));
echo(str("saddle_width: ", sw, " mm"));
echo(str("tab_len: ", tl, " mm"));
echo(str("hole_d: ", hole_d, " mm"));

module clamp_2d() {
    translate([-or, 0]) square([wt, sd]);
    translate([ir, 0]) square([wt, sd]);

    translate([0, sd])
        difference() {
            circle(r = or, $fn = FN_ARC);
            circle(r = ir, $fn = FN_ARC);
            translate([-or, -or])
                square([or * 2, or]);
        }
}

module tab_raw(x0, x1) {
    xlo = min(x0, x1);
    xhi = max(x0, x1);
    x_arm = (abs(xlo) <= abs(xhi)) ? xlo : xhi;
    x_far = (abs(xlo) <= abs(xhi)) ? xhi : xlo;
    x_cyl = x_far + ((x_arm > x_far) ? tab_r : -tab_r);

    if (tab_r < 0.05) {
        translate([xlo, 0, 0]) cube([xhi - xlo, wt, sw]);
    } else {
        hull() {
            translate([x_arm - 0.005, 0, 0]) cube([0.01, wt, sw]);
            for (zc = [tab_r, sw - tab_r])
                translate([x_cyl, 0, zc])
                    rotate([-90, 0, 0])
                        cylinder(r = tab_r, h = wt, $fn = FN_TAB);
        }
    }
}

module u_clamp_raw() {
    difference() {
        union() {
            linear_extrude(height = sw) clamp_2d();
            tab_raw(-or, -(or + tl));
            tab_raw( or,  (or + tl));
        }

        for (xc = [-(or + tl / 2), (or + tl / 2)])
            translate([xc, wt / 2, sw / 2])
                rotate([90, 0, 0])
                    cylinder(
                        d      = hole_d,
                        h      = wt + 2,
                        center = true,
                        $fn    = FN_HOLE
                    );
    }
}

module u_clamp() {
    translate([0, sw, 0])
        rotate([90, 0, 0])
            u_clamp_raw();
}

module pipe_preview() {
    color("SteelBlue", 0.28)
        translate([0, sw / 2, sd])
            rotate([90, 0, 0])
                cylinder(
                    d      = pipe_od,
                    h      = sw * 2,
                    center = true,
                    $fn    = FN_ARC
                );
}

u_clamp();

if (show_pipe) pipe_preview();