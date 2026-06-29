import type { ActionLogEntry, Card, Phase, PlayerActionType, PrivateSnapshot, PublicSeatSnapshot, SeatStatus, TableSnapshot } from "./protocol.js";
import { createDeck, shuffleDeck } from "./deck.js";
import { buildSidePots, type SidePot } from "./pot_manager.js";

export interface Player {
  id: string;
  name: string;
  connected: boolean;
}

export interface Seat {
  seatIndex: number;
  playerId: string;
  name: string;
  chips: number;
  status: SeatStatus;
  disconnected: boolean;
  holeCards: Card[];
  currentBet: number;
  contribution: number;
  acted: boolean;
  lastAction: string;
  lastActionAmount: number;
  isDealer: boolean;
  isSmallBlind: boolean;
  isBigBlind: boolean;
}

export interface WinnerRecord {
  seat_index: number;
  amount: number;
  hand_rank?: string;
  cards?: string[];
}

export class TableState {
  readonly roomId: string;
  readonly maxSeats = 6;
  smallBlind = 25;
  bigBlind = 50;
  phase: Phase = "waiting";
  handId = 0;
  seats: Seat[] = [];
  communityCards: Card[] = [];
  deck: Card[] = [];
  currentBet = 0;
  minRaiseTo = 50;
  currentTurnSeat = -1;
  dealerSeat = -1;
  smallBlindSeat = -1;
  bigBlindSeat = -1;
  winners: WinnerRecord[] = [];
  log: string[] = [];
  recentActions: ActionLogEntry[] = [];
  private nextActionLogId = 1;

  constructor(roomId: string) {
    this.roomId = roomId;
    for (let i = 0; i < this.maxSeats; i += 1) this.seats.push(this.emptySeat(i));
  }

  sidePots(): SidePot[] {
    return buildSidePots(this.seats);
  }

  totalPot(): number {
    return this.seats.reduce((sum, seat) => sum + seat.contribution, 0);
  }

  addLog(message: string): void {
    this.log.push(message);
    if (this.log.length > 80) this.log = this.log.slice(-80);
  }

  addAction(entry: Omit<ActionLogEntry, "id" | "event_id" | "sequence" | "hand_id" | "phase" | "betting_round" | "created_at">): void {
    const sequence = this.nextActionLogId++;
    const actionEntry: ActionLogEntry = {
      id: sequence,
      event_id: sequence,
      sequence,
      hand_id: this.handId,
      phase: this.phase,
      betting_round: this.phase,
      created_at: new Date().toISOString(),
      ...entry,
    };
    this.recentActions.push(actionEntry);
    if (this.recentActions.length > 30) this.recentActions = this.recentActions.slice(-30);
    this.addLog(actionEntry.message);
  }

  sitDown(player: Player, seatIndex: number, buyIn = 5000): void {
    const seat = this.getSeat(seatIndex);
    if (!seat || seat.playerId) throw new Error("seat is not available");
    Object.assign(seat, {
      playerId: player.id,
      name: player.name,
      chips: Math.max(1, Math.floor(buyIn)),
      status: "sitting" satisfies SeatStatus,
      disconnected: false,
    });
    this.addLog(`${player.name} sits at seat ${seatIndex}.`);
  }

  leaveSeat(playerId: string): void {
    const seat = this.getSeatByPlayer(playerId);
    if (!seat) return;
    Object.assign(seat, this.emptySeat(seat.seatIndex));
  }

  setReady(playerId: string, ready: boolean): void {
    const seat = this.getSeatByPlayer(playerId);
    if (!seat) throw new Error("player is not seated");
    if (seat.status === "sitting" || seat.status === "ready") seat.status = ready ? "ready" : "sitting";
  }

  markDisconnected(playerId: string): void {
    const seat = this.getSeatByPlayer(playerId);
    if (!seat) return;
    seat.disconnected = true;
    if (["sitting", "ready"].includes(seat.status)) seat.status = "disconnected";
  }

  startHand(seed = Date.now()): void {
    const eligible = this.seats.filter((seat) => ["ready", "sitting"].includes(seat.status) && seat.chips > 0 && !seat.disconnected);
    if (eligible.length < 2) throw new Error("at least two connected seated players are required");
    this.handId += 1;
    this.phase = "preflop";
    this.communityCards = [];
    this.deck = shuffleDeck(createDeck(), seed);
    this.currentBet = 0;
    this.minRaiseTo = this.bigBlind;
    this.currentTurnSeat = -1;
    this.winners = [];
    for (const seat of this.seats) {
      seat.holeCards = [];
      seat.currentBet = 0;
      seat.contribution = 0;
      seat.acted = false;
      seat.lastAction = "";
      seat.lastActionAmount = 0;
      seat.isDealer = false;
      seat.isSmallBlind = false;
      seat.isBigBlind = false;
      if (eligible.includes(seat)) seat.status = "playing";
      else if (seat.playerId && seat.chips > 0) seat.status = seat.disconnected ? "disconnected" : "sit_out";
    }
    this.assignButtonAndBlinds();
    this.postBlind(this.smallBlindSeat, this.smallBlind, "small_blind");
    this.postBlind(this.bigBlindSeat, this.bigBlind, "big_blind");
    for (let round = 0; round < 2; round += 1) {
      for (const seat of this.activeSeats()) seat.holeCards.push(this.draw());
    }
    this.currentBet = Math.max(...this.seats.map((seat) => seat.currentBet));
    this.minRaiseTo = this.currentBet + this.bigBlind;
    this.currentTurnSeat = this.nextActionableSeat(this.bigBlindSeat);
    this.addAction({ type: "system", message: `Hand ${this.handId} started.` });
  }

  publicSnapshot(): TableSnapshot {
    return {
      room_id: this.roomId,
      hand_state: this.phase,
      betting_round: this.phase,
      phase: this.phase,
      hand_id: this.handId,
      seats: this.seats.map((seat): PublicSeatSnapshot => ({
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_id: seat.playerId,
        player_name: seat.name,
        name: seat.name,
        chips: seat.chips,
        status: seat.status,
        folded: seat.status === "folded",
        all_in: seat.status === "all_in",
        disconnected: seat.disconnected,
        current_bet: seat.currentBet,
        contribution: seat.contribution,
        last_action: seat.lastAction,
        last_action_amount: seat.lastActionAmount,
        is_dealer: seat.isDealer,
        is_small_blind: seat.isSmallBlind,
        is_big_blind: seat.isBigBlind,
        hole_card_count: seat.holeCards.length,
      })),
      community_cards: this.communityCards.slice(),
      pot: this.totalPot(),
      side_pots: this.sidePots().map((pot) => ({ amount: pot.amount, eligible_seats: pot.eligibleSeats })),
      current_bet: this.currentBet,
      min_raise_to: this.minRaiseTo,
      current_turn_seat: this.currentTurnSeat,
      dealer_seat: this.dealerSeat,
      small_blind_seat: this.smallBlindSeat,
      big_blind_seat: this.bigBlindSeat,
      small_blind: this.smallBlind,
      big_blind: this.bigBlind,
      winners: this.winners.slice(),
      log: this.log.slice(),
      recent_actions: this.recentActions.slice(),
      action_log: this.recentActions.slice(),
    };
  }

  privateSnapshot(playerId: string, legalActions: PrivateSnapshot["legal_actions"] = []): PrivateSnapshot | null {
    const seat = this.getSeatByPlayer(playerId);
    if (!seat) return null;
    return {
      room_id: this.roomId,
      player_id: playerId,
      seat_index: seat.seatIndex,
      hole_cards: seat.holeCards.slice(),
      legal_actions: legalActions,
    };
  }

  getSeat(seatIndex: number): Seat | undefined {
    return this.seats.find((seat) => seat.seatIndex === seatIndex);
  }

  getSeatByPlayer(playerId: string): Seat | undefined {
    return this.seats.find((seat) => seat.playerId === playerId);
  }

  activeSeats(): Seat[] {
    return this.seats.filter((seat) => seat.status === "playing" || seat.status === "all_in");
  }

  liveSeats(): Seat[] {
    return this.seats.filter((seat) => seat.status === "playing" || seat.status === "all_in");
  }

  actionableSeats(): Seat[] {
    return this.seats.filter((seat) => seat.status === "playing" && seat.chips > 0);
  }

  nextActionableSeat(fromSeat: number): number {
    const ids = this.actionableSeats().map((seat) => seat.seatIndex).sort((a, b) => a - b);
    if (ids.length === 0) return -1;
    return ids.find((id) => id > fromSeat) ?? ids[0];
  }

  nextLiveSeat(fromSeat: number): number {
    const ids = this.activeSeats().map((seat) => seat.seatIndex).sort((a, b) => a - b);
    if (ids.length === 0) return -1;
    return ids.find((id) => id > fromSeat) ?? ids[0];
  }

  commit(seat: Seat, amount: number): number {
    const paid = Math.min(Math.max(0, Math.floor(amount)), seat.chips);
    seat.chips -= paid;
    seat.currentBet += paid;
    seat.contribution += paid;
    if (seat.chips === 0 && seat.status === "playing") seat.status = "all_in";
    return paid;
  }

  advancePhase(): void {
    for (const seat of this.seats) {
      seat.currentBet = 0;
      seat.acted = false;
    }
    this.currentBet = 0;
    this.minRaiseTo = this.bigBlind;
    if (this.phase === "preflop") {
      this.dealBoard(3);
      this.phase = "flop";
      this.addAction({ type: "phase", action: "flop", message: `Flop: ${this.communityCards.map((card) => card.code).join(" ")}` });
    } else if (this.phase === "flop") {
      this.dealBoard(1);
      this.phase = "turn";
      this.addAction({ type: "phase", action: "turn", message: `Turn: ${this.communityCards[this.communityCards.length - 1]?.code ?? ""}` });
    } else if (this.phase === "turn") {
      this.dealBoard(1);
      this.phase = "river";
      this.addAction({ type: "phase", action: "river", message: `River: ${this.communityCards[this.communityCards.length - 1]?.code ?? ""}` });
    } else if (this.phase === "river") {
      this.phase = "showdown";
      this.currentTurnSeat = -1;
      this.addAction({ type: "phase", action: "showdown", message: "Showdown." });
      return;
    }
    this.currentTurnSeat = this.nextActionableSeat(this.dealerSeat);
  }

  runoutBoard(): void {
    if (this.communityCards.length < 3) this.dealBoard(3 - this.communityCards.length);
    while (this.communityCards.length < 5) this.dealBoard(1);
  }

  finishDisconnectedHand(): void {
    for (const seat of this.seats) {
      if (seat.disconnected && seat.status !== "empty") seat.status = "sit_out";
    }
  }

  private assignButtonAndBlinds(): void {
    const activeIds = this.activeSeats().map((seat) => seat.seatIndex).sort((a, b) => a - b);
    this.dealerSeat = this.dealerSeat === -1 ? activeIds[0] : this.nextActiveId(activeIds, this.dealerSeat);
    if (activeIds.length === 2) {
      this.smallBlindSeat = this.dealerSeat;
      this.bigBlindSeat = this.nextActiveId(activeIds, this.dealerSeat);
    } else {
      this.smallBlindSeat = this.nextActiveId(activeIds, this.dealerSeat);
      this.bigBlindSeat = this.nextActiveId(activeIds, this.smallBlindSeat);
    }
    this.getSeat(this.dealerSeat)!.isDealer = true;
    this.getSeat(this.smallBlindSeat)!.isSmallBlind = true;
    this.getSeat(this.bigBlindSeat)!.isBigBlind = true;
  }

  private postBlind(seatIndex: number, amount: number, label: string): void {
    const seat = this.getSeat(seatIndex);
    if (!seat) return;
    const paid = this.commit(seat, amount);
    seat.lastAction = label;
    seat.lastActionAmount = paid;
    this.addAction({
      type: "player_action",
      seat_id: seat.seatIndex,
      seat_index: seat.seatIndex,
      player_name: seat.name,
      action: label,
      amount: paid,
      message: `${seat.name} posts ${label === "small_blind" ? "small blind" : "big blind"} ${paid}.`,
    });
  }

  private dealBoard(count: number): void {
    for (let i = 0; i < count; i += 1) this.communityCards.push(this.draw());
  }

  private draw(): Card {
    const card = this.deck.shift();
    if (!card) throw new Error("deck is empty");
    return card;
  }

  private nextActiveId(activeIds: number[], fromSeat: number): number {
    return activeIds.find((id) => id > fromSeat) ?? activeIds[0];
  }

  private emptySeat(seatIndex: number): Seat {
    return {
      seatIndex,
      playerId: "",
      name: "",
      chips: 0,
      status: "empty",
      disconnected: false,
      holeCards: [],
      currentBet: 0,
      contribution: 0,
      acted: false,
      lastAction: "",
      lastActionAmount: 0,
      isDealer: false,
      isSmallBlind: false,
      isBigBlind: false,
    };
  }
}
