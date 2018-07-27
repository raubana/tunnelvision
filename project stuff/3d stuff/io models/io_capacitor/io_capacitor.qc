$modelname "models/tunnelvision/io_models/io_capacitor.mdl"
$body 1 "io_capacitor.smd"
$cdmaterials "models/tunnelvision/io_models/"

$scale 1

$sequence idle "io_capacitor.smd" {
	loop
	fps 1
}

$surfaceprop metal

$collisionmodel	"io_capacitor.smd" {}