$modelname "models/tunnelvision/io_models/io_switch.mdl"
$body 1 "io_switch.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$texturegroup skinfamilies
{
	{ "io_switch_off"  }
	{ "io_switch_on" }
}

$sequence idle "io_switch.smd" {
	loop
	fps 1
}

$surfaceprop metal

$collisionmodel	"io_switch.smd" {}