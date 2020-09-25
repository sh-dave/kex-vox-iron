package vox;

import iron.data.SceneFormat.TMeshData;
import iron.data.SceneFormat.TObj;
import format.vox.types.Vox;

typedef IronVoxFileData = {
	final vox: Vox;
	final mesh_datas: Array<TMeshData>;
	final objects: Array<TObj>;
	// TODO (DK) materials
}
