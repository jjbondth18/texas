import type { PrivateSnapshot } from "./protocol.js";
import type { Phase } from "./protocol.js";

export interface PublicVirtualPlayerConfig {
  enabled: boolean;
  targetOnline: number;
  maximumOnline: number;
  maximumPerRoom: number;
  joinDelayMinMs: number;
  joinDelayMaxMs: number;
  actionDelayMinMs: number;
  actionDelayMaxMs: number;
  sessionHandMin: number;
  sessionHandMax: number;
  chatEnabled: boolean;
}

export interface PublicVirtualPlayerProfile {
  id: string;
  displayName: string;
  avatarId: string;
  enabled: boolean;
  skillProfile: "beginner" | "tight_passive" | "tight_aggressive" | "loose_passive" | "balanced";
  preferredBuyIn: number;
  aggression: number;
  looseness: number;
  bluffFrequency: number;
  actionDelayMinMs: number;
  actionDelayMaxMs: number;
  sessionHandMin: number;
  sessionHandMax: number;
  chatEnabled: boolean;
}

const DEFAULT_NAMES = ["RiverFox", "BlueComet", "MapleAce", "NightOwl", "LuckyPine", "SilverWave", "AmberPeak", "CedarMoon", "QuietLake", "RedKite"];

export const PUBLIC_VIRTUAL_PLAYER_PROFILES: readonly PublicVirtualPlayerProfile[] = DEFAULT_NAMES.map((displayName, index) => ({
  id: `virtual:vp_${String(index + 1).padStart(3, "0")}`,
  displayName,
  avatarId: "default",
  enabled: true,
  skillProfile: (["beginner", "tight_passive", "tight_aggressive", "loose_passive", "balanced"] as const)[index % 5],
  preferredBuyIn: 2_000,
  aggression: [0.25, 0.2, 0.68, 0.42, 0.5][index % 5],
  looseness: [0.45, 0.25, 0.3, 0.72, 0.5][index % 5],
  bluffFrequency: [0.04, 0.03, 0.12, 0.1, 0.08][index % 5],
  actionDelayMinMs: 650 + (index % 3) * 150,
  actionDelayMaxMs: 1_800 + (index % 4) * 250,
  sessionHandMin: 3,
  sessionHandMax: 8,
  chatEnabled: false,
}));

export function publicVirtualPlayerConfigFromEnv(env: NodeJS.ProcessEnv = process.env): PublicVirtualPlayerConfig {
  return {
    enabled: booleanValue(env.VIRTUAL_PLAYERS_ENABLED, false),
    targetOnline: integerValue(env.VIRTUAL_PLAYER_TARGET_ONLINE, 2, 0, 32),
    maximumOnline: integerValue(env.VIRTUAL_PLAYER_MAX_ONLINE, 4, 0, 32),
    maximumPerRoom: integerValue(env.VIRTUAL_PLAYER_MAX_PER_ROOM, 2, 0, 8),
    joinDelayMinMs: integerValue(env.VIRTUAL_PLAYER_JOIN_DELAY_MIN_MS, 4_000, 0, 300_000),
    joinDelayMaxMs: integerValue(env.VIRTUAL_PLAYER_JOIN_DELAY_MAX_MS, 12_000, 0, 300_000),
    actionDelayMinMs: integerValue(env.VIRTUAL_PLAYER_ACTION_DELAY_MIN_MS, 650, 100, 30_000),
    actionDelayMaxMs: integerValue(env.VIRTUAL_PLAYER_ACTION_DELAY_MAX_MS, 2_500, 100, 30_000),
    sessionHandMin: integerValue(env.VIRTUAL_PLAYER_SESSION_HAND_MIN, 3, 1, 100),
    sessionHandMax: integerValue(env.VIRTUAL_PLAYER_SESSION_HAND_MAX, 8, 1, 100),
    chatEnabled: booleanValue(env.VIRTUAL_PLAYER_CHAT_ENABLED, false),
  };
}

export function virtualPlayerProfile(ordinal: number): PublicVirtualPlayerProfile {
  return PUBLIC_VIRTUAL_PLAYER_PROFILES[Math.max(0, ordinal) % PUBLIC_VIRTUAL_PLAYER_PROFILES.length];
}

export function choosePublicVirtualAction(
  view: {
    roomId: string;
    handId: number;
    phase: Phase;
    currentBet: number;
    minRaiseTo: number;
    recentActionCount: number;
    ownSeatIndex: number;
    ownChips: number;
    ownCurrentBet: number;
  },
  legal: PrivateSnapshot["legal_actions"],
): { action: "check" | "call" | "fold" | "bet" | "raise"; amount?: number } | null {
  const check = legal.find((item) => item.action === "check");
  const call = legal.find((item) => item.action === "call");
  const fold = legal.find((item) => item.action === "fold");
  const raise = legal.find((item) => item.action === "raise" || item.action === "bet");
  const pressure = view.currentBet > 0 ? Math.max(0, view.currentBet - view.ownCurrentBet) / Math.max(1, view.ownChips) : 0;
  const seed = hash(`${view.roomId}:${view.handId}:${view.phase}:${view.ownSeatIndex}:${view.recentActionCount}`);
  const roll = (seed % 10_000) / 10_000;

  if (raise && roll > 0.82) {
    const minimum = Math.max(1, Math.floor(Number(raise.min_amount ?? view.minRaiseTo)));
    const maximum = Math.max(minimum, Math.floor(Number(raise.max_amount ?? view.ownChips + view.ownCurrentBet)));
    return { action: raise.action as "bet" | "raise", amount: Math.min(maximum, minimum) };
  }
  if (call && pressure <= 0.18 && roll > 0.12) return { action: "call" };
  if (check) return { action: "check" };
  if (call && roll > 0.45) return { action: "call" };
  if (fold) return { action: "fold" };
  return null;
}

function booleanValue(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined || value.trim() === "") return fallback;
  return ["1", "true", "yes", "on"].includes(value.trim().toLowerCase());
}

function integerValue(value: string | undefined, fallback: number, minimum: number, maximum: number): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed)) return fallback;
  return Math.min(maximum, Math.max(minimum, parsed));
}

function hash(value: string): number {
  let result = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    result ^= value.charCodeAt(index);
    result = Math.imul(result, 16777619);
  }
  return result >>> 0;
}
