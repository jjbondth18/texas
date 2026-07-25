import {
  PUBLIC_VIRTUAL_PLAYER_PROFILES,
  type PublicVirtualPlayerConfig,
  type PublicVirtualPlayerProfile,
} from "./public_virtual_players.js";
import { VirtualPlayerRepository } from "./db/virtual_player_repository.js";

export type VirtualPlayerState = "offline" | "queued" | "joining" | "seated" | "playing" | "pending_leave" | "leaving" | "error";

export interface VirtualPlayerAgentSnapshot {
  playerKind: "virtual";
  playerId: string;
  displayName: string;
  avatarId: string;
  skillProfile: PublicVirtualPlayerProfile["skillProfile"];
  enabled: boolean;
  state: VirtualPlayerState;
  roomId: string;
  seatIndex: number;
  chips: number;
  handId: number;
  sessionHandsPlayed: number;
  onlineSince?: string;
  lastActionAt?: string;
  recentError: string;
  joinBlockReason: string;
  pendingLeaveReason: string;
}

export interface VirtualRoomCandidate {
  roomId: string;
  humanCount: number;
  virtualCount: number;
  waitingHumanCount: number;
  availableSeats: number;
  effectiveWaitingSinceAt: string;
  roomCreatedAt: string;
  eligible: boolean;
}

type MutableAgent = VirtualPlayerAgentSnapshot & { profile: PublicVirtualPlayerProfile; sessionHandTarget: number };

export class VirtualPlayerManager {
  private configValue: PublicVirtualPlayerConfig;
  private readonly agents = new Map<string, MutableAgent>();
  private readonly recentBehaviorLogs: Array<Record<string, unknown>> = [];
  private readonly recoveredAgents: number;
  private lastSchedulerRunAt = "";
  private lastSchedulerError = "";
  private lastSchedulerDecision = "";

  constructor(
    defaults: PublicVirtualPlayerConfig,
    private readonly repository: VirtualPlayerRepository,
    private readonly now: () => Date = () => new Date(),
  ) {
    this.configValue = normalizeConfig({ ...defaults, ...(repository.loadConfig() ?? {}) });
    const overrides = repository.profileOverrides();
    for (const profile of PUBLIC_VIRTUAL_PLAYER_PROFILES) {
      this.agents.set(profile.id, {
        profile,
        playerKind: "virtual",
        playerId: profile.id,
        displayName: profile.displayName,
        avatarId: profile.avatarId,
        skillProfile: profile.skillProfile,
        enabled: overrides.get(profile.id) ?? profile.enabled,
        state: "offline",
        roomId: "",
        seatIndex: -1,
        chips: 0,
        handId: 0,
        sessionHandsPlayed: 0,
        sessionHandTarget: 0,
        recentError: "",
        joinBlockReason: "",
        pendingLeaveReason: "",
      });
    }
    this.recoveredAgents = repository.recoverAfterRestart(this.isoNow());
    if (this.recoveredAgents > 0) this.log("restart_recovery", "", "", `recovered_agents=${this.recoveredAgents}`);
  }

  config(): PublicVirtualPlayerConfig {
    return { ...this.configValue };
  }

  updateConfig(patch: Partial<PublicVirtualPlayerConfig>): PublicVirtualPlayerConfig {
    this.configValue = normalizeConfig({ ...this.configValue, ...patch });
    this.repository.saveConfig(this.configValue, this.isoNow());
    this.log("config_updated", "", "", JSON.stringify(patch));
    return this.config();
  }

  setProfileEnabled(playerId: string, enabled: boolean): void {
    const agent = this.mustAgent(playerId);
    agent.enabled = enabled;
    this.repository.saveProfileEnabled(playerId, enabled, this.isoNow());
    this.log(enabled ? "profile_enabled" : "profile_disabled", playerId);
    if (!enabled && agent.state !== "offline") this.markPendingLeave(playerId, "profile_disabled");
  }

  reserveAgent(roomId: string): PublicVirtualPlayerProfile | undefined {
    if (!this.configValue.enabled || this.onlineCount() >= this.configValue.maximumOnline) return undefined;
    const agent = [...this.agents.values()].find((candidate) => candidate.enabled && candidate.state === "offline");
    if (!agent) return undefined;
    agent.state = "joining";
    agent.roomId = roomId;
    agent.recentError = "";
    agent.joinBlockReason = "";
    this.persist(agent);
    this.log("join_reserved", agent.playerId, roomId);
    return agent.profile;
  }

  hasAvailableAgent(): boolean {
    return this.configValue.enabled
      && this.onlineCount() < this.configValue.targetOnline
      && this.onlineCount() < this.configValue.maximumOnline
      && [...this.agents.values()].some((candidate) => candidate.enabled && candidate.state === "offline");
  }

  canCompleteReservation(playerId: string, roomId: string): boolean {
    const agent = this.agents.get(playerId);
    return Boolean(agent
      && this.configValue.enabled
      && agent.enabled
      && agent.state === "joining"
      && agent.roomId === roomId);
  }

  releaseReservation(playerId: string, reason: string): void {
    const agent = this.mustAgent(playerId);
    if (agent.state !== "joining" && agent.state !== "queued") return;
    this.resetOffline(agent);
    agent.joinBlockReason = reason;
    this.persist(agent);
    this.log("join_reservation_released", playerId, "", reason);
  }

  markSeated(playerId: string, roomId: string, seatIndex: number, chips: number): void {
    const agent = this.mustAgent(playerId);
    const minimum = Math.max(this.configValue.sessionHandMin, agent.profile.sessionHandMin);
    const maximum = Math.max(minimum, Math.min(this.configValue.sessionHandMax, agent.profile.sessionHandMax));
    Object.assign(agent, {
      state: "seated" satisfies VirtualPlayerState,
      roomId,
      seatIndex,
      chips,
      handId: 0,
      sessionHandsPlayed: 0,
      sessionHandTarget: minimum + Math.floor(Math.random() * (maximum - minimum + 1)),
      onlineSince: this.isoNow(),
      recentError: "",
      joinBlockReason: "",
      pendingLeaveReason: "",
    });
    this.persist(agent);
    this.log("seated", playerId, roomId, `seat=${seatIndex} chips=${chips}`);
  }

  markPlaying(playerId: string, handId: number, chips: number): void {
    const agent = this.mustAgent(playerId);
    agent.state = "playing";
    agent.handId = handId;
    agent.chips = chips;
    this.persist(agent);
  }

  canAct(playerId: string, roomId: string): boolean {
    const agent = this.agents.get(playerId);
    return Boolean(agent && agent.roomId === roomId && agent.enabled && ["seated", "playing"].includes(agent.state));
  }

  markAction(playerId: string, handId: number, chips: number, action: string): void {
    const agent = this.mustAgent(playerId);
    agent.state = "playing";
    agent.handId = handId;
    agent.chips = chips;
    agent.lastActionAt = this.isoNow();
    agent.recentError = "";
    this.persist(agent);
    this.log("action", playerId, agent.roomId, action);
  }

  markHandCompleted(playerId: string, handId: number, chips: number): boolean {
    const agent = this.mustAgent(playerId);
    agent.state = "seated";
    agent.handId = handId;
    agent.chips = chips;
    agent.sessionHandsPlayed += 1;
    const shouldLeave = agent.sessionHandsPlayed >= agent.sessionHandTarget;
    if (shouldLeave) agent.state = "pending_leave";
    if (shouldLeave) agent.pendingLeaveReason = "session_hand_target";
    this.persist(agent);
    if (shouldLeave) this.log("pending_leave", playerId, agent.roomId, `reason=session_hand_target hands=${agent.sessionHandsPlayed}`);
    return shouldLeave;
  }

  markPendingLeave(playerId: string, reason: string): void {
    const agent = this.mustAgent(playerId);
    if (agent.state === "offline") return;
    agent.state = "pending_leave";
    agent.pendingLeaveReason = reason;
    this.persist(agent);
    this.log("pending_leave", playerId, agent.roomId, reason);
  }

  markLeaving(playerId: string): void {
    const agent = this.mustAgent(playerId);
    agent.state = "leaving";
    this.persist(agent);
  }

  markOffline(playerId: string, reason: string): void {
    const agent = this.mustAgent(playerId);
    const roomId = agent.roomId;
    this.resetOffline(agent);
    this.persist(agent);
    this.log("offline", playerId, roomId, reason);
  }

  markError(playerId: string, error: string): void {
    const agent = this.mustAgent(playerId);
    agent.state = "error";
    agent.recentError = error.slice(0, 500);
    this.persist(agent);
    this.log("error", playerId, agent.roomId, agent.recentError);
  }

  isPendingLeave(playerId: string): boolean {
    return this.agents.get(playerId)?.state === "pending_leave";
  }

  onlineCount(): number {
    return [...this.agents.values()].filter((agent) => !["offline", "queued"].includes(agent.state)).length;
  }

  selectRoom(candidates: VirtualRoomCandidate[]): VirtualRoomCandidate | undefined {
    this.lastSchedulerRunAt = this.isoNow();
    this.lastSchedulerError = "";
    return candidates
      .filter((candidate) => candidate.eligible && candidate.humanCount === 1 && candidate.virtualCount === 0 && candidate.waitingHumanCount === 0 && candidate.availableSeats > 0)
      .sort((left, right) => {
        const waitingOrder = left.effectiveWaitingSinceAt.localeCompare(right.effectiveWaitingSinceAt);
        if (waitingOrder !== 0) return waitingOrder;
        const roomAgeOrder = left.roomCreatedAt.localeCompare(right.roomCreatedAt);
        if (roomAgeOrder !== 0) return roomAgeOrder;
        return left.roomId.localeCompare(right.roomId);
      })[0];
  }

  recordSchedulerError(error: string): void {
    this.lastSchedulerError = error.slice(0, 500);
    this.log("scheduler_error", "", "", this.lastSchedulerError);
  }

  recordSchedulerIdle(reason: string): void {
    this.lastSchedulerDecision = reason;
    for (const agent of this.agents.values()) {
      if (agent.enabled && agent.state === "offline") agent.joinBlockReason = reason;
    }
  }

  snapshots(): VirtualPlayerAgentSnapshot[] {
    return [...this.agents.values()].map(({ profile: _profile, sessionHandTarget: _target, ...agent }) => ({ ...agent }));
  }

  health(): Record<string, unknown> {
    const errorAgents = [...this.agents.values()].filter((agent) => agent.state === "error").length;
    return {
      status: this.lastSchedulerError || errorAgents > 0 ? "degraded" : "ok",
      enabled: this.configValue.enabled,
      target_online: this.configValue.targetOnline,
      maximum_online: this.configValue.maximumOnline,
      online: this.onlineCount(),
      queued: [...this.agents.values()].filter((agent) => agent.state === "queued" || agent.state === "joining").length,
      pending_leave: [...this.agents.values()].filter((agent) => agent.state === "pending_leave").length,
      errors: errorAgents,
      recovered_after_restart: this.recoveredAgents,
      last_scheduler_run_at: this.lastSchedulerRunAt,
      last_scheduler_error: this.lastSchedulerError,
      last_scheduler_decision: this.lastSchedulerDecision,
    };
  }

  logs(limit = 100): Array<Record<string, unknown>> {
    const persisted = this.repository.recentEvents(limit);
    return persisted.length > 0 ? persisted : this.recentBehaviorLogs.slice(-limit).reverse();
  }

  shutdown(): void {
    for (const agent of this.agents.values()) {
      if (agent.state !== "offline") this.markOffline(agent.playerId, "server_shutdown");
    }
  }

  private mustAgent(playerId: string): MutableAgent {
    const agent = this.agents.get(playerId);
    if (!agent) throw new Error("virtual_profile_not_found");
    return agent;
  }

  private resetOffline(agent: MutableAgent): void {
    Object.assign(agent, {
      state: "offline" satisfies VirtualPlayerState,
      roomId: "",
      seatIndex: -1,
      chips: 0,
      handId: 0,
      sessionHandsPlayed: 0,
      sessionHandTarget: 0,
      onlineSince: undefined,
      lastActionAt: undefined,
      recentError: "",
      joinBlockReason: "",
      pendingLeaveReason: "",
    });
  }

  private persist(agent: MutableAgent): void {
    this.repository.saveState({
      virtual_player_id: agent.playerId,
      state: agent.state,
      room_id: agent.roomId,
      seat_index: agent.seatIndex,
      chips: agent.chips,
      hand_id: agent.handId,
      session_hands_played: agent.sessionHandsPlayed,
      online_since: agent.onlineSince ?? null,
      last_action_at: agent.lastActionAt ?? null,
      recent_error: agent.recentError,
    }, this.isoNow());
  }

  private log(eventType: string, playerId = "", roomId = "", detail = ""): void {
    const item = { event_type: eventType, virtual_player_id: playerId, room_id: roomId, detail, created_at: this.isoNow() };
    this.recentBehaviorLogs.push(item);
    if (this.recentBehaviorLogs.length > 200) this.recentBehaviorLogs.splice(0, this.recentBehaviorLogs.length - 200);
    this.repository.appendEvent(eventType, playerId, roomId, detail, String(item.created_at));
  }

  private isoNow(): string {
    return this.now().toISOString();
  }
}

function normalizeConfig(config: PublicVirtualPlayerConfig): PublicVirtualPlayerConfig {
  const normalized = { ...config };
  normalized.targetOnline = clampInteger(normalized.targetOnline, 0, 32);
  normalized.maximumOnline = clampInteger(normalized.maximumOnline, 0, 32);
  normalized.targetOnline = Math.min(normalized.targetOnline, normalized.maximumOnline);
  normalized.maximumPerRoom = clampInteger(normalized.maximumPerRoom, 0, 8);
  normalized.joinDelayMinMs = clampInteger(normalized.joinDelayMinMs, 0, 300_000);
  normalized.joinDelayMaxMs = Math.max(normalized.joinDelayMinMs, clampInteger(normalized.joinDelayMaxMs, 0, 300_000));
  normalized.actionDelayMinMs = clampInteger(normalized.actionDelayMinMs, 100, 30_000);
  normalized.actionDelayMaxMs = Math.max(normalized.actionDelayMinMs, clampInteger(normalized.actionDelayMaxMs, 100, 30_000));
  normalized.sessionHandMin = clampInteger(normalized.sessionHandMin, 1, 100);
  normalized.sessionHandMax = Math.max(normalized.sessionHandMin, clampInteger(normalized.sessionHandMax, 1, 100));
  return normalized;
}

function clampInteger(value: number, minimum: number, maximum: number): number {
  const parsed = Number.isFinite(value) ? Math.floor(value) : minimum;
  return Math.min(maximum, Math.max(minimum, parsed));
}
