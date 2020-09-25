package vox;

import format.vox.types.*;
import format.vox.*;
import iron.data.SceneFormat;
import kha.AssetError;
import kha.Blob;
import kha.math.FastMatrix4;

private typedef Tmp = {
	final objCounter: Int;
	final t: Array<FastMatrix4>;
}

class IronVoxLoader {
	public static function loadVoxFromPath( url: String, done: IronVoxFileData -> Void, failed: AssetError -> Void )
		kha.Assets.loadBlobFromPath(
			url,
			parseVox.bind(_, haxe.io.Path.withoutDirectory(url), done, failed),
			failed
		);

	static function parseVox( blob: Blob, url: String, done: IronVoxFileData -> Void, failed: AssetError -> Void ) {
		VoxReader.read(blob.toBytes().getData(), function( ?vox, ?err ) {
			if (err != null) {
				failed({ url: url, error: err });
			} else {
				final data = {
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
		});
	}

	static function walker_begin( vox: Vox, url: String, d: { out: IronVoxFileData, tmp: Tmp } ) {
		for (i in 0...vox.models.length) {
			var model = vox.models[i];
			var mesh = IronMeshFactory.createRawIronMeshData(
				VoxelTools.newVoxelMesh(model.map(function( v ) : Voxel return {
					x: v.x, y: v.y, z: v.z, color: {
						r: vox.palette[v.colorIndex].r,
						g: vox.palette[v.colorIndex].g,
						b: vox.palette[v.colorIndex].b,
						a: vox.palette[v.colorIndex].a,
					}
				})),
				'${url}_mesh_${i}',
				-Math.floor(vox.sizes[i].x / 2), -Math.floor(vox.sizes[i].y / 2), -Math.floor(vox.sizes[i].z / 2)
			);

			d.out.mesh_datas.push(mesh);
		}
	}

	static function walker_end() {
	}

	static function walker_beginGroup( att: Dict ) {
	}

	static function walker_endGroup( d: { out: IronVoxFileData, tmp: Tmp } ) {
		d.tmp.t.pop();
	}

	static function walker_onTransform( att: Dict, d: { out: IronVoxFileData, tmp: Tmp } ) {
		d.tmp.t.push(getTransformation(att, d.tmp.t[d.tmp.t.length - 1]));
	}

	static function walker_onShape( att: Dict, models: Array<Model>, url: String, d: { out: IronVoxFileData, tmp: Tmp } ) {
		for (i in 0...models.length) {
			final model = models[i];
			final transformData = new kha.arrays.Float32Array(16);
			final parent = d.tmp.t[d.tmp.t.length - 1];
			final transform = new iron.math.Mat4(
				parent._00, parent._10, parent._20, parent._30,
				parent._01, parent._11, parent._21, parent._31,
				parent._02, parent._12, parent._22, parent._32,
				parent._03, parent._13, parent._23, parent._33
			);

			transform.write(transformData);

			final obj: TObj = {
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
		final r = VoxTools.getRotationFromDict(att, '_r');
		final t = VoxTools.getTranslationFromDict(att, '_t');

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
