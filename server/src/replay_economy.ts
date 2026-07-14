export const REPLAY_TYPES = ["official_human", "room_replay", "ai", "training"] as const;

export type ReplayType = (typeof REPLAY_TYPES)[number];

export const REPLAY_ECONOMY_CONFIG = Object.freeze({
  currency: "gems" as const,
  prices: Object.freeze({
    official_human: 20,
    room_replay: 20,
    ai: 10,
    training: 10,
  }),
});

export function isReplayType(value: string): value is ReplayType {
  return (REPLAY_TYPES as readonly string[]).includes(value);
}

export function replayUnlockCost(replayType: ReplayType): number {
  return REPLAY_ECONOMY_CONFIG.prices[replayType];
}

export function replayUnlockReason(replayType: ReplayType): string {
  switch (replayType) {
    case "ai":
      return "ai_replay_unlock";
    case "training":
      return "training_replay_unlock";
    case "official_human":
    case "room_replay":
      return "official_replay_unlock";
  }
}

export function replayTypeForOfficialTable(tableType: string, visibility: "public" | "private"): ReplayType {
  return visibility === "private" || tableType.startsWith("private_") ? "room_replay" : "official_human";
}
