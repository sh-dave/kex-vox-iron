package kex.vox;

import iron.data.SceneFormat;
import kha.AssetError;
import kha.math.FastMatrix4;

typedef IronVox = {
	mesh_datas: Array<TMeshData>,
	objects: Array<TObj>,
	// TODO (DK) materials
}

class IronVoxLoader {
	public static function loadVoxFromPath( url: String, done: IronVox -> Void, failed: AssetError -> Void )
		kha.Assets.loadBlobFromPath(url, parseVox.bind(_, url, done, failed), failed);

	static function parseVox( blob: kha.Blob, url: String, done: IronVox -> Void, failed: AssetError -> Void ) {
		switch new format.vox.Reader(blob.toBytes()).read() {
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

	static function walkNodeGraph( vox: format.vox.types.Vox, url: String, done: IronVox -> Void, out: IronVox, tmp ) {
		var i = 0;

		for (model in vox.models) {
			var mesh = kex.vox.MeshFactory.createRawIronMeshData(
				kex.vox.VoxelTools.newVoxelMesh(model.map(function( v ) : Voxel return {
					x: v.x, y: v.y, z: v.z, color: {
						r: vox.palette[v.colorIndex].r / 255,
						g: vox.palette[v.colorIndex].g / 255,
						b: vox.palette[v.colorIndex].b / 255,
						a: vox.palette[v.colorIndex].a / 255,
					}
				})),
				'${url}_mesh_${i++}',
				0.0, -64.0
			);

			out.mesh_datas.push(mesh);
		}

		nodeWalker(vox.nodeGraph, url, kha.math.FastMatrix4.identity(), out, tmp);
	}

	static function nodeWalker( node: format.vox.types.Node, url: String, parent: FastMatrix4, out: IronVox, tmp ) {
		return switch node {
			case null: // TODO (DK) just for dummy scenes without node graph, should be removed
				for (i in 0...out.mesh_datas.length) {
					var obj: TObj = {
						name: '${url}_obj_${tmp.objCounter++}', // TODO (DK) prepend url?
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
					// trace(transformData);

					var obj: TObj = {
						name: '${url}_obj_${tmp.objCounter++}',
						type: 'mesh_object',
						data_ref: '${url}_mesh_${model.modelId}',
						material_refs: ['MyMaterial'],
						transform: { values: transformData },
					}

					out.objects.push(obj);
				}
		}
	}

	static function getTransformation( att: format.vox.types.Dict, parent: FastMatrix4 ) : FastMatrix4 {
		var r = format.vox.Tools.getRotationFromDict(att, '_r');
		var t = format.vox.Tools.getTranslationFromDict(att, '_t');
		return FastMatrix4.translation(t.x, t.y, t.z).multmat(FastMatrix4.rotation(r.x, r.y, r.z));
	}
}
