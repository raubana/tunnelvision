$modelname "models/tunnelvision/io_models/io_relay.mdl"
$body 1 "io_relay.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$texturegroup skinfamilies
{
	{ "io_relay_off"  }
	{ "io_relay_on" }
}

$sequence idle "io_relay.smd" {
	loop
	fps 1
}

$surfaceprop metal

$collisionmodel	"io_relay.smd" {}