package kex.vox;

import format.vox.types.Dict;
import format.vox.types.Model;
import format.vox.types.Vox;
import format.vox.VoxReader;
import format.vox.VoxNodeTools;
import format.vox.VoxTools;
import iron.data.SceneFormat;
import kha.AssetError;
import kha.Blob;
import kha.math.FastMatrix4;

typedef IronVox = {
	vox: Vox,
	mesh_datas: Array<TMeshData>,
	objects: Array<TObj>,
	// TODO (DK) materials
}

private typedef Tmp = {
	objCounter: Int,
	t: Array<FastMatrix4>,
}

class IronVoxLoader {
	public static function loadVoxFromPath( url: String, done: IronVox -> Void, failed: AssetError -> Void )
		kha.Assets.loadBlobFromPath(url, parseVox.bind(_, haxe.io.Path.withoutDirectory(url), done, failed), failed);

	static function parseVox( blob: Blob, url: String, done: IronVox -> Void, failed: AssetError -> Void ) {
		switch new VoxReader(new haxe.io.BytesInput(blob.toBytes())).read() {
			case null:
				failed({
					url: url,
					error: 'failed to read bytes'
				});
			case vox:
				var data = {
					out: { vox: vox, mesh_datas: [], objects: [] },
					tmp: { objCounter: 0, t: [FastMatrix4.identity()] },
				}

				VoxNodeTools.walkNodeGraph(
					vox, {
						beginGraph: walker_begin.bind(_, url, data),
						endGraph: walker_end,
						beginGroup: walker_beginGroup,
						endGroup: walker_endGroup.bind(data),
						onTransform: walker_onTransform.bind(_, data),
						onShape: walker_onShape.bind(_, _, url, data),
					}
				);

				done(data.out);
		}
	}

	static function walker_begin( vox: Vox, url: String, d: { out: IronVox, tmp: Tmp } ) {
		for (i in 0...vox.models.length) {
			var model = vox.models[i];
			var mesh = MeshFactory.createRawIronMeshData(
				VoxelTools.newVoxelMesh(model.map(function( v ) : Voxel return {
					x: v.x, y: v.y, z: v.z, color: {
						r: vox.palette[v.colorIndex].r,
						g: vox.palette[v.colorIndex].g,
						b: vox.palette[v.colorIndex].b,
						a: vox.palette[v.colorIndex].a,
					}
				})),
				'${url}_mesh_${i}',
				-vox.sizes[i].x / 2, -vox.sizes[i].y / 2, -vox.sizes[i].z / 2 // TODO (DK) Math.floor() ?
			);

			d.out.mesh_datas.push(mesh);
		}
	}

	static function walker_end() {
	}

	static function walker_beginGroup( att: Dict ) {
	}

	static function walker_endGroup( d: { out: IronVox, tmp: Tmp } ) {
		d.tmp.t.pop();
	}

	static function walker_onTransform( att: Dict, d: { out: IronVox, tmp: Tmp } ) {
		d.tmp.t.push(getTransformation(att, d.tmp.t[d.tmp.t.length - 1]));
	}

	static function walker_onShape( att: Dict, models: Array<Model>, url: String, d: { out: IronVox, tmp: Tmp } ) {
		for (i in 0...models.length) {
			var model = models[i];
			var transformData = new kha.arrays.Float32Array(16);
			var parent = d.tmp.t[d.tmp.t.length - 1];
			var transform = new iron.math.Mat4(
				parent._00, parent._10, parent._20, parent._30,
				parent._01, parent._11, parent._21, parent._31,
				parent._02, parent._12, parent._22, parent._32,
				parent._03, parent._13, parent._23, parent._33
			);

			transform.write(transformData);

			var obj: TObj = {
				name: '${url}_obj_${d.tmp.objCounter++}',
				type: 'mesh_object',
				data_ref: '${url}_mesh_${model.modelId}',
				material_refs: ['MyMaterial'], // TODO (DK) how to pass this in, do we actually want to?
				transform: { values: transformData },
			}

			d.out.objects.push(obj);
		}

		d.tmp.t.pop();
	}

	static function getTransformation( att: Dict, parent: FastMatrix4 ) : FastMatrix4 {
		var r = VoxTools.getRotationFromDict(att, '_r');
		var t = VoxTools.getTranslationFromDict(att, '_t');

		return parent
			.multmat(FastMatrix4.translation(t.x, t.y, t.z))
			.multmat(new FastMatrix4(
				r._00,	r._10,	r._20,	0,
				r._01,	r._11,	r._21,	0,
				r._02,	r._12,	r._22,	0,
				0,		0,		0,		1
			));
	}
}
