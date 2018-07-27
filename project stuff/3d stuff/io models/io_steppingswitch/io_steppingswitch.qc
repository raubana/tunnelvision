$modelname "models/tunnelvision/io_models/io_steppingswitch.mdl"
$body 1 "io_steppingswitch.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$texturegroup skinfamilies
{
	{ "io_steppingswitch_off"  }
	{ "io_steppingswitch_1" }
	{ "io_steppingswitch_2" }
	{ "io_steppingswitch_3" }
	{ "io_steppingswitch_4" }
	{ "io_steppingswitch_5" }
	{ "io_steppingswitch_6" }
	{ "io_steppingswitch_7" }
	{ "io_steppingswitch_8" }
	{ "io_steppingswitch_9" }
	{ "io_steppingswitch_0" }
}

$sequence idle "io_steppingswitch.smd" {
	loop
	fps 1
}

$surfaceprop metal

$collisionmodel	"io_steppingswitch.smd" {}