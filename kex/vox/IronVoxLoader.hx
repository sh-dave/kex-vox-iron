package kex.vox;

import format.vox.types.Dict;
import format.vox.types.Node;
import format.vox.types.Vox;
import format.vox.VoxReader;
import format.vox.VoxTools;
import iron.data.SceneFormat;
import kha.AssetError;
import kha.Blob;
import kha.math.FastMatrix4;

typedef IronVox = {
	mesh_datas: Array<TMeshData>,
	objects: Array<TObj>,
	// TODO (DK) materials
}

class IronVoxLoader {
	public static function loadVoxFromPath( url: String, done: IronVox -> Void, failed: AssetError -> Void )
		kha.Assets.loadBlobFromPath(url, parseVox.bind(_, url, done, failed), failed);

	static function parseVox( blob: Blob, url: String, done: IronVox -> Void, failed: AssetError -> Void ) {
		switch new VoxReader(blob.toBytes()).read() {
			case null:
				failed({
					url: url,
					error: 'failed to read bytes'
				});
			case vox:
				var out: IronVox = { mesh_datas: [], objects: [] }
				var tmp = { objCounter: 0 }
				walkNodeGraph(vox, url, done, out, tmp);
				done(out);
		}
	}

	static function walkNodeGraph( vox: Vox, url: String, done: IronVox -> Void, out: IronVox, tmp ) {
		for (i in 0...vox.models.length) {
			var model = vox.models[i];
			var mesh = MeshFactory.createRawIronMeshData(
				VoxelTools.newVoxelMesh(model.map(function( v ) : Voxel return {
					x: v.x, y: v.y, z: v.z, color: {
						r: vox.palette[v.colorIndex].r / 255,
						g: vox.palette[v.colorIndex].g / 255,
						b: vox.palette[v.colorIndex].b / 255,
						a: vox.palette[v.colorIndex].a / 255,
					}
				})),
				'${url}_mesh_${i}',
				-vox.sizes[i].x / 2, -vox.sizes[i].y / 2, -vox.sizes[i].z / 2
			);

			out.mesh_datas.push(mesh);
		}

		nodeWalker(vox.nodeGraph, url, FastMatrix4.identity(), out, tmp);
	}

	static function nodeWalker( node: Node, url: String, parent: FastMatrix4, out: IronVox, tmp ) {
		return switch node {
			case null: // TODO (DK) just for dummy scenes without node graph, should be removed
				for (i in 0...out.mesh_datas.length) {
					var obj: TObj = {
						name: '${url}_obj_${tmp.objCounter++}',
						type: 'mesh_object',
						data_ref: '${url}_mesh_$i',
						material_refs: ['MyMaterial'], // TODO (DK) how to pass this in, do we actually want to?
						transform: null,
					}

					out.objects.push(obj);
				}
			case Transform(att, res, lyr, frames, child):
				nodeWalker(child, url, getTransformation(frames[0], parent), out, tmp);
			case Group(att, children):
				for (child in children) {
					nodeWalker(child, url, parent, out, tmp);
				}
			case Shape(att, models):
				for (i in 0...models.length) {
					var model = models[i];
					var transformData = new kha.arrays.Float32Array(16);
					var transform = new iron.math.Mat4(
						parent._00, parent._10, parent._20, parent._30,
						parent._01, parent._11, parent._21, parent._31,
						parent._02, parent._12, parent._22, parent._32,
						parent._03, parent._13, parent._23, parent._33
					);

					transform.write(transformData);

					var obj: TObj = {
						name: '${url}_obj_${tmp.objCounter++}',
						type: 'mesh_object',
						data_ref: '${url}_mesh_${model.modelId}',
						material_refs: ['MyMaterial'], // TODO (DK) how to pass this in, do we actually want to?
						transform: { values: transformData },
					}

					out.objects.push(obj);
				}
		}
	}

	static function getTransformation( att: Dict, parent: FastMatrix4 ) : FastMatrix4 {
		var r = VoxTools.getRotationFromDict(att, '_r');
		var t = VoxTools.getTranslationFromDict(att, '_t');
		return parent
			.multmat(FastMatrix4.translation(t.x, t.y, t.z))
			.multmat(FastMatrix4.rotation(r.x, r.y, r.z));
	}
}
