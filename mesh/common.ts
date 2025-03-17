import { Mesh } from "@meshsdk/core";

export async function initializeMesh() {
  const mesh = new Mesh();
  return mesh;
}

export async function getBalance(address: string) {
  const mesh = await initializeMesh();
  return await mesh.getBalance(address);
}

export async function getUtxos(address: string) {
  const mesh = await initializeMesh();
  return await mesh.getUtxos(address);
}
