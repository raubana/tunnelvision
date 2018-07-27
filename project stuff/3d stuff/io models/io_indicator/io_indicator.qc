$modelname "models/tunnelvision/io_models/io_indicator.mdl"
$body 1 "io_indicator.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$texturegroup skinfamilies
{
	{ "io_indicator_off"  }
	{ "io_indicator_on" }
}

$sequence idle "io_indicator.smd" {
	loop
	fps 1
}

$surfaceprop metal

$collisionmodel	"io_indicator.smd" {}