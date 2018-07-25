$modelname "models/tunnelvision/misc/fuse.mdl"
$body 1 "fuse.smd"
$cdmaterials "models/tunnelvision/misc/"

$scale 1

$texturegroup skinfamilies
{
	{ "fuse1" }
	{ "fuse2" }
	{ "fuse3" }
	{ "fuse4" }
	{ "fuse5" }
}

$sequence idle "fuse.smd" {
	loop
	fps 1
}

$surfaceprop plastic

$collisionmodel	"fuse_collision.smd" {}