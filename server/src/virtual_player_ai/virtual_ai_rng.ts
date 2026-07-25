export function createVirtualAiRng(parts: readonly (string | number)[]): () => number {
  let state = 2166136261;
  for (const char of parts.join("|")) { state ^= char.charCodeAt(0); state = Math.imul(state, 16777619); }
  return () => { state += 0x6d2b79f5; let v = state; v = Math.imul(v ^ v >>> 15, v | 1); v ^= v + Math.imul(v ^ v >>> 7, v | 61); return ((v ^ v >>> 14) >>> 0) / 4294967296; };
}
