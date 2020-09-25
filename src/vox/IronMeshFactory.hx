package vox;

import iron.data.SceneFormat.TMeshData;

class IronMeshFactory {
	public static function createRawIronMeshData( triangles: Array<Triangle>, name: String, x = 0.0, y = 0.0, z = 0.0 ) : TMeshData {
		final vertexCount = triangles.length * 3;
		final positions = new kha.arrays.Float32Array(vertexCount * 3);
		final normals = new kha.arrays.Float32Array(vertexCount * 3);
		final colors = new kha.arrays.Float32Array(vertexCount * 3);
		final indices = new kha.arrays.Uint32Array(vertexCount);

		var pi = 0;
		var ni = 0;
		var ci = 0;
		var ii = 0;

		for (i in 0...triangles.length) {
			final t1 = triangles[i].v1;
			positions.set(pi++, t1.position.x + x);
			positions.set(pi++, t1.position.y + y);
			positions.set(pi++, t1.position.z + z);
			colors.set(ci++, t1.color.r / 255);
			colors.set(ci++, t1.color.g / 255);
			colors.set(ci++, t1.color.b / 255);
			normals.set(ni++, t1.normal.x);
			normals.set(ni++, t1.normal.y);
			normals.set(ni++, t1.normal.z);

			final t2 = triangles[i].v2;
			positions.set(pi++, t2.position.x + x);
			positions.set(pi++, t2.position.y + y);
			positions.set(pi++, t2.position.z + z);
			colors.set(ci++, t2.color.r / 255);
			colors.set(ci++, t2.color.g / 255);
			colors.set(ci++, t2.color.b / 255);
			normals.set(ni++, t2.normal.x);
			normals.set(ni++, t2.normal.y);
			normals.set(ni++, t2.normal.z);

			final t3 = triangles[i].v3;
			positions.set(pi++, t3.position.x + x);
			positions.set(pi++, t3.position.y + y);
			positions.set(pi++, t3.position.z + z);
			colors.set(ci++, t3.color.r / 255);
			colors.set(ci++, t3.color.g / 255);
			colors.set(ci++, t3.color.b / 255);
			normals.set(ni++, t3.normal.x);
			normals.set(ni++, t3.normal.y);
			normals.set(ni++, t3.normal.z);

			indices[ii++] = i * 3 + 0;
			indices[ii++] = i * 3 + 1;
			indices[ii++] = i * 3 + 2;
		}

		return {
			name: name,
			vertex_arrays: [
				{ attrib: "pos", data: 'short4norm', size: 3, values: positions },
				{ attrib: "nor", data: 'short4norm', size: 3, values: normals },
				{ attrib: "col", data: 'short4norm', size: 3, values: colors },
			],
			index_arrays: [{ material: 0, values: indices }],
		}
	}
}

// public var attrib: String;
// public var values: Int16Array;
// public var data: String; // short4norm, short2norm
// @:optional public var padding: Null<Int>;
// @:optional public var size: Null<Int>;
