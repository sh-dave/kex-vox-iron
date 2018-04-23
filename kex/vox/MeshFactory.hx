package kex.vox;

import iron.data.SceneFormat;

class MeshFactory {
	public static function createRawIronMeshData( triangles: Array<Triangle>, name: String, x = 0.0, y = 0.0 ) : iron.data.TMeshData {
		var vertexCount = triangles.length * 3;
		var positions = new kha.arrays.Float32Array(vertexCount * 3);
		var normals = new kha.arrays.Float32Array(vertexCount * 3);
		var colors = new kha.arrays.Float32Array(vertexCount * 3);
		var indices = new kha.arrays.Uint32Array(vertexCount);

		var pi = 0;
		var ni = 0;
		var ci = 0;
		var ii = 0;

		for (i in 0...triangles.length) {
			var t = triangles[i].v1;
			positions.set(pi++, t.position.x + x);
			positions.set(pi++, t.position.y + y);
			positions.set(pi++, t.position.z);
			colors.set(ci++, t.color.r);
			colors.set(ci++, t.color.g);
			colors.set(ci++, t.color.b);
			normals.set(ni++, t.normal.x);
			normals.set(ni++, t.normal.y);
			normals.set(ni++, t.normal.z);

			t = triangles[i].v2;
			positions.set(pi++, t.position.x + x);
			positions.set(pi++, t.position.y + y);
			positions.set(pi++, t.position.z);
			colors.set(ci++, t.color.r);
			colors.set(ci++, t.color.g);
			colors.set(ci++, t.color.b);
			normals.set(ni++, t.normal.x);
			normals.set(ni++, t.normal.y);
			normals.set(ni++, t.normal.z);

			t = triangles[i].v3;
			positions.set(pi++, t.position.x + x);
			positions.set(pi++, t.position.y + y);
			positions.set(pi++, t.position.z);
			colors.set(ci++, t.color.r);
			colors.set(ci++, t.color.g);
			colors.set(ci++, t.color.b);
			normals.set(ni++, t.normal.x);
			normals.set(ni++, t.normal.y);
			normals.set(ni++, t.normal.z);

			indices[ii++] = i * 3 + 0;
			indices[ii++] = i * 3 + 1;
			indices[ii++] = i * 3 + 2;
		}

		return {
			name: name,
			vertex_arrays: [
				{ attrib: "pos", size: 3, values: positions },
				{ attrib: "nor", size: 3, values: normals },
				{ attrib: "col", size: 3, values: colors },
			],
			index_arrays: [{ material: 0, values: indices }],
		}
	}
}
